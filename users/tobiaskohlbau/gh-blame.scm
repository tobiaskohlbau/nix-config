(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require "helix/misc.scm")

;;@doc
; Copy github blame of current file into system clipboard
(define (gh-blame)
  (define (with-stdout-piped command)
    (set-piped-stdout! command)
    command)
  (define remote (trim-end-matches (~> (command "git" '("remote" "get-url" "origin")) (with-stdout-piped) (spawn-process) (Ok->value) (wait->stdout) (Ok->value) (trim)) ".git"))
  (define current-line-number (helix.static.get-current-line-number))
  (set-register! #\+ (list (string-append remote "/blame/main/" (trim-start-matches (current-path) (string-append (find-workspace) "/")) "#L" (int->string (+ 1 current-line-number))))))

(provide gh-blame)
