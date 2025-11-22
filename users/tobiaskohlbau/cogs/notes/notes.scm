(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require "helix/misc.scm")

;;@doc
; Open notes with filename
(define (notes-internal #:note_type file)
  (helix.open (string-append "~/notes/" file ".md")))

;;@doc
; Open notes
(define (notes . args)
  (if (null? args) (notes-internal #:note_type "notes") (notes-internal #:note_type (car args))))

(provide notes)
