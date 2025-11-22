(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require "helix/misc.scm")

;;@doc
; Copy blame url of current line, on upstream forge, into system clipboard.
(define (blame . args)
  (define remote-name (if (null? args) "origin" (car args)))
  (define branch (if (= (length args) 2) (last args) (default-branch remote-name)))
  (define remote (remote-url remote-name))
  (define current-line-number (helix.static.get-current-line-number))
  (define url (cond [(string-contains? remote "github") (string-append remote "/blame/" branch (trim-start-matches (current-path) (find-workspace)) "/#L" (int->string (+ 1 current-line-number)))]
               [(string-contains? remote "gitlab") (string-append remote "/-/blame/" branch (trim-start-matches (current-path) (find-workspace)) "#L" (int->string (+ 1 current-line-number)))]))
  (set-register! #\+ (list url)))

(define (with-stdout-piped command)
  (set-piped-stdout! command)
  command)

(define (remote-url remote-name)
  (define url (~> (command "git"
                   (append (list "remote" "get-url") (list remote-name)))
               (with-stdout-piped)
               (spawn-process)
               (Ok->value)
               (wait->stdout)
               (Ok->value)
               (trim)))
  (trim-end-matches (cond [(string-contains? url "git@") (string-append "https://" (string-replace (trim-start-matches url "git@") ":" "/"))]
                     [(string-contains? url "https://") url])
    ".git"))

(define (default-branch remote-name)
  (trim-start-matches (~> (command "git"
                           (list "symbolic-ref" (string-append "refs/remotes/" remote-name "/HEAD") "--short"))
                       (with-stdout-piped)
                       (spawn-process)
                       (Ok->value)
                       (wait->stdout)
                       (Ok->value)
                       (trim))
    (string-append remote-name "/")))

(define (current-path)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)])
    (editor-document->path focus-doc-id)))

(provide blame)
