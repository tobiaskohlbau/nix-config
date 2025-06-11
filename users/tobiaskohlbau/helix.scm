(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require "helix/misc.scm")

(provide expanded-shell
         buildifier
         open-helix-scm
         open-init-scm
         gh-blame)

;;@doc
;; Open the helix.scm file
(define (open-helix-scm)
  (helix.open (helix.static.get-helix-scm-path)))

;;@doc
;; Opens the init.scm file
(define (open-init-scm)
  (helix.open (helix.static.get-init-scm-path)))

;;@doc
; Copy github blame of current file into system clipboard
(define (gh-blame)
  (define (with-stdout-piped command)
    (set-piped-stdout! command)
    command)
  (define remote (trim-end-matches (~> (command "git" '("remote" "get-url" "origin")) (with-stdout-piped) (spawn-process) (Ok->value) (wait->stdout) (Ok->value) (trim)) ".git"))
  (define current-line-number (helix.static.get-current-line-number))
  (set-register! #\+ (list (string-append remote "/blame/main/" (trim-start-matches (current-path) (string-append (find-workspace) "/")) "#L" (int->string (+ 1 current-line-number))))))

;;@doc
;; Formatting bazel files with buildifier
(define (buildifier)
  (expanded-shell "buildifier" "-mode=fix" "-lint=fix" "%")
  (enqueue-thread-local-callback-with-delay 100 helix.reload))

;;@doc
;; Specialized shell - also be able to override the existing definition, if possible.
(define (expanded-shell . args)
  ;; Replace the % with the current file
  (define expanded
    (map (lambda (x)
           (if (equal? x "%")
               (current-path)
               x))
         args))
  (apply helix.run-shell-command expanded))

(define (current-path)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)])
    (editor-document->path focus-doc-id)))

