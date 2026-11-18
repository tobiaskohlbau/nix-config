(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require "helix/misc.scm")
(require-builtin helix/core/text)

;; Currently displayed annotation: (list line-number first-line last-line), or #f.
(define *annotation* #f)

;; Doc id of a buffer that is being saved before it gets annotated, or #f.
(define *pending-annotate* #f)

;; jj snapshots the working copy into @ before annotating (no --ignore-working-copy),
;; so the just saved file contents are what gets annotated.
(define jj-annotate-script
  "cd \"$(dirname \"$1\")\" && jj file annotate -T \"if(line_number == $2, '  ' ++ commit.change_id().shortest(8) ++ ' ' ++ commit.author().name() ++ ', ' ++ commit.author().timestamp().ago() ++ ' • ' ++ commit.description().first_line())\" \"$1\"")

(define (clear-annotation!)
  (when *annotation*
    (remove-inlay-hint-by-id (cadr *annotation*) (caddr *annotation*))
    (set! *annotation* #f)))

(define (show-annotation! doc-id)
  (let* ([line (helix.static.get-current-line-number)]
         [path (editor-document->path doc-id)]
         [text (editor->text doc-id)]
         [output (~> (command "sh" (list "-c" jj-annotate-script "jj-annotate" path (int->string (+ 1 line))))
                     (with-stdout-piped)
                     (spawn-process)
                     (Ok->value)
                     (wait->stdout)
                     (Ok->value)
                     (trim-end))])
    (if (string=? output "")
        (set-status! "jj annotate: no annotation for this line")
        ;; Place the hint at the end of the line, before its newline.
        (let* ([line-start (rope-line->char text line)]
               [content (trim-end-matches (trim-end-matches (rope->string (rope->line text line)) "\n") "\r")]
               [id (add-inlay-hint (+ line-start (string-length content)) output)])
          (set! *annotation* (list line (car id) (cadr id)))))))

;;@doc
; Toggle the `jj file annotate` information of the current line, rendered
; inline at the end of the line. Unsaved changes are written first, so the
; annotation matches the buffer. Cleared again when the cursor leaves the line.
(define (jj-annotate)
  (define line (helix.static.get-current-line-number))
  (define was-shown (and *annotation* (= (car *annotation*) line)))
  (define doc-id (editor->doc-id (editor-focus)))
  (clear-annotation!)
  (unless was-shown
    (if (editor-document-dirty? doc-id)
        ;; :write is asynchronous; annotate from the document-saved hook once it finished.
        (begin
          (set! *pending-annotate* doc-id)
          (helix.write))
        (show-annotation! doc-id))))

(register-hook 'document-saved
               (lambda (doc-id)
                 (when (and *pending-annotate* (equal? *pending-annotate* doc-id))
                   (set! *pending-annotate* #f)
                   (when (equal? doc-id (editor->doc-id (editor-focus)))
                     (show-annotation! doc-id)))))

(register-hook 'selection-did-change
               (lambda (view-id)
                 (when (and *annotation*
                            (not (= (car *annotation*) (helix.static.get-current-line-number))))
                   (clear-annotation!))))

(provide jj-annotate)
