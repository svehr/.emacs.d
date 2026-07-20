;; less verbose prompts
(defalias 'yes-or-no-p 'y-or-n-p)

(require 'cl-macs)
(cl-defmacro my/modify-sym (let-args &rest forms)
  "`let-args' is a list of (VAR SYMB-TEXT).
This macro binds each VAR to the string value of the corresponding SYMB-TEXT in `forms' (implicit `progn').
The return value of the implicit `progn' will be returned as interned symbol.
Thus the return value of last expression in forms must be a string.

example
(macroexpand-1 '(my/modify-sym ((s1 'abcd)
                                 (s2 'efgh))
                                (concat s1 s2)))
=>
(let
    ((s1
      (symbol-name 'abcd))
     (s2
      (symbol-name 'efgh)))
  (intern
   (concat s1 s2)))
=>
abcdefgh
"
  (cl-flet ((bind-var (lambda (tuple)
                        (let ((var (car tuple))
                              (symb-text (cadr tuple)))
                          `(,var (symbol-name ,symb-text))))))
    `(let ,(mapcar #'bind-var let-args)
       (intern
        ,(if (> (length forms) 1)
             `(progn ,@forms)
           (car forms))))))
(progn
  ;; emacs lisp library / utility; customization
  ;; BUG: when executing multiple changes of single var
  ;;      comment var does not get updated

  (defun my/customize:1 (variable value &optional &key comment)
    "Changes variable `variable' to `value' via `customize-set-variable'
and create a variable with docstring `comment' named `variable':my/comment.
Returns `value'."
    (declare (indent 2))
    (customize-set-variable variable value comment)
    (eval `(defvar ,(my/modify-sym ((s variable))
                                    (format "%s:my/comment" s))
             nil
             ,(format "This docstring is a comment on `%s'.\n[the value of this variable should just be `nil' / has no intended use]:\n\n%s"
                      variable comment)))
    value)

  (defun my/customize:many (&rest my/customize:args)
    "`my/customize:args' is interpreted as a list of (arguments to `my/customize:1' with the exception that instead of VALUE (nth 1) we supply an EXPRESSION; to make it similar to `custom-set-variables')"
    (dolist (args my/customize:args)
      (apply #'my/customize:1
             ;; args -> args (nth 1) is evaled
             (nconc (list (car args)
                          (eval (cadr args)))
                    (nthcdr 2 args)))))

  (defun my/customize (&rest args)
    "IF first argument is [evaluates to] a symbol: `apply' `my/customize:1' to `args'.
ELSE: `apply' `my/customize:many' to `args'."
    (when args
      (apply (if (symbolp (car args))
                 #'my/customize:1
               #'my/customize:many)
             args))))

(progn
  ;; emacs file management

  (defvar user-emacs-directory:cache
    (concat user-emacs-directory ".cache/")
    "directory to put all files created by packages.
   One should create the path with `my/path:cache' instead of using this variable directly ")

  (defun my/path:cache (relative-path)
      "build path from `user-emacs-directory:cache' and relative-path"
      (convert-standard-filename
       (concat user-emacs-directory:cache relative-path))))


(progn
  ;; discoverability

  (defcustom
    my/help/useful-unbound-functions-list nil
    "list of useful functions without a keybinding.")

  (defun my/help/useful-unbound-function:declare:1 (fn)
    (add-to-list 'my/help/useful-unbound-functions-list fn))

  (defun my/help/useful-unbound-function:declare (&rest fn-list)
    (my/customize 'my/help/useful-unbound-functions-list
                  (append fn-list my/help/useful-unbound-functions-list))))



;; --------------------------
;; PACKAGE MANAGEMENT HELPERS
;; --------------------------

;; ##### package.el
(require 'package)
(my/customize 'package-enable-at-startup nil
              :comment "TODO: reason")

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives 
             '("org" . "https://orgmode.org/elpa/") t)


(when (< emacs-major-version 24)
  ;; for important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))

(eval-when-compile (package-initialize))

(defun my/package.el-install (package)
  "Install `package' via `package.el'.
If package cache (`package-archive-contents')is empty it will be refreshed (via `package-refresh-contents'). 
"
  (unless (package-installed-p package)
    (message "need to install package '%s'" package)
    (let ((archives (or package-archive-contents
                        (progn (package-refresh-contents)
                               package-archive-contents))))
      (if (assoc package archives)
          (package-install package)
        (error "package '%s'" package)))))

;; ##### el-get

(add-to-list 'load-path "~/.emacs.d/el-get/el-get")

;; NOTE: without package.el
;; (unless (require 'el-get nil 'noerror)
;;   (with-current-buffer
;;       (url-retrieve-synchronously
;;        "https://raw.githubusercontent.com/dimitri/el-get/master/el-get-install.el")
;;     (goto-char (point-max))
;;     (eval-print-last-sexp)))
;; NOTE: with package.el
;; NOTE: may not be found via `package-installed-p' since el-get
;;       uses package.el download only as bootstrap to install
;;       itself into another directory
;;       and then delete package.el download
(unless (require 'el-get nil 'noerror)
  (my/package.el-install 'el-get)
  (require 'el-get))


(add-to-list 'el-get-recipe-path "~/.emacs.d/init-lisp/el-get--recipes")
(add-to-list 'el-get-recipe-path "~/.emacs.d/el-get/el-get/recipes")
(el-get 'sync)

;; ##### use-package

(unless (package-installed-p 'use-package)
  (my/package.el-install 'use-package))
(eval-when-compile (require 'use-package))
(require 'use-package-ensure)
(my/customize 'use-package-always-ensure t
              :comment ":ensure property of all `use-package' forms is set to `t' (will always be downloaded if not found on disk)")

;; ;; use-package example
;; (use-package PACKAGE ;; use-package is macro: PACKAGE is "text"
;;   :disabled t   ;; OPTIONAL do not load package
;;   :no-require t ;; OPTIONAL: do not load PACKAGE YET
;;   :ensure PACKAGE
;;   ;; or
;;   :ensure t ;; default when `use-package-always-ensure' set to t
;;   :load-path PATH ;; generally not needed
;;   ;; ----- conditional loading and dependencies
;;   :if (EMACS-LISP) ;;
;;   :after (PACKAGE1 PACKAGE2) ;; :all, :any at start of list possible
;;   ;;      PACKAGE is loaded after PACKAGE1 PACKAGE2 are loaded
;;   ;;      (independent of respective positions in source code)
;;   :requires (PACKAGE1 PACKAGE2) ;;
;;   ;;      PACKAGE is loadeded only if PACKAGE1 PACKAGE2 are loaded
;;   ;; ----- configuration
;;   :init
;;   ;; stuff executed before loading PACKAGE
;;   :config
;;   ;; stuff executed before loading PACKAGE
;;   )
;; ;; use-package short example
;; (use-package PACKAGE ;; use-package is macro: PACKAGE is "text"
;;   :after (PACKAGE1 PACKAGE2)
;;   :init
;;   ;; stuff executed before loading PACKAGE
;;   :config
;;   ;; stuff executed before loading PACKAGE
;;   )

;; --------------------
;; EMACS-LISP LIBRARIES
;; --------------------

(use-package diminish
  ;; https://github.com/myrjola/diminish.el
  ;; remove or modifiy minor mode indicators
  :config
  (require 'diminish))

(use-package dash
  ;; https://github.com/magnars/dash.el
  ;; list library
  :config
  (dash-enable-font-lock))

(use-package f
  ;; https://github.com/rejeep/f.el
  ;; filesystem library
  )

(use-package ht
  ;; https://github.com/Wilfred/ht.el
  ;; hash table
  )

(use-package warnings ;; built-in
  )

(use-package transient
  :ensure t
  :init
  (my/customize 'transient-read-with-initial-input 't))

(defun my/symbol-prefixer (prefix)
  "returns a unary function that prefixes the input symbol 
with the symbol `prefix' [symbol -> `prefix'symbol]"
  (if prefix
      `(lambda (s)
        (my/modify-sym ((pref ',prefix)
                         (s    s))
                        (concat pref s)))
    #'identity))

(defmacro my/defmacro$ (&rest ___args___)
  "note: `___args___' is evaluated during macro-expansion
example:
(let ((name 'test/name))
  (macroexpand-1 '(my/defmacro$ name (___args___)
                    (body1)
                    (body2)))) 
=>
(defmacro test/name (___args___)
  (body1)
  (body2))
"
  `(defmacro ,(eval (car ___args___)) ,@(cdr ___args___)))


;; customize
(defmacro my/defface (face spec doc &rest args)
  ""
  (declare (doc-string 3))
  `(progn
     (defface ,face ,spec ,doc ,@args)
     (face-spec-set ',face (purecopy ,spec) 'face-defface-spec)
     (when ,doc (set-face-documentation ',face (purecopy ,doc)))
     ',face))

(defmacro my/defcustom (symbol standard &rest args)
  "= (`defcustom' `symbol' `standard' ,@args) (`setq' `symbol' `standard')"
  `(progn
     (defcustom ,symbol ,standard ,@args)
     (setq      ,symbol ,standard)))

(defmacro my/defcustom:multi (&rest args)
  "Macro which takes a list of (arguments to `defcustom'),
prefixes the variable name (first arg to `defcustom') with `prefix' (or the empty string if prefix is `nil'; note this means `nil' is a forbidden prefix) and returns a list of `my/defcustom' forms.
`prefix' may be omitted; same as `prefix' = `nil'.
example:

  (macroexpand-1 
   '(my/defcustom prefix/
                 (var \"string-value\" \"docstring\")))
=>
(list
 (defcustom prefix/var \"string-value\" \"docstring\"))

----------

  (macroexpand-1 
   '(my/defcustom
                 (var \"string-value\" \"docstring\")))
=>
(list
 (defcustom var \"string-value\" \"docstring\"))

----------

  (macroexpand-1  nil
   '(my/defcustom
                 (var \"string-value\" \"docstring\")))
=>

(list
 (defcustom var \"string-value\" \"docstring\"))

NOTE: when using a prefix with this macro, the variable renaming canot be achieved via a single string replace.
"
  (let* ((prefix (when (symbolp (car args)) 
                   (car args)))
         (arg-list (if prefix (cdr args) 
                     args)))
    (cl-flet ((arg-fn 
               (lexical-let ((mksym (my/symbol-prefixer prefix)))
                 (lambda (args) 
                   `(my/defcustom ,(funcall mksym (car args)) ,@(cdr args))))))
      (cons 'list (mapcar #'arg-fn arg-list)))))

(defmacro my/defvar (symbol standard &rest args)
  "= (`defvar' `symbol' `standard' ,@args) (`setq' `symbol' `standard')"
  (declare (doc-string 3))
  `(progn
     (defvar ,symbol ,standard ,@args)
     (setq   ,symbol ,standard)))

(defmacro my/defvar:multi (&rest args)
  "Macro like `my/defcustom:multi' but for `defvar' / `my/defvar'. "
  (let* ((prefix (when (symbolp (car args)) 
                   (car args)))
         (arg-list (if prefix (cdr args) 
                     args)))
    (cl-flet ((arg-fn 
               (lexical-let ((mksym (my/symbol-prefixer prefix)))
                 (lambda (args) 
                   `(my/defvar ,(funcall mksym (car args)) ,@(cdr args))))))
      (cons 'list (mapcar #'arg-fn arg-list)))))


(progn
    ;; CORE; library; utililty; functions, function creation, lambda creation, building with functions, lexical scope

    (defmacro my/lex-rebind (sym-list &rest forms)
      "\"Rebind\" syms in SYM-LIST lexical in FORMS
i.e. to make closures with `lambda'
e.g.
`(progn
  (funcall (let ((a 1)) ,(macroexpand-1 '(my/lex-rebind (a) (lambda() a))))))
⇝
(progn
  (funcall
   (let ((a 1))
     (lexical-let
         ((a a))
       (lambda nil a)))))
"
      (declare (indent 1))
      `(lexical-let ,(mapcar (lambda (x) (list x x))
                             (remove-duplicates sym-list))
         ,@forms))

    (defun my/forms-split (&rest forms)
      (let* ((docstring (and (stringp (car-safe forms))
                             (cdr-safe forms)
                             (car forms)))
             (forms (if docstring (cdr forms) forms))
             (iactive-p (lambda (x) (eq 'interactive (car-safe x))))
             (iactive (-first iactive-p forms))
             (declaration-p (lambda (x) (eq 'declare (car-safe x))))
             (declaration (-first declaration-p forms))
             (body (-remove-first iactive-p (-remove-first declaration-p forms)))
             (front (-remove-item nil (list docstring declaration iactive))))
        (list front body)))

    (defun my/lex-rebind-expression (arglist body-list)
"e.g.
(my/lex-rebind-form-expression '(arg1 arg2) '(arg1))
⇝
(lexical-let
    ((arg1 arg1)
     (arg2 arg2))
  arg1)
"
      (let ((lexlet-args
             (append
              (list
               (mapcar (lambda (x) (list x x))
                       (-remove (lambda (sym) (member sym '(&optional &key &rest &key &aux &environment)))
                                arglist)))
              body-list)))
        (cons 'lexical-let lexlet-args)))

    (defun my/forms-insert-lexical-let-into-forms (arglist &rest forms)
      (cl-destructuring-bind (front body) (apply #'my/forms-split forms)
        (append front (list (my/lex-rebind-expression arglist body)))))


    (defmacro my/defun (name arglist &rest forms)
      "Version of `defun' macro where all parameters have lexical scopes.
NOTE: / TODO: might not work correctly in all cases

e.g.:
(macroexpand-1 '(my/defun lexical (arg1 arg2) \"DOC\" (lambda () arg1)))
(defun lexical
    (arg1 arg2)
  \"DOC\"
  (lexical-let
      ((arg1 arg1)
       (arg2 arg2))
    (lambda nil arg1)))"
      (declare (doc-string 3) (indent 2))
      `(defun ,name ,arglist ,@(apply #'my/forms-insert-lexical-let-into-forms arglist forms)))

    (defun my/test/defun ()
                   (list
                    (macroexpand-1 '(my/defun test (arg1 arg2) arg1)) 
                    (macroexpand-1 '(my/defun test (arg1 arg2) (interactive) arg1)) 
                    (macroexpand-1 '(my/defun test (arg1 arg2) "DOC" arg1)) 
                    (macroexpand-1 '(my/defun test (&optional arg1 &rest args) "DOC" arg1)) 
                    (macroexpand-1 '(my/defun test (arg1 arg2) "DOC" (interactive) arg1))
                    (macroexpand-1 '(my/defun test (arg1 arg2) "RETURN"))
                    (macroexpand-1 '(my/defun test (arg1 arg2) (interactive) "RETURN"))))


    ;; font-lock; emacs-lisp-mode
    (font-lock-add-keywords 'emacs-lisp-mode
                            '(("(\\(?:my/defun\\)\\(?:\\s-\\|\n\\)*\\(\\(?:\\s_\\|\\sw\\)+\\)\\(?:.*\\))?"
                               (1 font-lock-function-name-face t))))

    (defmacro my/lambda (arglist &rest forms)
      "Version of `lambda' macro where all parameters have lexical scopes.
NOTE: / TODO: might not work correctly in all cases
"
      (declare (doc-string 2) (indent 1))
      `(lambda ,arglist ,@(apply #'my/forms-insert-lexical-let-into-forms arglist forms)))


    (defmacro my/lambda1l (arglist &rest forms)
      "creates a wrapper `lambda' which a single argument which applies 
the actual (`my/lambda' ARGLIST FORMS) to its sole arg."
      (declare (doc-string 2) (indent 1))
      (let ((arg-sym (gensym)))
        `(lambda (,arg-sym)
           (apply ,(macroexpand-1 `(my/lambda ,arglist ,@forms)) ,arg-sym))))

    (defmacro my/lambda1 (arglist &rest forms)
      "creates a wrapper `lambda' which a single argument which applies 
the actual (`lambda' ARGLIST FORMS) to its sole arg."
      (declare (doc-string 2) (indent 1))
      (let ((arg-sym (gensym)))
        `(lambda (,arg-sym)
           (apply (lambda ,arglist ,@forms) ,arg-sym)))))

(progn
  ;; CORE; test; library; utility
  (my/defun my/test (setup)
"SETUP is an alist of (0-ARY-FUNCTION . EXPECTED-RESULT)"
    (let* ((process (car setup))
           (expected (cdr setup))
           (result (funcall process)))
      (list (equal result expected)
            :process process :result result :expected expected)))

  (my/defun my/test-fn/via-apply (fn)
    "Returns: lambda
(args) ↦ my/test-fn with input (ARGS-TO-FN . EXPECTED-RESULTS)"
    (my/test-fn:process (my/test-fn) (∘ #'my/const (my/apply-fn fn))))

  (my/defun my/test-fn ()
    "Returns:
(lambda (setup) (`my/test' setup))"
    (lambda (setup) (my/test setup)))

  (my/defun my/test-fn:setup (test-fn setup->setup-fn)
    "Modifies setup of a `my/test-fn'"
    (lambda (setup)
        (funcall test-fn (funcall setup->setup-fn setup)))) 

  (my/defun my/test/test-fn:setup ()
    (mapcar (my/test-fn:setup (my/test-fn) 'funcall) 
            ;; TODO: rethink this test
            (list ;; list of: setup creating function
             (my/const (cons (my/const 1) 1)))))

  (my/defun my/test-fn:process (test-fn process->process-fn)
    "Modifies process part of setup of a `my/test-fn'"
    (my/test-fn:setup test-fn
                      (lambda (setup)
                        (cons (funcall process->process-fn (car setup))
                              (cdr setup)))))

  (my/defun my/test/test-fn:process ()
    (mapcar (lambda (setup)
              (apply (lambda (initial-process process->process-fn expected)
                       (funcall (my/test-fn:process
                                 (my/test-fn)
                                 process->process-fn)
                                (cons initial-process expected)))
                     setup)) 
            (list ;; list of: (INITIAL-PROCESS PROCESS->PROCESS-FN EXPECTED) 
             (list (my/const 1) (my/const (my/const 2)) 2)
             (list (lambda () 'kjasdkfj) (my/const (my/const 2)) 2))))

  (my/defun my/test-fn:expected (test-fn expected->expected-fn)
    "Modifies expected part of setup of a `my/test-fn'"
    (my/test-fn:setup test-fn
                      (lambda (setup)
                        (cons (car setup)
                              (funcall expected->expected-fn setup)))))

  (my/defun my/test/test-fn:expected ()
    (mapcar (lambda (setup)
              (apply (lambda (process initial-expected expected->expected-fn)
                       (funcall (my/test-fn:expected
                                 (my/test-fn)
                                 expected->expected-fn)
                                (cons process initial-expected)))
                     setup)) 
            (list ;; list of: (PROCESS INITIAL-EXPECTED EXPECTED->EXPECTED-FN)
             (list (my/const 1) 2 (my/const 1))
             (list (lambda () 'kjasdkfj) 2 (my/const 'kjasdkfj))))))

(progn
  ;; debugging
  (defun my/trace-fn (fn-symbol)
    (lexical-let ((fmt-string (format "trace: (apply '%S %%S)" fn-symbol)))
      (lambda (&rest args) (message fmt-string args))))

  (defvar my/trace-alist nil)

  (defun my/trace:before (fn-symbol)
    (let ((fn (my/trace-fn fn-symbol)))
      (setq my/trace-alist (cons (cons fn-symbol fn) my/trace-alist))
      (advice-add fn-symbol :before fn)))

  (defun my/trace-cancel (fn-symbol)
    (when-let ((fn (assq fn-symbol my/trace-alist)))
      (setq my/trace-alist (assq-delete-all fn-symbol my/trace-alist))
      (advice-remove fn-symbol fn)))
  ;; TODO: cancel does not work currently
  ;; (advice-mapc (lambda (advice _props) (advice-remove #'my/zk/file-handler advice)) #'my/zk/file-handler)
  )


(progn
  ;; building with function; function creation; function composition
  (defun my/NOP-fn ()
    (lambda (arg) arg))

  (defun my/lambda* (&rest args)
    "\"defun version\" of `lambda' macro."
    (apply #'list (cons 'lambda args)))

  (my/defun my/cmd (fn)
    "returns interactive version of `fn'
∀ functions fn: (commandp (my/cmd fn))"
    (lambda ()
      (interactive)
      (funcall fn)))

  (my/defun my/dup (x)
    (list x x))

  (my/defun my/dup-fn ()
    (lambda (x) (list x x)))

  (my/defun my/call-at (N fn)
    "returns function (x,y ...) ↦ (fn(x), y, ...) "
    (lambda (l) (-replace-at N (funcall fn (nth N l)) l)))

  (my/defun my/fst (fn)
    "returns function (x,y ...) ↦ (fn(x), y, ...) "
    (lambda (l) (-replace-at 0 (funcall fn (nth 0 l)) l)))

  (my/defun my/snd (fn)
    "returns function (x,y, ...) ↦ (x, fn(y), z, ...) "
    (lambda (l) (-replace-at 1 (funcall fn (nth 1 l)) l)))

  (my/defun my/cons-fn (item)
    (my/lambda (&rest args)
        (apply #'cons item args)))

  (my/defun my/push_back-fn (item)
    (my/lambda (list)
        (append list (list item))))

  ;; TODO: my/unless-fn
  (my/defun my/when-fn (pred fn)
    (my/lambda (&rest args)
        (when (apply pred args)
          (apply fn args))))

  (my/defun my/skip-nil (fn)
    (my/lambda (&rest args)
        (when (car args)
          (apply fn args))))

  (my/defun my/if-fn (pred true-fn false-fn)
    (declare (indent 1))
    (my/lambda (&rest args)
      (if (apply pred args)
          (apply true-fn args)
        (apply false-fn args))))

  ;; TODO:
  (my/defun my/when-prompt-fn (prompt-string fn)
    (lambda (&rest args)
      (when (y-or-n-p prompt-string)
        (apply fn args))))

  (progn
    ;; test; utility; function composition
    (my/defun my/compose (&rest fns)
      ;; TODO: ?: return #'identity if no FNS given
      (when fns (apply #'my/compose-1 fns)))

    (defalias '∘ #'my/compose)


    (my/defun my/compose-1 (&rest fns)
      (lambda (&rest args)
          (car (reduce (lambda (f x) (list (apply f x)))
                       fns
                       :from-end t
                       :initial-value args))))

    (my/defun my/test/compose ()
      (mapcar (lambda (setup)
                (apply (lambda (fns-list args-list result)
                         (my/test (cons
                                   (my/lambda:apply-0 (apply #'∘ fns-list) args-list)
                                   result)))
                       setup)) 
              '(((identity identity) (1) 1)
                ((evenp 1+)          (1) t)
                ((oddp  1+)          (1) nil)))))

  (my/defun my/alternatives-left-to-right (&rest fns)
    "tried from left-to-right
E.g. 
(funcall (my/alternatives-left-to-right #'oddp #'evenp) 2)
⇝ t
(funcall (my/alternatives-left-to-right (lambda (num) (when (oddp  num) 'oddp ))
                   (lambda (num) (when (evenp num) 'evenp)))
         2)
⇝ evenp
NOTE: / TODO: (`my/alternatives-left-to-right' fns... args...) 
              ≡ lazy evaluated (or (`my/all-called-on' fns... args...)) 
"
    (unless fns
      (error "no functions supplied to 'my/alternatives-left-to-right'"))
    (lambda (&rest args)
      (cl-do* ((fn      (car fns) (car fn-list))
               (fn-list (cdr fns) (cdr fn-list))
               (result  (apply fn args) (apply fn args)))
          ((or result
               (null fn-list))
           result))))

 (defalias 'my/or-fn #'my/alternatives-left-to-right)

  (my/defun my/alternatives-right-to-left (&rest fns)
    "tried from right-to-left until non-nil return value"
    (unless fns
      (error "no functions supplied to 'my/alternatives-right-to-left'"))
    (my/alternatives-left-to-right (reverse fns)))

  (my/defun my/uncurry-1 (fn)
    "example
               fn: a       → (b,c,d → x)
(my/uncurry-1 fn): a,b,c,d →          x"
    (my/lambda (args-car &rest args-cdr)
        (apply (funcall fn args-car) args-cdr)))

  (my/defun my/test/uncurry-1 ()
    (mapcar (my/lambda1l (fn args expected)
                         (my/test (cons (my/apply-fn (my/uncurry-1 fn) args)
                                        expected))) 
            (list
             (list (my/lambda (a) (my/lambda (b) (+ a b)))
                   '(1 1) 2)
             (list (my/lambda (a) (my/lambda (b c d) (+ a b c d)))
                   '(1 1 1 1) 4))))

  (my/defun my/curry-1 (fn)
    "example
               fn: a,b,c →       x
  (my/curry-1 fn): a     → b,c → x"
    (my/lambda (args-car)
        (apply-partially fn args-car)))

  (my/defun my/test/curry-1 ()
    (mapcar (my/lambda1l (fn args-car args-cdr expected)
                         (my/test (cons (my/apply-fn (funcall (my/curry-1 fn) args-car) args-cdr)
                                        expected))) 
            (list
             (list (my/lambda (a b) (+ a b))
                   1 '(1) 2)
             (list (my/lambda (a b c d) (+ a b c d))
                   1 '(1 1 1) 4))))


  (my/defun my/arg-as-result-fn (fn)
    (lambda (arg)
      (funcall fn arg)
      arg))

  ;; test; utility; function creation
  (my/defun my/const (args)
    "Returns a constant variadic function which ignores it arguments and just returns ARGS"
    (lambda (&rest IGNORED) args))

  ;; test; utility; function creation
  (my/defun my/list-fn (&rest params)
    "Returns a"
    (lambda (&rest args)
      (let ((lp (length params))
            (la (length args)))
        (if (= la lp)
            (apply #'list args)
          (error "wrong number of arguments %s: %S (expected %s: %S)" la args lp params)))))

  (my/defun my/list-id (param-list)
    "Returns a function that checks whether the input list has exactly as much parameters as param-list
(if not it throws an (not pretty) error)."
    (unless (listp param-list)
      (error "(my/list-id %S): argument is not a list" param-list))
    (macroexpand-1
     `(my/lambda1 ,param-list (list ,@param-list))))

  (my/defun my/nth-fn (index)
    (my/lambda (list)
      (nth index list)))

  (my/defun my/take-indices-fn (&rest indices)
    (my/lambda (list)
      (-select-by-indices indices list)))

;; NOTE: the following is correct; but shorter version below
;;   (defun my/lambda:apply-0 (fn &rest args)
;;    "(funcall (my/apply-fn FN) arg1 arg2 ... argN)
;; = (apply FN argN)"
;;     (lexical-let ((fn* fn)
;;                   (args* (if (cdr args)
;;                              (let* ((r (reverse args))
;;                                     (but-last (reverse (cdr r)))
;;                                     (last (car r)))
;;                                (append but-last last))
;;                            (car args))))
;;       (lambda () (apply fn* args*))))

  (my/defun my/lambda:apply-0 (fn &rest args)
    "(funcall (my/apply-fn FN) arg1 arg2 ... argN)
= (apply FN argN)"
    (lambda () (apply #'apply (cons fn args))))

  (defun my/test/lambda:apply-0 ()
    (list
     (my/test (cons
               (lambda () (condition-case err
                              (funcall (my/lambda:apply-0 'identity 1))
                            (error 'error)))
               'error))
     
     (my/test (cons
               (lambda () (funcall (my/lambda:apply-0 '+ 1 1 '(1 1))))
               4))))

  (my/defun my/apply-fn (fn &rest args-prefix)
    "(funcall (my/apply-fn FN) arg1 arg2 ... argN)
= (apply FN arg1 arg2 ... argN)

(funcall (my/apply-fn FN arg1 ... argI) argJ ... argN)
= (apply FN arg1 ... argN)
"
    (lambda (&rest args-rest)
      (funcall (my/lambda:apply-0 #'apply (cons fn (append args-prefix args-rest))))))

  (my/defun my/test/apply-fn ()
    (mapcar #'my/test
            (list
             (cons
              (lambda () (condition-case err
                             (funcall (my/apply-fn 'identity) 1)
                           (error 'error)))
              'error)
             (cons
              (lambda () (funcall (my/apply-fn '+) 1 1 '(1 1)))
              4)
             (cons
              (lambda () (funcall (my/apply-fn '+ 1) 1 '(1 1)))
              4))))


  (defalias 'ap #'apply-partially)

  (my/defun my/all-called-on (fns value)
    "Returns a list where (`nth' i) = (`funcall' (`nth' i) VALUE).
To call all FNS in sequence without input value use (`mapcar' #'`funcall' FNS)
or `my/apply-all-fn'
"
    (mapcar (lambda (fn) (funcall fn value)) fns))

  (my/defun my/all-applied-to (fns args)
    "Returns a list where (`nth' i) = (`apply' (`nth' i) ARGS).
NOTE: advantage over `my/all-called-on' case 0 args possible
"
    (mapcar (lambda (fn) (apply fn args)) fns))

  (my/defun my/apply-all-fn (fns)
    "Returns a list where (`nth' i) = (`apply' (`nth' i) ARGS).
NOTE: advantage over `my/all-called-on' case 0 args possible
"
    (lambda (&optional args)
      (mapcar (lambda (fn) (apply fn args)) fns)))

  (defalias '°a (∘ #'my/apply-all-fn #'list)
    "notation adapted from from bird's 'lectures on constructive functional programming'") 

  (defalias '° (∘ (my/curry-1 #'my/all-called-on) #'list)
    "notation adapted from from bird's 'lectures on constructive functional programming'"))

(progn
  ;; utility; buffers; files

  (my/defun my/insert-file-contents (&rest args)
    (condition-case err
        (apply #'insert-file-contents args)
      (error nil)))

  (my/defun my/replace-file (path fn)
    "FN will be executed in temp-file overwriting PATH.
Let b be a buffer visiting PATH
∃ b and modified ⇒ prompt for continue and revert after overwrite
RETURNS (cons b result-of-fn) [b might be nil]"
    (declare (indent 1))
    (let ((buffer (find-buffer-visiting path)))
      (when (or (null buffer)
                (not (buffer-modified-p buffer))
                (y-or-n-p (format "live buffer (modified) '%s' might be changed and file '%s' will be overwritten. okay?"
                                  buffer path))) 
          (let ((result (with-temp-file path (funcall fn))))
            (cons
             (when buffer
               (with-current-buffer buffer (revert-buffer t t))
               buffer)
             result)))))

  (my/defun my/execute-in-file-buffer:temp-copied (path fn)
    "FN will be executed in temp-buffer which is a copy of 
(or 'a buffer visiting PATH' 'the file at PATH')
RETURNS result of fn"
    (declare (indent 1))
    (if-let ((buffer (find-buffer-visiting path)))
        (when-let ((content (with-current-buffer buffer (buffer-string))))
          (with-temp-buffer
            (insert content)
            (goto-char (point-min))
            (funcall fn)))
      (with-temp-buffer
        ;; ?:TODO: NOTE: `insert-file-contents' does not trigger find file hook
        ;; NOTE: `insert-file-contents' also works with encrypted files
        (my/insert-file-contents path)
        (goto-char (point-min))
        (funcall fn))))

  (my/defun my/execute-in-file-buffer (path fn)
    "Let B be a buffer visiting PATH or create it via `find-file-noselect' (and close in the end)
WHEN ∄ buffer b visiting PATH
THEN b ← buffer visitng PATH
execute FN in b and save the buffer
RETURNS (cons b result-of-fn) [b might be nil] or nil on fail"
    (declare (indent 1))
    (let ((live-buffer (find-buffer-visiting path)))
      (when (or (not live-buffer)
                (or (not (buffer-modified-p live-buffer))
                    (y-or-n-p (format "live live-buffer (modified) '%s' might be changed and file '%s' will be overwritten. okay?"
                                      live-buffer path))))
        (when-let ((buffer (or live-buffer (find-file-noselect path))))
          (cons
           live-buffer
           (progn
             (with-current-buffer buffer
               (funcall fn)
               (save-buffer))
             (unless live-buffer
               (kill-buffer buffer))))))))

  (my/defun my/execute-in-file-buffer:read-only (path fn)
    "Let b be a buffer visiting PATH or create it via `find-file-noselect' (and close in the end)
execute FN in b while `buffer-read-only' is set to t.
RETURNS (cons b result-of-fn) [b might be nil] or nil on fail"
    (declare (indent 1))
    (let ((live-buffer (find-buffer-visiting path)))
      (when-let ((buffer (or live-buffer (find-file-noselect path))))
        (cons
         live-buffer
         (progn
           (with-current-buffer buffer
             (let ((buffer-read-only t))
               (funcall fn)))
           (unless live-buffer
             (kill-buffer buffer)))))))

  (my/defun my/in-file-buffer:ensure+read-only (path fn)
    "Let b be a buffer visiting PATH or create it via `find-file-noselect'
RETURNS result of executing FN in b [`buffer-read-only' is set to t for execution of FN]"
    (declare (indent 1))
    (when-let ((buffer (find-file-noselect path)))
      (with-current-buffer buffer
        (let ((buffer-read-only t))
          (funcall fn)))))

  (my/defun my/in-file-buffer:ensure+save (path fn)
    "Let b be a buffer visiting PATH or create it via `find-file-noselect'
RETURNS result of executing FN in b"
    (declare (indent 1))
    (when-let ((buffer (find-file-noselect path)))
      (with-current-buffer buffer
        (let ((result (funcall fn)))
          (save-buffer)
          result)))))



(progn
  ;; string; library

  (my/defun my/split-string-once (string separator-re)
    "Searches for first occurence of `separator-re' in `string' and returns
(cons STRING-BEFORE-SEPARATOR-RE STRING-AFTER-SEPARATOR-RE)

`separator-re' not found ⇔ (null STRING-AFTER-SEPARATOR-RE)"
    (save-match-data
      (let ((start (string-match separator-re string)))
        (if start
            (cons (substring string 0 start)
                  (substring string (match-end 0)))
          (cons string nil)))))

  (my/defun my/test/split-string-once ()
    (mapcar (my/test-fn/via-apply #'my/split-string-once)
            '((("/home/user" "/")       . ("" . "home/user"))
              (("noslash" "/")          . ("noslash" . nil))
              (("prefix/" "/")          . ("prefix" . ""))
              ((".emacs.d/dir/dir" "/") . (".emacs.d" . "dir/dir"))))))


;; buffer editing / mofification
(defun my/replace-region (start end string)
  "Replaces region START (incl.) to END (excl.) of current buffer with STRING"
  (delete-region start end)
  (goto-char start)
  (insert string))


;; filesystem
(defun my/dir:ensure (path)
"Returns PATH if PATH is a directory after execution of this function.
NOTE: does NOT create parent directories.
"
  (cond
   ((f-directory? path) path)
   ((f-file? path) nil)
   (t (condition-case err
          (progn (mkdir path)
                 path)
        (error nil)))))

(progn
  ;; calendar; interactive date selection
  (defun my/date/MDY-to-YMD (date)
"PRECONDITION: DATE is a list (MONTH DAY YEAR) "
    (list (caddr date) (car date) (cadr date)))

  (defun my/date/YMD-to-MDY (date)
"PRECONDITION: DATE is a list (YEAR MONTH DAY) "
    (list (cadr date) (caddr date) (car date)))

  (defun my/calendar-date:interactive (&optional start-date)
    "Select date via `calendar' and return date in format (month day year) [or nil].
PRECONDITION: START-DATE has form (Y M D) or nil"
    (interactive)
    (lexical-let ((date nil))
      (let ((start-date (my/date/YMD-to-MDY (or start-date (my/date:today))))
            (calendar-mode-map
             (let ((map calendar-mode-map))
               (define-key map [remap evil-ret]
                 ;; TODO: BUG: calendar-mode-map modified forever
                 (lambda ()
                   (interactive)
                   (when (< 0 (recursion-depth))
                     (let ((cdate (calendar-cursor-to-date)))
                       (setq date cdate)
                       (calendar-exit)
                       (exit-recursive-edit)))))
               (define-key map [remap quit-window]
                 (lambda () (interactive) (calendar-exit) (when (< 0 (recursion-depth)) (exit-recursive-edit)) nil))
               (define-key map [remap evil-next-line]      #'calendar-forward-week)
               (define-key map [remap evil-previous-line]  #'calendar-backward-week)
               (define-key map [remap evil-forward-char]   #'calendar-forward-day)
               (define-key map [remap evil-backward-char]  #'calendar-backward-day)
               map)))
        (calendar)
        (with-current-buffer calendar-buffer
          (calendar-goto-date start-date))
        (recursive-edit))
      date))

  (defun my/date:interactive (&optional start-date)
    "Select date via `calendar' and return date in format (year month day) [or nil].
PRECONDITION: START-DATE has form (Y M D) or nil"
    (when-let ((cdate (my/calendar-date:interactive start-date)))
      (my/date/MDY-to-YMD cdate)))

  (defun my/date:today (&optional timezone)
    (my/time-to-date (current-time) timezone))

  (defun my/time-to-date (time-obj &optional timezone)
    "TIME-OBJ as e.g. obtained via `current-time' or `encode-time'"
    (funcall (my/take-indices-fn 5 4 3) (decode-time time-obj timezone)))

  (defun my/date-to-week-date (date)
    "DATE has form (year month day)"
    (when-let ((cdate (my/date/YMD-to-MDY date))
               (date (my/date/MDY-to-YMD (calendar-iso-from-absolute (calendar-absolute-from-gregorian cdate)))))
      (when (= 0 (caddr date))
        (setf (caddr date) 7))
      date))

  (defun my/week-date-to-date (week-date)
    "WEEK-DATE has form (iso-year iso-week iso-weekday)"
    (let ((cwdate (or (when (= 7 (caddr week-date))
                        (list (car week-date) (cadr week-date) 0))
                      week-date)))
      (my/date/MDY-to-YMD (calendar-gregorian-from-absolute (calendar-iso-to-absolute (my/date/YMD-to-MDY cwdate))))))

  (defun my/week-date:interactive (&optional start-date)
    "Select ISO-week-date via `calendar' and return date in format (ISO-year ISO-week ISO-weekday) [or nil].
PRECONDITION: START-DATE has form (Y M D) or nil"
    (interactive)
    (my/date-to-week-date (my/date:interactive start-date)))

  (defun my/week-date-to-week (week-date)
    "WEEK-DATE has form (iso-year iso-week iso-weekday)"
    (-take 2 week-date))

  (defun my/week:interactive (&optional start-date)
    "Select ISO-week via `calendar' and return date in format (ISO-year ISO-week) [or nil].
PRECONDITION: START-DATE has form (Y M D) or nil"
    (interactive)
    (when-let ((wdate (my/week-date:interactive start-date)))
      (my/week-date-to-week wdate)))

  (defun my/week:today ()
    "Select ISO-week via `calendar' and return date in format (ISO-year ISO-week) [or nil]."
    (interactive)
    (when-let ((wdate (my/date-to-week-date (my/date:today))))
      (my/week-date-to-week wdate))))

(provide 'my--base)
