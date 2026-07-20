;; additional emacs-lisp files loaded on intialisatiton
;; should be put in subdirectory ./init-lisp
(add-to-list 'load-path (expand-file-name "init-lisp" user-emacs-directory))

(eval-when-compile (require 'cl))


(require 'init--config)
(require 'init--keys)
