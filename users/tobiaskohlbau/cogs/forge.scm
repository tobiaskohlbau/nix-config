(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require "helix/misc.scm")

;;@doc
; Open blame of current line, on upstream forge.
; Inside a rex terminal copies to the local clipboard of the rex client
; (OSC 52). Otherwise opens it on darwin, or copies to the system clipboard
; on linux (assumed VM).
(define (forge-blame . args)
  (define remote-name (if (null? args) "origin" (car args)))
  (define branch (if (= (length args) 2) (last args) (default-branch remote-name)))
  (define remote (remote-url remote-name))
  (define current-line-number (helix.static.get-current-line-number))
  (define url (cond [(string-contains? remote "github") (string-append remote "/blame/" branch (trim-start-matches (current-path) (find-workspace)) "/#L" (int->string (+ 1 current-line-number)))]
               [(string-contains? remote "gitlab") (string-append remote "/-/blame/" branch (trim-start-matches (current-path) (find-workspace)) "#L" (int->string (+ 1 current-line-number)))]))
  (open-or-copy url))

;;@doc
; Open url of current line, on upstream forge.
; Inside a rex terminal copies to the local clipboard of the rex client
; (OSC 52). Otherwise opens it on darwin, or copies to the system clipboard
; on linux (assumed VM).
(define (forge-open . args)
  (define remote-name (if (null? args) "origin" (car args)))
  (define branch (if (= (length args) 2) (last args) (default-branch remote-name)))
  (define remote (remote-url remote-name))
  (define current-line-number (helix.static.get-current-line-number))
  (define url (cond [(string-contains? remote "github") (string-append remote "/blob/" branch (trim-start-matches (current-path) (find-workspace)) "/#L" (int->string (+ 1 current-line-number)))]
               [(string-contains? remote "gitlab") (string-append remote "/-/blob/" branch (trim-start-matches (current-path) (find-workspace)) "#L" (int->string (+ 1 current-line-number)))]))
  (open-or-copy url))

(define (open-or-copy url)
  (cond [(rex-copy url) (set-status! (string-append "Copied to local clipboard via rex: " url))]
    [(string=? (operating-system) "darwin") (~> (command "open"
                                                 (list url))
                                             (spawn-process)
                                             (Ok->value)
                                             (wait)
                                             (Ok->value))]
    [(string=? (operating-system) "linux") (set-register! #\+ (list url))]))

(define rex-osc52-script
  "[ -n \"$REX_SESSION\" ] || exit 0
printf '\\033]52;c;%s\\a' \"$(printf %s \"$1\" | base64 | tr -d '\\n')\" > /dev/tty && echo rex")

(define (rex-copy url)
  (string=? "rex"
            (~> (command "sh"
                 (list "-c" rex-osc52-script "rex-copy" url))
             (with-stdout-piped)
             (spawn-process)
             (Ok->value)
             (wait->stdout)
             (Ok->value)
             (trim))))

(define (operating-system)
  (define uname (~> (command "uname"
                     '("-a"))
                 (with-stdout-piped)
                 (spawn-process)
                 (Ok->value)
                 (wait->stdout)
                 (Ok->value)
                 (trim)))
  (cond [(string-contains? uname "Darwin") "darwin"] [(string-contains? uname "Linux") "linux"]))

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

(provide forge-blame forge-open)
