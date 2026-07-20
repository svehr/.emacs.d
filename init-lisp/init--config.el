;; UTF-8
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

(require 'my--base)

(my/customize 'ring-bell-function 'ignore
              :comment "stop the beep")

;; customization config
(my/customize 'custom-file (my/path:cache "custom-file.el")
              :comment "i.e. prevents emacs from modifying the init file.")

(my/customize 'load-prefer-newer t :comment "TODO: reason")

(my/help/useful-unbound-function:declare 'save-buffers-kill-emacs)

;; disable startup stuff
(my/customize
 '(initial-scratch-message "")
 '(inhibit-startup-screen t))

;; disable auto save and backups
(my/customize
 '(auto-save-default nil)
 '(auto-save-interval 0)
 '(auto-save-visited-file-name nil)
 '(make-backup-files nil))


(progn
  ;; tags: editing; display
  (my/customize
   '(bidi-paragraph-direction 'left-to-right :comment "disable bidirectional capabilities for faster rendering")
   '(bidi-inhibit-bpa 't :comment "disable bidirectional capabilities for faster rendering"))

  (global-so-long-mode)

  (my/customize
   '(require-final-newline 'nil :comment "i.e. to be able to create files readable with '-0' command-line option of several programs (e.g. rsync)")
   '(mode-require-final-newline 'nil :comment "c.f. `require-final-newline'"))
  ;; TODO: to enable conditionaly (e.g.)
  ;; .dir-locals.el
  ;; ((nil  . ((require-final-newline . t)
  ;;           (mode-require-final-newline . t))))

  (my/customize 'whitespace-style
                '(face tabs spaces trailing space-before-tab newline indentation empty space-after-tab space-mark tab-mark newline-mark)
                :comment "i.e. do not mark overlong lines (no 'lines or 'lines-tail')")
  (custom-set-faces
   '(border ((t (:background "#5485ab" :inherit nil)))))

  ;; (global-whitespace-newline-mode 1)
  (global-whitespace-mode 1))

(my/customize
 '(messages-buffer-max-lines 50000 :comment "500000 very sluggish on desktop2019"))


;; GUI
;; disable GUI elements
(my/customize
 '(use-dialog-box nil))
(when (featurep 'menu-bar) (menu-bar-mode -1))
(when (featurep 'tool-bar) (tool-bar-mode -1))
(when (featurep 'scroll-bar) (scroll-bar-mode -1))

;; MONITOR:
;; see https://github.com/syl20bnr/spacemacs/issues/12535
;; (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")


(require 'server)

;; ----------------
;; KEYBINDING BASE
;; ----------------

;; base:
;;   evil       : vim emulation
;;   general    : macros used to create all custom bindings
;;   which-key  : discoverability of key bindings

;; evil requirement
(use-package undo-tree
  :diminish undo-tree-mode
  :config
  (global-undo-tree-mode 1)
  (my/customize 'undo-tree-auto-save-history nil
                :comment "do not store undo-tree history on disk; else the undo-tree history could i.e. leak secrets from encrypted files")
  (my/help/useful-unbound-function:declare 'undo-tree-visualize))

;; evil requirement
(use-package goto-chg
  :config)

(use-package evil
  :after (undo-tree goto-chg)
  :init
  (setq evil-want-keybinding nil)
  (my/customize
   '(evil-default-cursor        '("yellow" box))
   '(evil-emacs-state-cursor    '("blue"   box))
   '(evil-normal-state-cursor   '("orange" box))
   '(evil-visual-state-cursor   '("gray"   box))
   '(evil-insert-state-cursor   '("green"  bar))
   '(evil-motion-state-cursor   '("pink"   box))
   '(evil-replace-state-cursor  '("red"    bar))
   '(evil-operator-state-cursor '("white"  bar)))

  (my/customize
   '(evil-want-C-i-jump   t :comment "t = like in vim")
   '(evil-want-C-u-scroll t :comment "t = like in vim")
   '(evil-want-C-d-scroll t :comment "t = like in vim")
   '(evil-want-C-w-delete t :comment "t = like in vim")
   '(evil-want-C-w-in-emacs-state nil
     :comment
     "t means C-w is window prefix in emacs state;
set to nil since we want C-w to backwards delete word like readline.")
   '(evil-want-change-word-to-end t
     :comment "t = like in vim; means cw = ce;")
   '(evil-want-Y-yank-to-eol t
     :comment
     "t more consistent with C,D.
NOTE: has some issues; see below")
   '(evil-want-minibuffer t
     :comment "t means enable evil in minibuffer")
   '(evil-move-cursor-back nil
     :comment
     "do not move cursor back when exiting normal state")
   '(evil-move-beyond-eol t)
   '(evil-want-integration nil
     :comment "less implicit config; but more explicit config needed.
i.e. undo-tree setup")
   '(evil-cross-lines t :comment "TEST:")
   '(evil-want-fine-undo t :comment "TEST:")
   '(evil-auto-indent nil :comment "TEST:")) 

   :config
   ;; NOTE: see 'general' :config for keybindings

   (require 'evil)
   (evil-mode 1)

  (defun my/evil-jump--push-location (&rest args)
    "wrapper to `evil--jumps-push' to be used in `advice-add'"
    (evil-set-jump))

  (defun my/evil-jump--push-location:around (orig-fn &rest args)
    "wrapper to `evil--jumps-push' to be used in `advice-add'"
    (evil-set-jump)
    (apply orig-fn args)
    (evil-set-jump))

   ;; TODO: / NOTE: some problem with evil-want-Y-yank-to-eol
   (evil-add-command-properties 'evil-yank-line :motion 'evil-end-of-line) 

  ;; do not move cursor when using 'evil-indent' / '='
  (defun my/advice-around/save-excursion (original-function &rest args)
    "save excursion on call of function"
    (save-excursion (apply original-function args)))
  (advice-add 'evil-indent :around #'my/advice-around/save-excursion)

  (defmacro my/evil/set-initial-state (&rest rest)
    "Macro where rest has form (:STATE MODE-SYM+)+ [regex like description].
For all MODE-SYM immediately after :STATE and until the next keyword 
the initial evil-state will be set to STATE.
This is accomplished by returning a list of suitable `evil-set-initial-state' forms.

The only checks performed by this macro is that `rest' starts with
a keyword; i.e. it will not be checked that STATE in :STATE is a legal state.

example
(macroexpand-1
 '(my/evil/set-initial-state
   :motion 'some-mode
   :normal 'another-mode)) 
=>
(list
 (evil-set-initial-state 'some-mode 'motion)
 (evil-set-initial-state 'another-mode 'normal))
"
    (if (not (keywordp (car rest)))
        (user-error "first argument must be a :state keyword but starts with '%s'" (car rest))
      (let ((l (-partition-before-pred #'keywordp rest)))
        `(list
           ,@(-flatten-n 1 (mapcar
                            (lambda (item)
                              ;; precondition: item is l (:state mode mode mode)
                              (let ((state (my/modify-sym ((s (car item)))
                                                           (substring-no-properties s 1))))
                                (mapcar `(lambda (mode)
                                           `(evil-set-initial-state ,mode ',',state))
                                        (cdr item))))
                            l))))))

  ;; TODO: insert-mode in minibuffer
  (my/evil/set-initial-state
   :normal 'debugger-mode
   :normal 'occur-mode
   :normal 'Custom-mode))


(progn
  ;; after: evil, undo-tree

  ;; evil; undo / redo; undo-tree
  (unless evil-want-integration
    ;; partially adapted from evil/evil-integration.el

   (my/customize '(evil-undo-system 'undo-tree))

    (defadvice undo-tree-visualize (after evil activate)
      "Initialize Evil in the visualization buffer."
      (when evil-local-mode
        (evil-initialize-state)))

    (when (fboundp 'undo-tree-visualize)
      (evil-ex-define-cmd "undol[ist]" 'undo-tree-visualize)
      (evil-ex-define-cmd "ul" 'undo-tree-visualize))

    (when (boundp 'undo-tree-visualizer-mode-map)
      (define-key undo-tree-visualizer-mode-map
        [remap evil-backward-char] 'undo-tree-visualize-switch-branch-left)
      (define-key undo-tree-visualizer-mode-map
        [remap evil-forward-char] 'undo-tree-visualize-switch-branch-right)
      (define-key undo-tree-visualizer-mode-map
        [remap evil-next-line] 'undo-tree-visualize-redo)
      (define-key undo-tree-visualizer-mode-map
        [remap evil-previous-line] 'undo-tree-visualize-undo)
      (define-key undo-tree-visualizer-mode-map
        [remap evil-ret] 'undo-tree-visualizer-set))

    (when (boundp 'undo-tree-visualizer-selection-mode-map)
      (define-key undo-tree-visualizer-selection-mode-map
        [remap evil-backward-char] 'undo-tree-visualizer-select-left)
      (define-key undo-tree-visualizer-selection-mode-map
        [remap evil-forward-char] 'undo-tree-visualizer-select-right)
      (define-key undo-tree-visualizer-selection-mode-map
        [remap evil-next-line] 'undo-tree-visualizer-select-next)
      (define-key undo-tree-visualizer-selection-mode-map
        [remap evil-previous-line] 'undo-tree-visualizer-select-previous)
      (define-key undo-tree-visualizer-selection-mode-map
        [remap evil-ret] 'undo-tree-visualizer-set))))



(use-package which-key
  :diminish which-key-mode
  :config
  (require 'which-key)
  (my/customize
   '(which-key-sort-order 'which-key-key-order-alpha))
  (which-key-mode))

(defvar my/kbd/minibuffer-maps
  '(minibuffer-local-completion-map
   minibuffer-local-must-match-map
   minibuffer-local-filename-completion-map
   minibuffer-local-filename-must-match-map
   minibuffer-local-ns-map
   minibuffer-local-map)
  "list of all minibuffer keymaps")

(use-package general
  :after (evil which-key dash)

  :init

  (my/defvar:multi my/kbd/prefix/

    (list
    '((leader "LEADER" "Used for nothing in particular.")
      (quick  "QUICK"  "Used i.e. for short and quick bindings")
      (major  "MAJOR"  "Used for major mode keybindings"))
"List of all prefixes. Entries have form (SYMBOL SHORT-DESCRIPTION DOC-STRING).
For every entry a custom general definer `my/kbd/prefix/SYMBOL/bind' will be defined that binds keys to the prefix `my/kbd/SYMBOL'")
    (symbols (mapcar #'car my/kbd/prefix/list)
             "list of all prefix symbols (mapcar #'car `my/kbd/prefix/list')") 

    (evil-states '(normal visual motion)
                 "list of all evil-states in which prefix keys are bound"))

  (my/defvar:multi my/kbd/
                (custom-definer-list
                 nil
                 "list of all custom definers created via `my/kbd/custom-definer'")
                (custom-global-definer-keymaps
                 '(global Info-mode-map special-mode-map)
                 "list of keymaps used for all custom global definers")
                (evil-states
                '(normal insert visual replace operator motion emacs)
                 "list of all evil-states"))

  :config

  (require 'general)


  ;; ---------- setup custom definers
  ;; NOTE: use this function every time a custom definer is created
  (defun my/kbd/custom-definer:declare (name)
    (push name my/kbd/custom-definer-list))

  (defmacro my/kbd/custom-definer (name &rest args)
    `(progn
       (my/kbd/custom-definer:declare ',name)
       (general-create-definer ,name ,@args)))

  (my/kbd/custom-definer my/kbd/bind/i
   :keymaps my/kbd/custom-global-definer-keymaps
   :states  '(insert))

  (my/kbd/custom-definer my/kbd/bind/v
   :keymaps my/kbd/custom-global-definer-keymaps
   :states  '(visual))

  (my/kbd/custom-definer my/kbd/bind/m
   :keymaps my/kbd/custom-global-definer-keymaps
   :states  '(motion))

  (my/kbd/custom-definer my/kbd/bind/mv
   :keymaps my/kbd/custom-global-definer-keymaps
   :states  '(motion visual))

  (my/kbd/custom-definer my/kbd/bind/mnv
   :keymaps my/kbd/custom-global-definer-keymaps
   :states  '(motion normal visual))

  (my/kbd/custom-definer my/kbd/bind/all-states
   :states  my/kbd/evil-states)

  (my/kbd/custom-definer my/kbd/bind/to:i
   :keymaps  'evil-inner-text-objects-map)

  (my/kbd/custom-definer my/kbd/bind/to:o
   :keymaps  'evil-outer-text-objects-map)

  (my/kbd/custom-definer my/kbd/bind/global
   :keymaps my/kbd/custom-global-definer-keymaps
   :states  my/kbd/evil-states)

  (my/kbd/custom-definer my/kbd/bind/global+
   :keymaps (append my/kbd/custom-global-definer-keymaps
                    my/kbd/minibuffer-maps)
   :states  my/kbd/evil-states)


  (defmacro my/kbd/prefix/definer (prefix)
    "Macro creating a wrapper-macro (our own \"custom definer\")
around `general-define-key'called `my/kbd/bind/PREFIX'.
It takes the :prefix arg from variable `my/kbd/PREFIX' 
(the prefix value is retrieved when wrapper-macro is expanded).

This way we can set the :prefix after the definition of the
custom definer / wrapper-macro.
NOTE: that the variable must still be set before it is used for the first time
"
    (let ((wrapper-name (intern (format "my/kbd/bind/%s" prefix)))
          (prefix-var   (intern (format "my/kbd/%s" prefix))))
      `(progn
         (my/kbd/custom-definer:declare ',wrapper-name)
         (defvar ,prefix-var nil
           ,(format "determines prefix used for `%s'" wrapper-name))
         (defmacro ,wrapper-name (&rest args)
           ,(format "wrapper for `general-define-key' with :prefix read from var `%s'" prefix-var)
           `(general-define-key
             :states my/kbd/prefix/evil-states
             :prefix ,',prefix-var
             ,@args)))))

  (defmacro my/kbd/prefix/definers (&rest prefixes)
    "Creates a list of calls to (`my/kbd/prefix/definer' PREFIX) for
all PREFIX in `prefixes'."
    `(list ,@(mapcar (lambda (prefix)
                       `(my/kbd/prefix/definer ,prefix))
                     prefixes)))

  ;; create custom definers
  (eval 
   `(my/kbd/prefix/definers ,@my/kbd/prefix/symbols)))

(use-package keyfreq
  :disabled t
  :config
  (require 'keyfreq)
  (my/customize
   '(keyfreq-file (my/path:cache "keyfreq"))
   '(keyfreq-file-lock (concat keyfreq-file ".lock")))
  (keyfreq-mode 1)
  (keyfreq-autosave-mode 1))


;; ---------- helper vars for creating consistent bindings later
;; NOTE: / TODO: currently hardcoded / cannot really be hardcoded later
;;               due to use of my/kbd/prefix-set

(defun my/kbd/prefix-set (&rest args)
  (let* ((prefix (when (symbolp (car args))
                   (car args)))
         (sym-value-alist (if prefix (cadr args)
                            (car args))))
    (cl-flet ((mksym (my/symbol-prefixer prefix)))
      (cl-loop for (sym . value) in sym-value-alist do
         (set (mksym sym) value)))))


(defcustom my/kbd/action-key-alist
  '((back                                  .  "C-h")        ;; for directories?
    (move-down                             .  "<down>")     ;; previously: "C-j"
    (move-up                               .  "<up>")       ;; previously: "C-k"
    (complete-common                       .  "<tab>")      ;; previously: "C-i"
    (choose-current                        .  "<right>")    ;; previously: "C-l"
      ;; ivy-minibuffer-map / swiper-map / counsel-find-file-map
      ;;   ivy-alt-done
      ;; company-active-map
      ;;   company-complete-selection
    (interactively-choose                  .  "<right>")    ;; previously: "M-l"
      ;; global
      ;;   my/counsel-company
      ;; company-active-map
      ;;   nil
    (interactively-choose-special          .  "M-<right>")  ;; previously: "M-;" yas-expand / ivy-avy ... 
      ;; global
      ;;   yas-insert-snippet
      ;; yas-keymap
      ;;   ;; previously yas-expand
      ;; swiper-map
      ;;   swiper-avy
    (choose-current-special                .  "<left>")        ;; previously "C-;" ;; yas-expand / ivy-avy ... 
      ;; global
      ;;   yas-expand
      ;; ivy-minibuffer-map
      ;;   ivy-dispatching-done
    (choose-input                          .  "<ret>")      ;; previously: RET; DO NOT (RE)BIND in insert-state
    (save-current-in-kill-ring             .  "M-y")
    (delete-backward-word                  .  "C-w")
    (delete-backward-word2                 .  "C-<backspace>")
    (paste-current-selection               .  "M-i")
    (paste-word-at-point                   .  "M-y")
    (paste-from-register                   .  "C-r")
    (search                                .  "C-s"))
  "alist of (NAME . KEY-STRING) tuples. 
Goal: consistent bindings for similar actions in different contexts and or packages
The KEY-STRING will later also be bound to the variable my/key/NAME via help of `my/kbd/prefix-set'")

(my/kbd/prefix-set 'my/key/ my/kbd/action-key-alist)


(defvar my/keys/homerow-priority '("j" "f" "k" "d" "l" "s" "h" "g" ";" "a")
  "in which order to choose / use homerow keys to select things")


;; -------------------
;; SELECTION FRAMEWORK
;; -------------------
(use-package avy
  :config
  (require 'avy)
  ;; use homerow keys with my priority + SPACE as avy-keys
  ;; -> space will be modifier when there are more than 10 candidates
  (my/customize
   '(avy-keys
     (mapcar 'string-to-char
             (append my/keys/homerow-priority '(" "))))))

(use-package ace-link
  :after (avy)
  :config
  (require 'ace-link)
  ;; (advice-add 'ace-link :around #'my/advice-around/save-excursion)
  ;; NOTE: not good enough because we want to change point when following links
  ;;        to subtrees

  ;; NOTE: REDEF
  ;; TODO: check def
  (defun ace-link-org ()
    "Open a visible link in an `org-mode' buffer.
     NOTE: REDEF: so that external links get followed without moving the cursor. But internal links (to other subtrees) get follwed intra buffer
     TODO: would be nice to change in `ace-link--org-action' BUT:
           avy--process seems to already move point so that start pt cannot be saved 
           in `ace-link--org-action' alone
     "
    (interactive)
    (require 'org)
    (let ((pt:start (point))
          (pt (avy-with ace-link-org
                (avy--process
                 (mapcar #'cdr (ace-link--org-collect))
                 (avy--style-fn avy-style)))))
      (ace-link--org-action pt)
      (when (equal (point) pt)
        ;; point did not move after opening the
        ;; link so it must have been an external link
        (goto-char pt:start))))

  ;; NOTE: redef
  (defun ace-link--org-action (pt)
"NOTE: REDEF: `org-open-at-point-global' instead of `org-open-at-point' (due to some problems with custom links)"
    (when (numberp pt)
      (goto-char pt)
      (org-open-at-point-global)))

  ;; (when (org-in-regexp org-any-link-re)
  ;;             (setq target-string (match-string-no-properties 0)))
  )


(use-package ivy
  :diminish ivy-mode
  :after (evil avy)
  :init
  (my/customize
   '(ivy-height 15)
   '(ivy-do-completion-in-region nil) ;; TODO: check
   '(ivy-count-format "[%d | %d] "))
  :config
  (require 'ivy)
  (my/customize
   '(magit-completing-read-function 'ivy-completing-read)
   '(projectile-completion-system 'ivy))

  (with-eval-after-load 'evil
    ;; record evil jump on every(TEST:) ivy call
    ;; TEST: may record too much locations (e.g. also on cancel)
    ;;       but is that a problem?
    (advice-add 'ivy-read :before #'my/evil-jump--push-location))

  (ivy-mode 1))


;; ----------------------------
;; VISUALS, FONT-LOCK and THEME
;; ----------------------------

(use-package rainbow-delimiters
  ;; color matching parens
  :config
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package paren
  ;; show matching parens
  :config
  ;; setup:
  ;;   * point 1 after last sexp: highlight it
  ;;   * point at start of sexp: highlight it
  ;;     [other rule has priority on conflict]
  (show-paren-mode 1)
  (my/customize
   '(show-paren-style 'expression)
   ;; do not overshadow region
   '(show-paren-priority 0))
  ;; faces / font-lock
  (custom-set-faces
   '(show-paren-match ((t (:foreground nil :background "#334444" :inverse-video nil))))))

(use-package spaceline
  :config
  (require 'spaceline-config)
  ;; NOTE: spaceline has indicator
  ;; putting it in use-package's :diminish is not good enough
  ;; (probably because purpose-mode is not loaded when spaceline is loaded)
  (with-eval-after-load 'window-purpose
    (diminish 'purpose-mode))
  (spaceline-spacemacs-theme))

(use-package hl-line
    :config
    (set-face-background hl-line-face "#333333")
    (global-hl-line-mode))

;; Make `load-theme' fully unload previous theme before loading a new one.
(defadvice load-theme
    (before theme-dont-propagate activate)
    (mapc #'disable-theme custom-enabled-themes))

(use-package darkokai-theme
  :config
  (my/customize

   '(darkokai-mode-line-padding 1)
   ;; only use fixed-width mono-space fonts
   ;; NOTE: value must be floating point to specify scale
   ;;       w.r.t underlying font [1.0; not 1]
   '(darkokai-use-variable-pitch nil))
  (mapc (lambda (num)
          (set (intern (concat "darkokai-height-plus-"
                               (number-to-string num)))
               1.0))
        '(1 2 3 4))
  (mapc (lambda (num)
          (set (intern (concat "darkokai-height-minus-"
                               (number-to-string num)))
               1.0))
        '(1))
  (load-theme 'darkokai t))

(custom-set-faces
 '(highlight ((t (:background "#5070a0" :foreground nil :inherit nil)))))

;; TODO: why?
(custom-set-faces
 '(region ((t (:background "#406188" :inherit nil)))))
;; (add-to-list 'default-frame-alist '(font . "DejaVu Sans Mono-16"))

;; (defun my/unicode-font-setup (&optional frame)
;;   (lexical-let ((size 20))
;;     (dolist (ft (fontset-list))
;;       (set-fontset-font ft 'unicode (font-spec :name "DejaVu Sans Mono" :size size) frame)
;;       (set-fontset-font ft 'unicode (font-spec :name "Latin Modern Math monospacified for DejaVu Sans Mono" :size size) frame 'append)
;;       (set-fontset-font ft 'unicode (font-spec :name "XITS Math monospacified for DejaVu Sans Mono" :size size) frame 'append))))

(defun my/unicode-font-setup (&optional frame)
  (when (display-graphic-p frame)
    ;; NOTE: size 24 and wide-size 28 makes a single wide characters as long as 2 non-wide characters
    ;;       ⦓with chosen fonts⦔
    (lexical-let ((size 28)
                  (wide-size 32))
    (let ((ft "fontset-default"))
      (set-fontset-font nil 'unicode (font-spec :name "JuliaMono" :size size) frame 'prepend)
      (set-fontset-font nil 'unicode (font-spec :name "DejaVu Sans Mono" :size size) frame 'append)
      (set-fontset-font nil 'unicode (font-spec :name "DejaVu Math TeX Gyre" :size size) frame 'append)
      (set-fontset-font nil 'unicode (font-spec :name "Latin Modern Math monospacified for DejaVu Sans Mono" :size size) frame 'append)
      (set-fontset-font nil 'unicode (font-spec :name "XITS Math monospacified for DejaVu Sans Mono" :size size) frame 'append)
      (set-fontset-font nil 'unicode (font-spec :name "Baekmuk Gulim" :size wide-size) frame 'append)
      (set-fontset-font nil 'unicode (font-spec :name "FreeMono" :size size) frame 'append)
      (set-fontset-font nil 'unicode (font-spec :name "Unifont" :size size) frame 'append)
      ;; (set-fontset-font nil 'unicode (font-spec :name "NanumGothicCoding" :size size) frame 'append)
      ))))

(add-hook 'after-init-hook
          (lambda () (unless (or (daemonp) (not (display-graphic-p))) (my/unicode-font-setup)))
          t)
(add-hook 'after-make-frame-functions #'my/unicode-font-setup t)


;; WORKAROUND: for some reason 'xmonad' does not color the frame
;;             [border face was empty for test;
;;              'emacs -q' did not have this problem]
(custom-set-faces
 '(border ((t (:background "#5485ab" :inherit nil)))))


(my/defface face/DONE
  '((t :foreground "#009700" :weight bold))
  "Face for 'DONE:' keyword.")
(my/defface face/TODO
  '((t :foreground "#ff0066" :weight bold))
  "Face for 'TODO:' keyword.")
(my/defface face/ONGOING
  '((t :inherit face/TODO :underline "#ffffff" :slant italic))
  "Face for 'NEXT:' keyword.")
(my/defface face/NEXT
  '((t :inherit face/TODO :underline t))
  "Face for 'NEXT:' keyword.")
(my/defface face/NOTE
  '((t :foreground "#06d8ff" :weight bold))
  "Face for 'NOTE:' keyword.")
(my/defface face/WARNING
  '((t :inherit font-lock-warning-face))
  "Face for 'WARNING:' keyword.")
(my/defface face/ERROR
  '((t :foreground "#ff2222" :weight bold))
  "Face for 'ERROR:' keyword.")
(my/defface face/ORG
  '((t :foreground "#8f81bc" :weight bold))
  "Face for 'ORG:' keyword.")
(my/defface face/MONITOR
  '((t :foreground "#ffd700" :weight bold))
  "Face for 'MONITOR:' keyword.")
(my/defface face/DEFERRED
  '((t :foreground "#c66272"))
  "Face for 'DEFERRED:' keyword.")
(my/defface face/?
  '((t :foreground "#a01cff" :weight bold :box t))
  "Face for '?:' keyword.")

  (setq my/font-lock-extra-keywords
        '(("\\(DONE\\):"                          1 'face/DONE t)
          ("\\(TODO\\|REFACTOR\\|TEST\\):"        1 'face/TODO t)
          ("\\(NEXT\\):"                          1 'face/NEXT t)
          ("\\(ONGOING\\|WIP\\):"                 1 'face/ONGOING t)
          ("\\(NOTE\\|DEPENDENCY\\):"             1 'face/NOTE t)
          ("\\(FIX\\(ME\\)?\\|BUG\\|ERROR\\):"    1 'face/ERROR t)
          ("\\(WARNING\\|HACK\\|WORKAROUND\\|CANCELLED\\):"   1 'face/WARNING t)
          ("\\(ORG\\):"                           1 'face/ORG t)
          ("\\(MONITOR\\):"                       1 'face/MONITOR t)
          ("\\(DEFERRED\\):"                      1 'face/DEFERRED t)
          ("\\(\\?\\):"                   1 'face/? t)))

(dolist (hook '(prog-mode-hook
                fundamental-mode-hook
                text-mode-hook))
  (add-hook hook
            (lambda ()
              (font-lock-add-keywords
               nil my/font-lock-extra-keywords 'append))))


(my/customize
 '(indicate-buffer-boundaries 'left))


;; ------------------------------
;; SUPRESSING FILE CHANGED DIALOG
;; ------------------------------

;; e.g. can it be used to suppress file changed dialog when
;;      tangling code blocks from org-mode

(load "userlock.el" nil t)

(fset 'ask-user-about-supersession-threat:default
      (symbol-function 'ask-user-about-supersession-threat))
(fset 'ask-user-about-lock:default
      (symbol-function 'ask-user-about-lock))


(defvar my/ask-user-about-supersession-threat:file-alist nil
  "List of (FILE . FUNCTION) associating FUNCTION with FILE for `my/ask-user-about-supersession-threat'")
(defvar my/ask-user-about-lock:file-alist nil
  "List of (FILE . FUNCTION) associating FUNCTION with FILE for `my/ask-user-about-lock'")


(defun my/ask-user-about-supersession-threat (path)
  "If `my/ask-user-about-supersession-threat:file-alist' contains a custom function for the file,
it is executed. Else `ask-user-about-supersession-threat:default' is called.
Should be used as `ask-user-about-supersession-threat' replacement."
  (let* ((item (assoc path my/ask-user-about-supersession-threat:file-alist))
         (fn   (if item
                   (cdr item)
                 #'ask-user-about-supersession-threat:default)))
    (funcall fn path)))

(defun my/ask-user-about-lock (path opponent)
  "If `my/ask-user-about-lock:file-alist' contains a custom function for the file,
it is executed. Else `ask-user-about-lock:default' is called.
Should be used as `ask-user-about-lock' replacement."
  (let* ((item (assoc path my/ask-user-about-lock:file-alist))
         (fn   (if item
                   (cdr item)
                 #'ask-user-about-lock:default)))
    (funcall fn path opponent)))

(fset 'ask-user-about-supersession-threat
          'my/ask-user-about-supersession-threat)
(fset 'ask-user-about-lock
          'my/ask-user-about-lock)

;; define ignoring functions
(defun ask-user-about-supersession-threat:ignore (fn)
  "Just ignore files that have changed on disk."
  )
(defun ask-user-about-lock:grab (file opponent)
  "Always grab lock"
  t)


(defun my/suppress-file-changed-prompt:on (file)
  (interactive "f")
  (push (cons file #'ask-user-about-supersession-threat:ignore)
        my/ask-user-about-supersession-threat:file-alist)
  (push (cons file #'ask-user-about-lock:grab)
        my/ask-user-about-lock:file-alist))

(defun my/suppress-file-changed-prompt:off (file)
  (interactive "f")
  (assoc-delete-all file my/ask-user-about-supersession-threat:file-alist)
  (assoc-delete-all file my/ask-user-about-lock:file-alist))



;; --------
;; EDITING
;; --------

(defmacro my/defun/region-action
    (fn-name find-beg find-end-from-beg act-on doc-string)
  `(defun ,fn-name ()
     ,doc-string
     (interactive)
     (save-excursion
       (,find-beg)
       (let ((wbeg (point)))
         (,find-end-from-beg)
         (,act-on wbeg (point))))))

(defmacro my/defun/last-word/action
    (fn-name act-on doc-string)
  `(my/defun/region-action
    ,fn-name
    evil-backward-word-begin
    (lambda () (progn (evil-forward-word-end)
                      (evil-forward-char)))
    ,act-on
    ,doc-string))

(defmacro my/defun/last-WORD/action
    (fn-name act-on doc-string)
  `(my/defun/region-action
    ,fn-name
    evil-backward-WORD-begin
    (lambda () (progn (evil-forward-WORD-end)
                      (evil-forward-char)))
    ,act-on
    ,doc-string))

(my/defun/last-word/action
 my/last-word/upcase
 upcase-region
 "converts last word to uppercase")

(my/defun/last-word/action
 my/last-word/downcase
 downcase-region
 "converts last word to lowercase")

(my/defun/last-WORD/action
 my/last-WORD/upcase
 upcase-region
 "converts last WORD to uppercase")

(my/defun/last-WORD/action
 my/last-WORD/downcase
 downcase-region
 "converts last WORD to lowercase")


;; scrolling
(my/customize
 '(scroll-margin 4)
 '(scroll-conservatively 101
   :comment "greater than 0 implies never jump")
 '(scroll-step 0
   :comment "does not matter if scroll-conservatively > 100")
 '(scroll-preserve-screen-position t
   :comment "keep position when moving out of current screen"))

;; indentation
(my/customize
 '(indent-tabs-mode nil)
 '(tab-always-indent t)
 '(tab-width 4))


(use-package autorevert
  :diminish auto-revert-mode
  :config
  ;; NOTE: may get activated by magit
  (require 'autorevert))


(use-package evil-quickscope
  :after (evil)
  :config
  (require 'evil-quickscope) 
  (global-evil-quickscope-always-mode 1))

(use-package evil-matchit
  :after (evil)
  :config
  (require 'evil-matchit)
  (global-evil-matchit-mode 1))

(use-package evil-nerd-commenter)


;; word movement
(use-package subword
  ;; built-in [since >= 26.1 at least]
  ;; TODO: custom subword package
  :config
  (global-subword-mode))


(use-package swiper
  :after (ivy)
  :config

  (require 'swiper)

  (general-define-key
   :keymaps 'swiper-map
    my/key/interactively-choose-special  'swiper-avy
    my/key/choose-current                'ivy-done))

(use-package ag
  :if (executable-find "ag")
  :after (counsel))

(use-package counsel
  :diminish counsel-mode
  :after (ivy) 
  :config
  (require 'counsel)
  ;; adapted from https://www.reddit.com/r/emacs/comments/52lnad/from_helm_to_ivy_a_user_perspective/d7pj9mz/
  (defun my/delete-file:confirm-recursion (x)
  "like (`dired-delete-file' X 'top). [asks once whether a directory should be
  deleted recursively]"
    (dired-delete-file x 'top))

  (defmacro my/create-lambda:prompt-for-file-exec-command (command prompt)
  "creates a lambda function that:
  1. prompts for a second file name with text PROMPT
     ('%s' in PROMPT will be replaced by the initial-file-name argument
      supplied to the returned lambda)
  2. executes COMMAND with the file-name obtained in 1."
    `(lambda (initial-file-name)
      (let ((target-file
             (expand-file-name
              (let ((enable-recursive-minibuffers t))
                (read-file-name
                 (format ,prompt initial-file-name)
                 (file-name-directory initial-file-name))))))
        (funcall ,command initial-file-name target-file))))

  (ivy-add-actions
   'counsel-find-file
   `(("c" ,(my/create-lambda:prompt-for-file-exec-command #'copy-file "Copy %s to: ") "copy")
     ("d" my/delete-file:confirm-recursion "delete")
     ("m" ,(my/create-lambda:prompt-for-file-exec-command #'rename-file "Move %s to: ") "move")))

  (defun counsel-make (&optional dir)
    "Parse Makefile from directory DIR with `my/list-make-targets' and execute make"
    (interactive)
    (unless (featurep 'imenu)
      (require 'imenu nil t))
    (let ((makefile (expand-file-name "Makefile" dir)))
      ;; `counsel-make:select-target' is responsible for
      ;; Makefile specific error handling
      (let ((target (counsel-make:select-target dir)))
        ;; just runs 'make' in case target is nil
        (compile (format "make %s %s"
                         (if dir (format "-C %s" dir) "")
                         target)))))

  (defun counsel-make:select-target (&optional dir)
    "Parse Makefile from directory DIR with `my/list-make-targets' and return selected command"
    (interactive)
    (unless (featurep 'imenu)
      (require 'imenu nil t))
    (let ((makefile (expand-file-name "Makefile" dir)))
      (if (file-exists-p makefile)
          (ivy-read "make " (if makefile
                                (my/list-make-targets makefile)
                              nil)
                    :require-match nil
                    :caller 'counsel-make)
        (error "no 'Makefile' found in %s" dir))))

  ;; NOTE: ripped off https://github.com/abo-abo/helm-make
  (defun my/list-make-targets (makefile)
    "Return the target list for MAKEFILE by parsing the output of \"make -nqp\"."
    (let ((default-directory (file-name-directory
                              (expand-file-name makefile)))
          targets target)
      (with-temp-buffer
        (insert
         (shell-command-to-string
          "make -nqp __BASH_MAKE_COMPLETION__=1 .DEFAULT 2>/dev/null"))
        (goto-char (point-min))
        (unless (re-search-forward "^# Files" nil t)
          (error "Unexpected \"make -nqp\" output"))
        (while (re-search-forward "^\\([^%$:#\n\t ]+\\):\\([^=]\\|$\\)" nil t)
          (setq target (match-string 1))
          (unless (or (save-excursion
                        (goto-char (match-beginning 0))
                        (forward-line -1)
                        (looking-at "^# Not a target:"))
                      (string-match "^\\([/a-zA-Z0-9_. -]+/\\)?\\." target))
            (push target targets)))
        (push " " targets)
        targets)))

  (general-define-key
   :keymaps 'counsel-find-file-map
    my/key/choose-current        'ivy-alt-done ;; go into directory or select file
    my/key/delete-backward-word  'counsel-up-directory
    my/key/delete-backward-word2 'counsel-up-directory)
  (evil-make-intercept-map counsel-find-file-map)

  (defun my/counsel:imenu-or-semantic ()
    (interactive)
    (if (semantic-active-p)
        (call-interactively 'counsel-semantic)
      (call-interactively 'counsel-imenu)))

  (progn
    ;; remove default bindings
    ;; ag; silver searcher
    (setq counsel-ag-map (make-keymap))
    ;; git-grep
    (setq counsel-git-grep-map (make-keymap))
    ;; imenu
    (setq counsel-imenu-map (make-keymap)))

  (general-define-key
   :keymaps '(counsel-git-grep-map counsel-ag-map)
   ;; TODO: change?
    "C-z" 'counsel-git-grep-recenter ;; from ~z-z~ vim binding
    "M-%" 'counsel-git-grep-query-replace)

  (counsel-mode 1))


(use-package iedit
  :init
  ;; we choose our own keys
  (my/customize
   '(iedit-toggle-key-default nil))
  (custom-set-faces
   '(iedit-occurence ((t (:inherit highlight)))))
  (my/customize '(iedit-overlay-priority
                  50
                  :comment "else higher than region ⇝ cannot see region in iedit-occurence")))

(use-package evil-iedit-state
  :after (iedit evil)
  :config
  (my/customize
   '(evil-iedit-state-cursor '("red" box))
   '(evil-iedit-insert-state-cursor '("red" bar))))

;; TODO: try switching to `corfu` & `vertico` (for minibuffer completions)?
;;       https://emacs.stackexchange.com/a/84925
(use-package company
  :diminish company-mode abbrev-mode
  :config
  (add-hook 'after-init-hook 'global-company-mode)
  (my/customize
   '(company-idle-delay nil
     :comment "never show company tooltip due to idle")
   '(company-minimum-prefix-length 2
     :comment "default == 3")
   '(company-dabbrev-downcase nil)
   '(company-dabbrev-char-regexp "[a-zA-Z0-9\\./_-]"
     :comment "all characters are considered word-chars by company-dabbrev backend.
;; Punctuation is useful for e.g. lisp and org-mode's noweb references.")
   ;; TODO: look at company-dabbrev-ignore-case
   '(company-tooltip-align-annotations t)
   '(company-show-numbers t)
   '(company-require-match nil
     :comment "else inserting newline / abort (instead of completing) not possible")))






;; -----------------------
;; SNIPPETS AND COMPLETION
;; -----------------------

(use-package yasnippet
  ;; http://joaotavora.github.io/yasnippet/
  :after (warnings f dash evil)
  :diminish yas-minor-mode
  ;; TODO:
  ;; :mode ("emacs.+/private/yasnippets/" . snippet-mode)
  :config
  (require 'yasnippet)
  (my/help/useful-unbound-function:declare 'yas-new-snippet)
  ;; (setq yas/prompt-functions 'TODO) ;; TODO
  (defvar my/yas/skip-file-basename
    ;; gather all directories in default snippet dir
    ".yas-skip"
    "putting a file named like this in a mode's snippet subdirectory tells yasnippet no to load snippets from there (according to http://joaotavora.github.io/yasnippet/snippet-organization.html)")

  (defvar my/yas-snippet-dir
    (concat user-emacs-directory "private/yasnippets")
    "snippet dir containing personal snippets")
  (my/customize 'yas-snippet-dirs (list 'my/yas-snippet-dir))

  (defadvice yas--move-to-field  (after my/yas--move-to-field-after/evil--jumps-push activate)
    (evil--jumps-push))
  (defadvice yas-expand  (before my/yas-expand--before/evil--jumps-push activate)
    (evil--jumps-push))
  (defadvice yas-expand  (after my/yas-expand--after/evil--jumps-push activate)
    (evil--jumps-push))
  (defadvice yas-exit-snippet  (after my/yas-exit-snippet--after/evil--jumps-push activate)
    (evil--jumps-push))

  (push '(yasnippet backquote-change) warning-suppress-types)

  (yas-global-mode 1))







;; -----------
;; DEVELOPMENT
;; -----------

(use-package quickrun
  ;; https://github.com/syohex/emacs-quickrun
  :config
  (require 'quickrun)

  (my/customize
   '(quickrun-focus-p nil
     :comment "do not focus quickrun buffer"))

  (add-hook 'quickrun-after-run-hook #'beginning-of-buffer)

  (defun my/quickrun-shell ()
    (interactive)
    (let ((remap-fn
           #'(lambda ()
               (general-define-key
                :keymaps 'local
                 [remap quit-window] 'delete-window))))
      (add-hook 'eshell-mode-hook remap-fn)
      (quickrun-shell)
      (remove-hook 'eshell-mode-hook remap-fn)))

  (general-define-key
    :keymaps 'quickrun/mode-map
    [remap quit-window] 'delete-window))


;; -----------------------
;; OS / SYSTEM INTERACTION
;; -----------------------

(defun my/terminal:external (&optional dir)
  "Opens terminal in DIR (or `default-directory').
Requires libraries 'f.el' and 'dash'"
  (interactive)
  ;; check executable dependencies (TODO: check at compile-time)
  ;; (let ((terminal "x-terminal-emulator"))
  (let ((needed-executables '("st" "tmux-shell.sh"))
        (terminal "st -e tmux-shell.sh"))
    (let ((missing nil))
      (cl-flet ((check-exe (lambda (bname)
                             (unless (executable-find bname)
                               (push bname missing)))))
        (dolist (bname needed-executables)
          (check-exe bname)))
      (when missing
        (error "missing executables: %S" missing)))
    ;; launch "daemonized" terminal process
    ;; (s.t. it survives emacs being killed)
    (let* ((dir (f-full (or dir default-directory)))
           (proc (start-process terminal nil shell-file-name
                                shell-command-switch
                                (format "sh -c 'cd \"%s\"; %s'" dir terminal))))
      proc)))


(defun sudo-edit (&optional arg)
  "Find a file and open it as root."
  (interactive "p")
  (if arg
      (find-file (concat "/sudo:root@localhost:" (read-file-name "File: ")))
    (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))))

(defun sudo-edit-current-file ()
  "Edit the current file as root."
  (interactive)
  (let ((pos (point)))
    (find-alternate-file (concat "/sudo:root@localhost:" (buffer-file-name (current-buffer))))
    (goto-char pos)))

;; -----
;; TOOLS
;; -----

;; (use-package pdf-tools
;;   ;; https://github.com/politza/pdf-tools
;;   :after (evil)
;;   :config
;;   (pdf-tools-install 'dont-query)
;;   ;; view whole page per default
;;   (add-hook 'pdf-view-mode-hook (lambda () (pdf-view-fit-page-to-window)))

;;   (defun noctuid/pdf-view-goto-page (count)
;;     "Goto page COUNT.
;;   If COUNT is not supplied, go to the last page."
;;     (interactive "P")
;;     (if count
;;         (pdf-view-goto-page count)
;;       (pdf-view-last-page)))

;;   (defun noctuid/pdf-view-page-as-text ()
;;     "Inserts current pdf page into a buffer for keyboard selection."
;;     (interactive)
;;     (pdf-view-mark-whole-page)
;;     (pdf-view-kill-ring-save)
;;     (switch-to-buffer (make-temp-name "pdf-page"))
;;     (save-excursion
;;       (yank)))

;;   (my/evil/set-initial-state
;;    :normal
;;     'pdf-view-mode
;;     'pdf-outline-buffer-mode
;;     'pdf-occur-buffer-mode)

;;   (general-define-key
;;    :states '(normal visual motion)
;;    :keymaps 'pdf-occur-buffer-mode-map
;;    "C-m" 'pdf-occur-goto-occurrence
;;    "C-l" 'pdf-occur-goto-occurrence)

;;   (general-define-key
;;    :states '(normal visual motion)
;;    :keymaps 'pdf-outline-buffer-mode-map
;;    ;; j / for next / previous headline
;;    "C-f" 'pdf-outline-follow-mode
;;    "f"   'pdf-outline-display-link
;;    "gj"  'outline-forward-same-level
;;    "gk"  'outline-backward-same-level
;;    "gh"  'outline-up-heading
;;    "gl"  'pdf-outline-follow-link
;;    "C-m" 'pdf-outline-follow-link-and-quit)

;;   (general-define-key
;;    :states '(normal visual motion)
;;    :keymaps 'pdf-view-mode-map
;;     ;; --- horizontal movement
;;     "h" 'image-backward-hscroll
;;     "l" 'image-forward-hscroll

;;     ;; --- vertical movement
;;     ;;  intra- / inter-page
;;     ; "one page"
;;     "K" 'pdf-view-scroll-down-or-previous-page
;;     "J" 'pdf-view-scroll-up-or-next-page

;;     ; "one screen"
;;     "j" 'pdf-view-next-page
;;     "k" 'pdf-view-previous-page

;;     ; some lines
;;     "M-j" (lambda () (interactive) (pdf-view-next-line-or-next-page 5))
;;     "M-k" (lambda () (interactive) (pdf-view-previous-line-or-previous-page 5))
;;     ;;  jump / links
;;     "gg" 'pdf-view-first-page
;;     "G" 'noctuid/pdf-view-goto-page

;;     "m" 'pdf-view-position-to-register
;;     "'" 'pdf-view-jump-to-register

;;     "f" 'pdf-links-action-perform
;;     "F" 'pdf-links-isearch-link
 
;;     ;; --- history
;;     "i"   'pdf-history-forward
;;     "o"   'pdf-history-backward
;;     "C-i" 'pdf-history-forward
;;     "C-o" 'pdf-history-backward


;;     ;; --- searching
;;     "/"  'isearch-forward
;;     "?"  'isearch-backward
;;     "SPC s"  'pdf-occur


;;     ;; --- fit / zoom / slice
;;     "+"  'pdf-view-enlarge
;;     "-"  'pdf-view-shrink
;;     "0"  'pdf-view-scale-reset

;;     "vh" 'pdf-view-fit-height-to-window
;;     "vw" 'pdf-view-fit-width-to-window
;;     "vp" 'pdf-view-fit-page-to-window

;;     "ss" 'pdf-view-set-slice-from-bounding-box
;;     "sm" 'pdf-view-set-slice-using-mouse
;;     "sr" 'pdf-view-reset-slice


;;     ;; --- annotations
;;     "al" 'pdf-annot-list-annotations
;;     "ad" 'pdf-annot-delete
;;     "aa" 'pdf-annot-attachment-dired
;;     "am" 'pdf-annot-add-markup-annotation
;;     "at" 'pdf-annot-add-text-annotation


;;     ;; --- misc/ special functions
;;     "M-t" 'noctuid/pdf-view-page-as-text
;;     "y"   'pdf-view-kill-ring-save
;;     "O"   'pdf-outline
;;     "I"   'pdf-misc-display-metadate
;;     "p"   'pdf-misc-print-document
;;     "r"   'pdf-view-revert-buffer))


(use-package ledger-mode
  :mode ("\\.\\(ledger\\)\\'" . ledger-mode)
  :after (company)
  :config

  (my/customize
   '(ledger-post-amount-alignment-column 60))

  (ledger-reports-add
   "monthly expenses"
   "print \"TOTAL per month: (positive total -> lost money)\n\" \
      && %(binary) -f %(ledger-file) reg -Mn  '^expenses' \
      && print \"\n\nBREAKDOWN per month:\n\" \
      &&  %(binary) -f %(ledger-file) reg -M --period-sort '(amount)' '^expenses'")

  (ledger-reports-add
   "monthly income"
   "print \"TOTAL per month: (positive total -> lost money)\n\" \
      && %(binary) -f %(ledger-file) reg -Mn  '^income' \
      && print \"\n\nBREAKDOWN per month:\n\" \
      &&  %(binary) -f %(ledger-file) reg -M --period-sort '(amount)' '^income'")

  (ledger-reports-add
   "monthly breakdown"
   "print \"TOTAL per month: (positive total -> lost money)\n\" \
      && %(binary) -f %(ledger-file) reg -Mn  '^expenses|^income' \
      && print \"\n\nBREAKDOWN per month:\n\" \
      &&  %(binary) -f %(ledger-file) reg -M --period-sort '(amount)' '^expenses|^income'"))

(use-package gnuplot
  :mode ("\\.\\(gp\\|gnuplot\\|gpi\\)\\'" . gnuplot-mode)
  :config
  (require 'gnuplot))

(use-package sage-sheLl-mode
  :disabled t
  :init
  (setq sage-shell:use-prompt-toolkit t)
  :config
  ;; turn on eldoc-mode
  (add-hook 'sage-shell-mode-hook #'eldoc-mode)
  (add-hook 'sage-shell:sage-mode-hook #'eldoc-mode))

(use-package ob-sagemath
  :disabled t
  :after sage-shell-mode
  :config
  ;; ob-sagemath supports only evaluating with a session.
  (setq org-babel-default-header-args:sage '((:session . t)
                                             (:results . "output"))))

;; ------------------------
;; VERSION CONTROL and VCS
;; ------------------------
(use-package magit
  :config
  (require 'magit)

  (my/defvar my/git:transient-prefix-function 'magit-status
             "Function called by `my/git:transient-prefix'")

  (defun my/git:transient-prefix ()
    "Call `my/git:transient-prefix-function'"
    (interactive)
    (call-interactively my/git:transient-prefix-function)))

;; evilify keybindings
(use-package evil-collection
  :after (evil magit)
  :config

  (my/evil/set-initial-state
   :insert 'with-editor-mode
   :normal 'magit-status-mode)

  (evil-collection-init '(magit))

  (general-define-key
   :keymaps 'magit-status-mode-map
   :states '(emacs normal motion)
   "<tab>"  #'magit-section-toggle
   "C-i"  #'magit-section-toggle
   "h"    #'magit-dispatch
   "l"    #'magit-log
   "C-h"  #'evil-backward-char
   "C-l"  #'evil-forward-char)

  ;; quitting git commit messages
  (general-define-key
   :keymaps '(global-git-commit-mode-map
              git-commit-mode-map
              git-rebase-mode-map
              with-editor-mode-map)
    [remap save-buffer] 'with-editor-finish
    [remap quit-window] 'with-editor-cancel))

;; (use-package gitconfig-mode
;;   :mode (("/\\.git/config\\'" . gitconfig-mode)
;;          ("/git/config\\'" . gitconfig-mode)
;;          ("/\\.gitconfig\\'" . gitconfig-mode)
;;          ("/etc/gitconfig\\'" . gitconfig-mode)
;;          ("/modules/.*/config\\'" . gitconfig-mode)
;;          ("/\\.gitmodules\\'" . gitconfig-mode))
;;   :config
;;   (require 'gitconfig-mode))
;; 
;; (use-package gitignore-mode
;;   :mode (("/\\.gitignore\\'" . gitignore-mode)
;;          ("/\\.git/info/exclude\\'" . gitignore-mode)
;;          ("/git/ignore\\'" . gitignore-mode))
;;   :config
;;   (require 'gitignore-mode))
;; 
;; (use-package gitattributes-mode
;;   :mode (("/\\.git/info/attributes\\'" . gitconfig-mode)
;;          ("/\\.gitattributes\\'" . gitconfig-mode)
;;          ("/git/attributes\\'" . gitconfig-mode))
;;   :config
;;   (require 'gitattributes-mode))




;; =========================
;; FLAT LIST OF TAGGED FORMS
;; =========================
;; multiple forms can receive the same tag via progn

(progn
  ;; BUFFER & WINDOW MANAGEMENT

  (defun my/quit-some-windows-on:current-frame ()
    "Quits windows that are running the following buffers:
      * \"*Help*\"
      * \"*info*\"
      * TODO: 
  "
    (interactive)
    (dolist (buffer-or-name '("*Help*" "*info*" "*scratch*" "*Messages*"))
      (ignore-errors
        (quit-windows-on buffer-or-name nil t))))

  (my/customize
   ;; window management; window splitting; automatic splits
   ;; configuration for `split-window-sensibly'
   ;; (used as default for `split-window-preferred-function'.)
   '(split-height-threshold nil
                            :comment "do not split vertically")
   '(split-width-threshold 140
                           :comment "need at least 70 columns after split")
   ;; TODO: window splitting
   ;;   * ? look at var `split-window-preferred-function'
   ;;   * ? use split-window property of windows
   ;;     to change split-window function
   ;;   * window--display-buffer
   ;;   * display-buffer
   )
  ;; buffer switching
  ;; TODO?: `switch-to-buffer-preserve-window-point'


  (defun my/display-buffer-custom (buffer __ignored__)
    "Can / Should be used as sole function in `display-buffer-alist' to handle the displaying of all buffers.
Activate e.g. via:
(custom-set-variables
   '(display-buffer-alist
     '((\".*\" (my/display-buffer-custom) nil))))
"
    (let ((bname (buffer-name buffer)))
      ;; (message "bname=%s (buffer-name (current-buffer))=%s" bname (buffer-name (current-buffer)))
      (cond
       (;; c.f. `transient--buffer-name' and `transient-display-buffer-action'
        ;; NOTE: BUG: displaying it as sole buffer of a window leads to "delete sole window" error
        ;;            ⇝ magit commit does not work properly (commits some other repo...)
        (string-match-p "^ \\*transient\\*$" bname)
        (display-buffer-in-side-window buffer '((side . bottom))))
       ((or
         (string-match-p "^magit: .*$" bname)
         (string-match-p "^magit-diff: .*$" bname)
         (string-match-p "^COMMIT_EDITMSG\\(<[[:digit:]]*>\\)?$" bname))
        (display-buffer-pop-up-frame buffer nil))
       ((or
         (string-match-p "*Messages*" bname)
         (string-match-p "*Warnings*" bname))
        (display-buffer-no-window buffer
                                  '((allow-no-window . t))))
       ((string-match-p "^\\*CLIPBOARD-BUFFER\\*\\(<[[:digit:]]*>\\)?$" bname)
        (display-buffer-pop-up-frame buffer nil))
       ((string-match-p "^\\*RECURSIVE-EDIT-BUFFER\\*\\(<[[:digit:]]*>\\)?$" bname)
        (display-buffer-pop-up-frame buffer nil))
       ((string-match-p "^zk: <missing description>\\(<[[:digit:]]*>\\)?$" bname)
        (display-buffer-pop-up-frame buffer nil))
       ((string-match-p "^\\*Help\\*\\(<[[:digit:]]*>\\)?$" bname)
        (display-buffer-pop-up-frame buffer nil))
       ((or (string-match-p "^\\*ielm\\*\\(<[[:digit:]]*>\\)?$" bname)
            (string-match-p "^\\*Occur\\*\\(<[[:digit:]]*>\\)?$" bname))
        (funcall (my/or-fn #'display-buffer-reuse-window
                           #'display-buffer-pop-up-frame)
                 buffer
                 '((reusable-frames . nil))))
       ((string-match-p "^\\*Calendar\\*$" bname)
        (funcall (my/or-fn #'display-buffer-reuse-window
                           #'display-buffer-in-side-window)
                 buffer
                 '((reusable-frames . nil)
                   (side            . bottom)
                   (window-height   . 0.30))))
       ((string-match-p "^\\*Flycheck errors\\*$" bname)
        (funcall (my/or-fn #'display-buffer-reuse-window
                           #'display-buffer-in-side-window)
                 buffer
                 '((reusable-frames . nil)
                   (side            . bottom)
                   (window-height   . 0.30))))
       ((or (string-match-p "^\\*Flycheck error messages\\*$" bname)
            (string-match-p "^\\*Flymake diagnostics for .*\\*$" bname))
        (funcall (my/or-fn #'display-buffer-reuse-window
                           #'display-buffer-below-selected)
                 buffer
                 '((reusable-frames . nil)
                   (window-height   . 0.06))))
       ((string-match-p "^\\*quickrun\\*$" bname)
        (funcall (my/or-fn #'display-buffer-reuse-window
                           #'display-buffer-in-side-window)
                 buffer
                 '((reusable-frames . nil)
                   (side            . right)
                   (window-width    . 0.40))))
       ((string-match-p "^\\*cargo-run-comint\\*$" bname)
        (funcall (my/or-fn #'display-buffer-reuse-window
                           #'display-buffer-below-selected)
                 buffer
                 '((reusable-frames . nil)
                   (window-width    . 0.40))))
       ((string-match-p "^ \\*undo-tree\\*$" bname)
        (funcall (my/or-fn #'display-buffer-reuse-window
                           #'display-buffer-in-side-window)
                 buffer
                 '((reusable-frames . nil)
                   (side            . right)
                   (window-width    . 0.20))))
       ((string-match-p "^\\*Backtrace\\*$" bname)
        ;; BUG:?: (current-buffer), (selected-window) etc seem to be executed on buffer which started backtrace (and not the backtrace buffer itself)
        ;;        * this only seems to be happening here; using `eval-expression' everything was normal
        ;; also see 'debug.el' 'debug' function for original setup [2020-02-25 Tue]
        (let* ((debugger-buffer (get-buffer-create "*Backtrace*"))
               (debugger-window (get-buffer-window debugger-buffer 0))
               (debugger-frame  (window-frame debugger-window)))
          (if (and (window-live-p debugger-window)
                   (frame-visible-p debugger-frame))
              (progn
                ;; TODO:BUG: currently frame is not being raise
                (raise-frame debugger-frame)
                (select-frame debugger-frame)
                (select-window debugger-window)
                (display-buffer-same-window buffer nil))
            (display-buffer-pop-up-frame buffer nil))))
       (t
        ;; base case (would be `display-buffer-base-action' in case no match via `display-buffer-alist')
        ;; reuse window displaying buffer on current frame (if any) or display in selected window
        (funcall (my/or-fn #'display-buffer-reuse-window #'display-buffer-same-window)
                 buffer
                 '((reusable-frames . nil)))))))

  (my/customize
   '(display-buffer-alist
     '((".*" (my/display-buffer-custom) nil))
     :comment "`my/display-buffer-custom' handles everything")))


(progn
  ;; text editing; line actions

  (defun my/line/make-empty ()
    (interactive)
    (delete-region (line-beginning-position) (line-end-position)))

  (defun my/line/insert-empty:above ()
    (interactive)
    (save-excursion
      (end-of-line 0) ;; end of prev. line
      ;; NOTE:
      ;; (beginnig-of-line) does not work since
      ;; BOL = EOL case possible (empty line)
      (open-line 1)))

  (defun my/line/insert-empty:below ()
    (interactive)
    (save-excursion
      (end-of-line)
      (open-line 1))))

(progn
  ;; text editing; indenting w.r.t lines above / below

  (defun my/indent/wrt-line-above:forward ()
    "version of (`indent-relative' nil t) with additional indentation point at (`end-of-line' 0).
Kind of complementary operation to `my/indent/wrt-line-above:backward'."
    (interactive)
    (let ((start-pos (point)))
      (indent-relative nil t)
      (when (and (= start-pos (point))
                 (not (my/point-on-first-line-p)))
        (let ((col (current-column))
              (target-col
               (save-excursion
                 (end-of-line 0) ;; end previous line
                 (current-column))))
          (when (<= col target-col)
            (insert-char #x20 (1+ (- target-col col))))))))

  (defun my/indent/wrt-line-above:backward ()
    "Try to remove as little whitespace in front of cursor s.t. afterwards
the cursor is 1 line below a WORD start (if we are below a WORD start we want to move to a different one (next previous one)).
If it is not possible to reach such a position by removing whitespace,
delete all whitespace between the cursor and the end of the previous
non whitespace char on the same line except 1 (i.e. we keep 1 space after the problem word).
Kind of complementary operation to `my/indent/wrt-line-above:forward'."
    (interactive)
    ;; TODO: ? move to start of current WORD first
    (unless (or (bolp)
                (my/point-on-first-line-p))
      ;;     we can indent backwards
      ;; and we have a previous line to w.r.t which we can indent
      (save-excursion
        (let ((pos-start (point))
              (col-start (current-column))
              (col-end-correct
               (save-excursion
                 (previous-logical-line)
                 ;; cursor is at column <= col-start now
                 ;; NOTE: cursor might be at column < col-start now
                 (skip-syntax-backward " "  (line-beginning-position))
                 (skip-syntax-backward "^ " (line-beginning-position))
                 (current-column)))
              (col-end-possible
               (save-excursion
                 (let ((pos1 (point)))
                   (skip-syntax-backward " " (line-beginning-position))
                   (if (or (= pos1 (point))
                           (bolp))
                       (current-column)
                     (+ 1 (current-column)))))))
          (let ((col-end (max col-end-possible
                              col-end-correct)))
            (delete-region (- pos-start (- col-start col-end))
                           pos-start)))))))

;; emacs lisp library / utility
(progn
  (defun my/point-on-first-line-p ()
    "Returns t iff. point is on first line of the buffer"
    (>= (point-min)
        (line-beginning-position))))

(progn
  ;; emacs-lisp utility / library

  (defun my/newline ()
    "newline char.
emacs buffers always uses ?\n as new line char [?:if possible]
TODO: citation needed."
    "\n")

  (cl-defmacro my/line-string (&optional &key no-properties)
    "Returns current line string  without trailing new line
    * strip text properties if :NO-PROPERTIES is non nil
(with trailing newline if exists).
Also see `my/line-string:no-properties'"
    (cond
     (no-properties
      `(buffer-substring-no-properties (line-beginning-position)
                                       (line-end-position)))
     (t
      `(buffer-substring (line-beginning-position)
                         (line-end-position)))))


  (defun my/point-on-blank-line-p ()
    "Return true if current line contains only whitespace
characters.
Also see `my/point-on-empty-line-p'
Taken from package 'comment-dwim-2'"
    (string-match "^[[:blank:]]*$" (my/line-string)))

  (defun my/point-on-empty-line-p ()
    "Return true if current line contains only trailing newline char.
"
    (string-empty-p (my/line-string)))

  (defun my/contiguous-spaces-at-point/this-line ()
    "NOTE: tabs etc. counted as 1 space"
    (save-match-data
      (if (looking-at "[\t ]*") ;; always matches since empty string allowed
          (- (match-end 0) (match-beginning 0))))))



(progn
  ;; org-mode

  ;; TODO:
  ;;   ? poporg https://github.com/QBobWatson/poporg
  ;;   ? biblio

  (use-package org
    ;; https://orgmode.org/
    ;; :pin org ;; use 'org entry from package-archives
    :pin gnu
    :after (evil)
    :ensure org-contrib
    :diminish org-src-mode
    :config

    (require 'org)

    ;; clear keymaps
    (setq org-mode-map (make-keymap))
    (setq org-src-mode-map (make-keymap))

    (progn
      ;; org mode outline

      (my/customize
       '(org-startup-folded 'showeverything) 
       '(org-insert-heading-respect-content nil
         :comment "insert heading directly after current line") 
       '(org-M-RET-may-split-line '((default . nil))
         :comment "split lines always"))

      (defun my/org-insert-heading ()
        "If we are before the first heading: insert level 1 heading.
Else: insert heading with same level as the heading we currently write under.
The headings are inserted by opening a neww line below the current line.
Special case: we are on an empty line; then the headin is added by replacing the current line.
We end in insert-state.
requires: evil"
        (interactive)
        (let ((level (or (org-current-level) 1)))
          (if (my/point-on-blank-line-p)
              (delete-region
               (line-beginning-position)
               (line-end-position))
            (my/line/insert-empty:below)
            (beginning-of-line 2))
          (insert-char ?* level)
          (insert " ")
          (evil-insert-state)))

      (progn
        ;; my org bullet list stuff

        (lexical-let ((item-start-re           "^[ \t\v]+\\(\\*\\|[0-9][0-9]?)\\)")
                      (num-spaces            2))

          (my/defvar my/org-bullet-list-info "See docstring of this variable."
                     "NOTE: / TODO: lists can only start with * or with [WIP:] a number of max 2 digits followed by ')' (right parenthesis).
Indentation levels are multiples of `num-spaces' [NOTE: / TODO: hardcoded in surrounding lexical-let]:
init = num-spaces; increasing / decreasing means +/- `num-spaces' spaces.
NOTE: start is inclusive and end exclusive for items and lists
TODO: indent multiple items (active region)
TODO: indent without subtree
NOTE: only spaces are really supported for indentation (1 tabs counted as 1 space)")

          (progn
            (my/defvar my/org-item-start-re
                       item-start-re
                       "i.e. used in `my/org-item-start'")

            (defun my/org-item-range ()
"Returns 
     (start-pos bullet-pos end-pos) of current my/org-item where start-pos is inclusive and end-pos is exclusive
  OR nil (ifnot in an org item)"
              (save-excursion
                (save-match-data
                  (let ((point:start (point))
                        ;; NOTE: on `re-search-backward' the complete searched for regexp needs to precede (point)
                        ;;       [and not just the beginning of the match]
                        (found (or (progn
                                     (beginning-of-line)
                                     (looking-at item-start-re))
                                   (re-search-backward item-start-re nil t))))
                    (when found
                      (let ((end (my/org-item-end/point-on-item-start)))
                        ;; TODO:?: rather return (end = (point-max) + 1)
                        (when (or (> end point:start)
                                  (and (= end point:start)
                                       (>= end (point-max))))
                          (list
                           (match-beginning 0)
                           (match-beginning 1)
                           end))))))))
            (defalias #'my/org-item-start      (∘ #'car #'my/org-item-range))
            (defalias #'my/org-item-bullet-pos (∘ #'cadr #'my/org-item-range))
            (defalias #'my/org-item-end        (∘ #'caddr #'my/org-item-range))

            (defun my/org-item-end/point-on-item-start ()
              "PRECONDITION: point is on item start (beginning of line not bullet pos)
Returns end (exlusive).
Everytying that is indented more than the bullet point of the item counts as part of that item
⇒ i.e. subtrees/-lists are included.
NOTE: moves point" 
              (let ((indentation:start (my/contiguous-spaces-at-point/this-line)))
                (beginning-of-line 2) ;; on document end fails quietly and goes to (point-max)
                (while (and (< (point) (point-max))
                            (< indentation:start (my/contiguous-spaces-at-point/this-line)))
                  (beginning-of-line 2))
                (point)))

          (defun my/org-indent-item:inc ()
            "Increase indentation of current bullet list item (with subtree).
C.f. `my/org-bullet-list-info' docstring."
            (interactive)
            (save-excursion
              (if-let ((range-info (my/org-item-range)))
                  (let ((end (caddr range-info)))
                    (goto-char (car range-info))
                    (while (< (point) end)
                      (insert-char ?\s num-spaces)
                      (beginning-of-line 2)))
                (user-error "not in an my/org-item (c.f. `my/org-bullet-list-info' docstring)."))))

          (defun my/org-indent-item:dec ()
            "Decrease indentation of current bullet list item (with subtree).
C.f. `my/org-bullet-list-info' docstring."
            (interactive)
            (save-excursion
              (if-let ((range-info (my/org-item-range)))
                  (let* ((first-line-start      (car  range-info))
                         (first-line-bullet-pos (cadr range-info))
                         (current-indentation (- first-line-bullet-pos first-line-start)))
                    (if (< (current-indentation) (* 2 num-spaces))
                        (user-error "Cannot further decrease indentation")
                       ;; NOTE: / TODO: alternative: adapt num-spaces if ident-delta < (current-indentation) < 2 * num-spaces
                       ;;               to ident to num-spaces
                       ;;               (let ((num-spaces (let ((naive-resulting-indentation (- current-indentation num-spaces)))
                       ;;                                     (if (< naive-resulting-indentation num-spaces)
                       ;;                                                               naive-resulting-indentation
                       ;;                                                                                       num-spaces))))
                       ;;                                                                                        ....)
                      (let* ((end (caddr range-info))
                             (delete-rectangle-end
                              (save-excursion
                                (goto-char end) ;; past-the-end
                                (if (= (point) (line-beginning-position))
                                    (progn
                                      ;; goto-beginning of prev line
                                      (beginning-of-line 0)
                                      (+ num-spaces (point)))
                                  (progn
                                    (+ num-spaces (line-beginning-position)))))))
                        (delete-rectangle first-line-start delete-rectangle-end))))
                (user-error "not in an my/org-item (c.f. `my/org-bullet-list-info' docstring)."))))

        (defun my/org-insert-item ()
            " If we are in an item: Adds a new item below the current item with the same indentation.
Else: Add a new item (C.f. `my/org-bullet-list-info')
Special case: we are on an empty line; then the item is added by replacing the current line.
In all cases we end in insert-state.
requires: evil
  "
            (interactive)
            (let* ((item-range-info (my/org-item-range))
                   (new-item-indent
                    (if item-range-info
                        (save-excursion
                          (goto-char (cadr item-range-info))
                          (current-column))
                      num-spaces)))
              (if (my/point-on-blank-line-p)
                  (delete-region
                   (line-beginning-position)
                   (line-end-position))
                (my/line/insert-empty:below)
                (beginning-of-line 2))
              ;; ?\s = space character
              (insert-char ?\s new-item-indent)
              (insert "* ")
              (evil-insert-state))))))

      (defun my/org-metaright ()
        (interactive)
        (cond
         ((my/org-item-range) (my/org-indent-item:inc))
         ((org-with-limited-levels
           (or (org-at-heading-p)
               (and (org-region-active-p)
                    (save-excursion
                      (goto-char (region-beginning))
                      (org-at-heading-p)))))
          (when (org-check-for-hidden 'headlines) (org-hidden-tree-error))
          (call-interactively 'org-do-demote))
         (t (user-error "my/org-metaright does not know what to do here."))))

      (defun my/org-metaleft ()
        (interactive)
        (cond
         ((my/org-item-range) (my/org-indent-item:dec))
         ((org-with-limited-levels
           (or (org-at-heading-p)
               (and (org-region-active-p)
                    (save-excursion
                      (goto-char (region-beginning))
                      (org-at-heading-p)))))
          (when (org-check-for-hidden 'headlines) (org-hidden-tree-error))
          (call-interactively 'org-do-promote))
         (t (user-error "my/org-metaright does not know what to do here.")))))


    ;; org src mode
    ;; ;; NOTE: / TODO?: not working
    ;;  (general-define-key
    ;;   :keymaps 'org-src-mode-map
    ;;   [remap quit-window]    'org-edit-src-abort
    ;;   [remap save-buffer]    'org-edit-src-exit)
    ;;  (add-hook 'org-src-mode-hook #'evil-normalize-keymaps)
    (defun my/org-src-bind-exit-keys ()
      (interactive)
      (general-define-key
       :keymaps 'local
       [remap quit-window]    'org-edit-src-abort
       [remap save-buffer]    'org-edit-src-exit))
    (add-hook 'org-src-mode-hook #'my/org-src-bind-exit-keys)

    ;; org-mode customizations
    (my/customize
     '(org-cycle-emulate-tab nil
       :comment "emulating tab just leads to conflicts")
     '(org-catch-invisible-edits 'show-and-error
       :comment "no unintended invisible edits"))

    (progn
      ;; org-mode; org-id
      ;; IDs for headlines
      ;; needed to link them

      (require 'org-id)
      (my/customize
       '(org-id-track-globally nil
         :comment "do not track IDs globally; global tracking would need external state")
       '(org-id-locations-file (my/path:cache ".org-id-locations")
         :comment "should be irrelevant if `org-id-track-globally' = nil")
       '(org-id-extra-files nil
         :comment "should be irrelevant if `org-id-track-globally' = nil")
       '(org-id-link-to-org-use-id 'create-if-interactive
         :comment "create an id for the current tree only if `org-store-link' is called interactively -> no \"side effects\"")))

    (progn
      ;; org links

      (my/customize
       '(org-descriptive-links t :comment "t means i.e. display [[link][desc]] as desc")
       '(org-activate-links nil :comment "also see my redef of `org-link-make-regexps'.
NOTE: / TODO: DEPRECATED in favor of zk links and `my/plain-link-re'" )
       '(org-link-file-path-type 'relative :comment "should be irrelevant if `org-id-track-globally' = nil"))

      ;; NOTE: set via `org-link-make-regexps' at org-mode load (adapted f)
      ;; NOTE: / TODO: DEPRECATED in favor of zk links and `my/plain-link-re'
;;       (defun org-link-make-regexps ()
;;         "Update the link regular expressions.
;; This should be called after the variable `org-link-parameters' has changed.
;; NOTE: REDEF to 
;;         * incluse only http{,s} links in plain links
;;         * only use innermost [] pair for org-link-bracket-re"
;;         (let ((types-re (regexp-opt (org-link-types) t)))
;;           (setq org-link-types-re
;;                 (concat "\\`" types-re ":")
;;                 org-link-angle-re
;;                 (format "<%s:\\([^>\n]*\\(?:\n[ \t]*[^> \t\n][^>\n]*\\)*\\)>"
;;                         types-re)
;;                 org-link-plain-re
;;                 (concat
;;                  "\\<"
;;                  ;; NOTE: replaced TYPES-RE here with the following string
;;                  "\\(https?\\)"
;;                  ":"
;;                  "\\([^][ \t\n()<>]+\\(?:([[:word:]0-9_]+)\\|\\([^[:punct:] \t\n]\\|/\\)\\)\\)")
;;                 ;;	 "\\([^]\t\n\r<>() ]+[^]\t\n\r<>,.;() ]\\)")
;;                 org-link-bracket-re
;;                 (rx (seq "[["
;;                          ;; URI part: match group 1.
;;                          (group
;;                           ;; Allow an even number of backslashes right
;;                           ;; before the closing bracket.
;;                           (or (one-or-more "\\\\")
;;                               (and (not (any "[")) ;; NOTE: added this as start of the regexp (⇒ no empty links)
;;                                    (*? anything)
;;                                    (not (any "\\"))
;;                                    (zero-or-more "\\\\"))))
;;                          "]"
;;                          ;; Description (optional): match group 2.
;;                          (opt "[" (group (+? anything)) "]")
;;                          "]"))
;;                 org-link-any-re
;;                 (concat "\\(" org-link-bracket-re "\\)\\|\\("
;;                         org-link-angle-re "\\)\\|\\("
;;                         org-link-plain-re "\\)"))))
      (defun org-link-make-regexps () nil)
      (org-link-make-regexps)

      ;; NOTE: some code taken from `org-id-get-with-outline-path-completion'
      (defun my/org-store-link-with-outline-path-completion (&optional targets)
        "Use `outline-path-completion' to retrieve the link of an entry.
  TARGETS may be a setting for `org-refile-targets' to define
  eligible headlines.  When omitted, all headlines in the current
  file are eligible.  
  This function returns nothing. It just stores the link or inserts it into the buffer
  "
        (interactive)
        (save-excursion
          ;; WORKAROUND: so that we can store links when we are before the first headline
          ;;             there must be a better way: look at / use U-U-{org-refile}
          (when (org-before-first-heading-p) (outline-next-heading))
          (let* ((org-refile-targets (or targets '((nil . (:maxlevel . 10)))))
                 (org-refile-use-outline-path
                  (if (caar org-refile-targets) 'file t))
                 (org-refile-target-verify-function nil)
                 (spos (org-refile-get-location "Entry"))
                 (message (format "spos %s" (prin1 spos)))
                 (pom (and spos (move-marker (make-marker) (nth 3 spos)
                                             (get-file-buffer (nth 1 spos))))))
            (prog1 (org-with-point-at pom (call-interactively #'org-store-link)) ;; NOTE:TODO?: interactively because of ID
              (move-marker pom nil)))))

      (defun my/org-store-link-with-outline-path-completion:insert (&optional targets)
        "like `my/org-store-link-with-outline-path-completion' but also inserts the link into the buffer"
        (interactive)
        (my/org-store-link-with-outline-path-completion targets)
        (call-interactively #'org-insert-last-stored-link))

      (defun my/org-insert-link/file ()
        (interactive)
        (org-insert-link nil (org-file-complete-link))))

    ;; org-src / org source block customizations
    (my/customize
     '(org-src-preserve-indentation t
       :comment "do not change the indentation automatically")
     '(org-src-fontify-natively t
       :comment "fontify embedded source code blocks according to language")
     '(org-src-fontify-natively t
       :comment "fontify embedded source code blocks according to language")
     '(org-src-window-setup 'current-window
       :comment "edit source code block in same window")
     '(org-src-ask-before-returning-to-edit-buffer t
       :comment "ask before editing a code block that has an open buffer already"))

    ;; org-src / org source block 
    ;; org-block is the face used in org blocks
    ;; color should be something in between comment and normal face
    (custom-set-faces
      ;; WORKAROUND: hardcoded
     '(org-block ((t (:foreground "#a8abbc")))))

    (custom-set-faces
     '(org-code ((t (:foreground "#a8979c")))))

    (progn
      ;; org-mode font lock keywords

      ;; org-mode font lock; org tables
      (progn
       (custom-set-faces
        '(org-table   ((t (:foreground nil))))
        '(org-formula ((t (:foreground nil))))))

      (my/customize '(org-emphasis-alist nil :comment "no \"markdown\" font lock")
                    '(org-fontify-emphasized-text nil :comment "no \"markdown\" font lock"))


      (add-hook 'org-font-lock-set-keywords-hook
                (lambda ()
                  (setq org-font-lock-extra-keywords
                        (append org-font-lock-extra-keywords my/font-lock-extra-keywords))))

      (defvar my/org-block-font-lock-regexp
        "^[[:space:]]*#\\+[bB][eE][gG][iI][nN]_\\([[:alpha:]]+\\)\\( [^[:space:]]+\\| \\[.+]\\)?[[:space:]]*$"
        "should catch org-blocks like this: '#+BEGIN_\(%s\)\( %s\)?'. The 2nd string can either be made of non-whitespace characters or any characters wrapped in [] (used for latex options for my latex-special-blocks)")

      (my/defface my/org-block-indicator-face
        '((t :foreground "#7777ff" :weight bold :slant italic))
        "highlihts type (and language when present) of org blocks (atm)"
        :group 'org)

      (setq my/org-block-extra-keywords
            `((,my/org-block-font-lock-regexp
               (1 'my/org-block-indicator-face t)
               (2 'my/org-block-indicator-face t t))))

      (add-hook 'org-font-lock-set-keywords-hook
                (lambda ()
                  (setq org-font-lock-extra-keywords
                        (append
                         org-font-lock-extra-keywords
                         my/org-block-extra-keywords)))))

    (progn
      ;; org-mode font lock; latex
      (my/customize '(org-highlight-latex-and-related nil
                                                      :comment "'script i.e. interferes with _ (underscore) in file or function names"))
      (custom-set-faces
       '(org-latex-and-related ((t (:foreground "#eba7ee")))))

      ;; highlight latex commands
      (add-hook 'org-font-lock-set-keywords-hook
                (lambda ()
                  (setq org-font-lock-extra-keywords
                        (append
                         org-font-lock-extra-keywords
                         '(("\\(\\\\[[:alnum:]]*\\)"
                            1 '(:foreground "burlywood") append)))))))

    (progn
      ;; org-mode; evil
      (add-hook 'org-insert-heading-hook
                #'(lambda () (evil-append nil))))

    (progn
      ;; org-mode; org tables config

      (defun my/org-table-recalculate:all ()
        (interactive)
        (org-table-recalculate 'all))

      (defun my/org-table-recalculate:iterate ()
        (interactive)
        (org-table-recalculate 'iterate))

      (defun my/org/timestamp-insert:date:now ()
        (interactive)
        (org-insert-time-stamp (current-time) nil t))

      (defun my/org/timestamp-insert:datetime:now ()
        (interactive)
        (org-insert-time-stamp (current-time) t   t)))

    ;; TODO?:
    ;;   * org-plot/gnuplot
    ;;   * org-table-export
    ;;   * org-table-convert
    ;;   * org-table-recalculate
    ;;   * org-table-sort-lines
    ;;   * org-table-sort-lines
    ;;   * org-table-toggle-
    ;;     * formula-debugger
    ;;     * coordinate-overlay

    ;; org mode; org refile; org outline;
    (my/customize
     '(org-outline-path-complete-in-steps nil
       :comment "for counsel / helm"))

    (progn
      ;; org mode; org refile

      (my/customize
       '(org-refile-use-outline-path t
                                     :comment "use full path of headlines")
       '(org-refile-allow-creating-parent-nodes t)
       '(org-refile-targets '((nil . (:maxlevel . 5))))))


    (progn
      ;; org mode; org babel
      )

    (my/customize
     'org-link-frame-setup
     '((vm . vm-visit-folder-other-frame)
       (vm-imap . vm-visit-imap-folder-other-frame)
       (gnus . org-gnus-no-new-news)
       (file . find-file)
       (wl . wl-other-frame))
     :comment "i.e. 'find-file' instead of 'find-file-other-window'"))


  (use-package org-indent
    :after (org)
    :ensure nil ;; part of org-mode
    :diminish org-indent-mode
    :config
    (add-hook 'org-mode-hook #'org-indent-mode)))



;; evil; evil textobjects; editing

(use-package evil-args
  :after (evil)
  :config
  (require 'evil-args)
  ;; (dolist (hook '(emacs-lisp-mode-hook))
  ;;   (add-hook hook `(lambda () (cl-pushnew " " ,(make-local-variable 'evil-args-delimiters)))))

  (dolist (hook '(emacs-lisp-mode-hook))
    (add-hook hook `(lambda () (setq ,(make-local-variable 'evil-args-delimiters) (list " ")))))
  (my/kbd/bind/to:i "a" 'evil-inner-arg)
  (my/kbd/bind/to:o "a" 'evil-outer-arg))

(use-package evil-visual-replace
  :after (evil)
  :config
  (require 'evil-visual-replace))

(use-package evil-surround
  :after (evil)
  :config
  (require 'evil-surround)
  (global-evil-surround-mode 1))


;; built-in; evil compatability; dired
(setq dired-mode-map (make-keymap))


;; built-in; evil compatability; isearch
;; adapted from `isearch-mode-map' def in `isearch.el'
;; NOTE: in special commands are needed to operate in isearch area
(let ((map (make-keymap)))
  (dolist (i (number-sequence ?\s 255))
    (define-key map (vector i) 'isearch-printing-char))
  (define-key map [return] 'isearch-exit)
  (define-key map "\C-s" 'isearch-repeat-forward)
  (define-key map "\C-r" 'isearch-repeat-backward)
  (define-key map "\177" 'isearch-delete-char)
  (define-key map "\C-h" 'isearch-delete-char)
  (define-key map "\C-g" 'isearch-abort)
  (define-key map "\C-w" 'isearch-abort)
  (define-key map "\C-n" 'isearch-ring-advance)
  (define-key map "\C-p" 'isearch-ring-retreat)
  (define-key map "\M-y" 'isearch-yank-pop)
  ;; Pass frame events transparently so they won't exit the search.
  ;; In particular, if we have more than one display open, then a
  ;; switch-frame might be generated by someone typing at another keyboard.
  (define-key map [switch-frame] nil)
  (define-key map [delete-frame] nil)
  (define-key map [iconify-frame] nil)
  (define-key map [make-frame-visible] nil)
  (define-key map [mouse-movement] nil)
  (define-key map [language-change] nil)
  (setq isearch-mode-map map))


;; built-in; evil compatability; ibuffer
(my/evil/set-initial-state
   :normal 'ibuffer-mode)
(setq ibuffer-mode-map (make-keymap))

(defun my/org/list-style-set:list ()
"Sets bullets of the current org list to '*'"
  (interactive)
  (org-cycle-list-bullet 2))

(defun my/org/list-style-set:enumeration ()
"Sets bullets of the current org list to '1)' enumeration"
  (interactive)
  (org-cycle-list-bullet 4))


(progn
  ;; init-lisp; easily open init lisp files
  ;; requires f.el
  (defun my/init/files ()
    "Return list of configuration files relevant to init process"
    (append '("~/.emacs"
              "~/.emacs.d/README.org"
              "~/.emacs.d/init.el")
            (f-files "~/.emacs.d/init-lisp/")))

  (defun my/init/find-files ()
    "select a file from `my/init/files' and pass it to `find-file'."
    (interactive)
    (let ((file (ivy-read "" (my/init/files)
                          :require-match t
                          :caller 'find-file)))
      (find-file file))))


;; (progn
;;   ;; editing; automatic operations after insertion

;;   (use-package electric
;;     :ensure nil ;; built-in
;;     ;; purpose
;;     ;; * electric keys: try to be smart after inserting characterd
;;     ;;                  e.g. indent
;;     ;; * electric buffer and windows: ORG:TODO:
;;     )

;;   ;; editing; always insert opening AND closing delimiters
;;   ;; TODO: alternative https://github.com/joaotavora/autopair/blob/master/autopair.el
;;   ;; TODO: replace with my own custom dumb pairing
;;   (use-package elec-pair
;;     :ensure nil ;; built-in
;;     :after (electric lisp)
;;     ;; elelctric pair mode
;;     ;; finds matching character via `matching-paren'
;;     :init
;;     (my/customize
;;      '(insert-pair-alist nil)
;;      '(electric-pair-skip-whitespace nil)
;;      '(electric-pair-pairs '((?\" . ?\")
;;                              (?\{ . ?\})
;;                              (?\[ . ?\])
;;                              (?\( . ?\)))
;;        :comment "no single quote (') since it is not paired in lisp-mode"))
;;     :config
;;     ;; always insert opening AND closing delimiters 
;;     ;; TODO: look at var `parens-require-spaces'
;;     (electric-pair-mode)))

(progn
   ;; editing;; insert balanced parenthesis
  (defun my/insert-pair-maybe (open close))

  (defmacro my/auto-pair:declare (open close)
   "`open' bind check on last character of `open'" 
    ))




;; syntax checking; flycheck; debugging
(use-package flycheck
;;:disabled t
  :diminish flycheck-mode
  :ensure t
  :config
  (global-flycheck-mode)
  (setq flycheck-check-syntax-automatically '(mode-enabled save))

  (add-hook 'flycheck-mode-hook
            (lambda () (remove-hook 'post-command-hook 'flycheck-hide-error-buffer 'local)))

  (defun my/flycheck-display-error-messages (errors)
    (when errors
      (let ((err_msgs (seq-map #'flycheck-error-format-message-and-id errors))
            (out_buf (get-buffer-create flycheck-error-message-buffer)))
        (with-current-buffer out_buf
          (unless (eq (current-buffer) (messages-buffer))
            (erase-buffer))
          (goto-char (point-max))
          (insert (string-join err_msgs "\n\n--------------------\n\n")))
        (unless (get-buffer-window out_buf 0)
          (display-buffer out_buf)))))

  (setq flycheck-display-errors-function #'my/flycheck-display-error-messages)

  (defun my/flycheck/toggle-error-list-window (&optional all-frames)
  "ALL-FRAMES like in `flycheck-get-error-list-window-list'"
    (interactive)
    (let ((window-list (flycheck-get-error-list-window-list
                        (or all-frames (selected-frame)))))
      (if window-list
          (mapc #'delete-window window-list)
        (flycheck-list-errors)))))


;; quickrun; ledger
(quickrun-add-command "ledger:bal"
  '((:command . "ledger")
    (:exec    . ("%c -f %s bal")))
  :mode 'ledger-mode)


(progn
  ;; latex
  (use-package tex 
    :ensure auctex
    :config

    ;; latex; font-lock
    (font-lock-add-keywords
     'latex-mode
     '(("\\(\\\\[[:alnum:]]*\\)" 1 font-lock-keyword-face keep)))

    ;; --------- viewing stuff
    ;; build from scratch
    (setq TeX-view-program-selection
          '((output-pdf "emacs:simple")))

    (add-to-list 'TeX-view-program-list
                 '("emacs:simple" (lambda () (find-file-other-window "%o"))))

    ;; do not confirm command with default 'View' command
    (setcdr (assoc "View" TeX-command-list)
            '("%V" TeX-run-discard-or-function nil t :help "Run Viewer"))
    ;; add command that behaves like default 'View' command
    (add-to-list 'TeX-command-list
                 '("View:prompt" "%V" TeX-run-discard-or-function t t :help "Run Viewer with prompt"))
    ;; ---------

    (my/customize
     '(TeX-engine 'xetex
       :comment "i.e. to be able to use unicode symbols in input (.tex) files"))

    (defun my/latex-save-run-command (command)
      (save-buffer)
      ;; do not confirm override
      (TeX-command command 'TeX-master-file nil))

    (defvar my/latex-compilation-command
      "LaTeX"
      "Command (name from `TeX-command-list') used process .tex by default.")

    (defun my/latex-compile ()
      "uses command specified in `my/latex-compilation-command' to process current .tex file"
      (interactive)
      (my/latex-save-run-command my/latex-compilation-command))

    ;; NOTE: taken / modified from spacemacs' latex layer
    ;; Rebindings for TeX-font
    (defun latex/font-remove () (interactive) (TeX-font nil ?\C-d))

    ;; TODO?: light (not supported by all typefaces)
    (defun latex/font-normal () (interactive) (TeX-font nil ?\C-n))
    (defun latex/font-upright () (interactive) (TeX-font nil ?\C-u)) ; same as normal
    (defun latex/font-medium () (interactive) (TeX-font nil ?\C-m))
    (defun latex/font-bold () (interactive) (TeX-font nil ?\C-b))
    (defun latex/font-teletype () (interactive) (TeX-font nil ?\C-t))
    (defun latex/font-emphasis () (interactive) (TeX-font nil ?\C-e))
    (defun latex/font-italic () (interactive) (TeX-font nil ?\C-i))
    (defun latex/font-slanted () (interactive) (TeX-font nil ?\C-s))
    (defun latex/font-calligraphic () 
      "NOTE: only useful in math-mode"
      (interactive)
      (TeX-font nil ?\C-a))
    (defun latex/font-small-caps () (interactive) (TeX-font nil ?\C-c))
    (defun latex/font-sans-serif () (interactive) (TeX-font nil ?\C-f))
    ;; roman = serif
    (defun latex/font-roman () (interactive) (TeX-font nil ?\C-r))
    (defun latex/font-serif () (interactive) (TeX-font nil ?\C-r)))


  (progn
    ;; NOTE: use either digestif or texlab
    ;; digestif
    (with-eval-after-load 'lsp-mode
      (my/customize '(lsp-tex-server 'digestif))
      (add-hook 'tex-mode-hook 'lsp)
      (add-hook 'latex-mode-hook 'lsp)
      (add-hook 'LaTeX-mode-hook 'lsp)
      (with-eval-after-load 'bibtex
        (add-hook 'bibtex-mode-hook 'lsp))))

  ;; (progn
  ;;   ;; NOTE: use either digestif or texlab
  ;;   ;; texlab
  ;;   (use-package lsp-latex
  ;;     ;; https://github.com/latex-lsp/texlab
  ;;     ;; https://github.com/ROCKTAKEY/lsp-latex
  ;;     :after (tex)
  ;;     :config
  ;;     (require 'lsp-latex)
  ;;     (add-hook 'tex-mode-hook 'lsp)
  ;;     (add-hook 'latex-mode-hook 'lsp)
  ;;     (add-hook 'LaTeX-mode-hook 'lsp)
  ;;     (with-eval-after-load 'bibtex
  ;;       (add-hook 'bibtex-mode-hook 'lsp))))
  )


;; evil; evil jumps; ace-link
(advice-add 'ace-link :around  #'my/evil-jump--push-location:around)


(progn
  ;; help; *Help*; spawn multiple *Help* windows / do not reuse it

  (defun help-buffer ()
    "NOTE: REDEF; 
Reuse `standard-output' if it is a help buffer [else multiple empty help buffers will be created by e.g. `describe-function'].
(`standard-output' is set in `with-temp-buffer-window'.)
Else: Create a new help buffer for each \"call to help\".
"
    (let ((create-new t)
          (buffer-name nil))
      (when (or (stringp standard-output)
                (bufferp standard-output))
        (let* ((out (get-buffer standard-output))
               (out-name (and out (buffer-name out))))
               (when (and out-name (string-match-p "*Help*\\(<[[:digit:]]*>\\)?" out-name))
                 (setq
                  create-new nil
                  buffer-name out-name)))) 
    (if create-new
        (buffer-name (get-buffer-create (generate-new-buffer-name "*Help*")))
      buffer-name)))

  (defun help-setup-xref (item interactive-p)
    "NOTE: REDEF: break it but avoid spawning unnecessary *Help* windows
"
    ))

(progn
  ;; electric pair; editing; automatic pair; my/auto-pair

  (defvar my/auto-pair/list
    '(("(" . ")")
      ("[" . "]")
      ("{" . "}"))
    "list of delimiting strings.
NO <> since they are used for operators")
  ;; TODO: bind last char of each sequence to scan if sequence is in fro

  (defun my/auto-pair/bind (pair-list)
    "`pair-list' is a list of (OPENING-DELIMITER . CLOSING-DELIMITER)
abbrevs OD opening delimiter; CD: closing delimiter
Returns a list (CHAR-AS-STRING FN-TO-BIND-TO)
This functions creates bindings based on `pair-list' in the keymap.
(This function should be used in a 

NEXT: NEXT: implementations with less problems:
    * explicit button to \"expand\"; like yasnippet
    * function with explicit input of opening delimiter
      (for longer delimiters)
      reserve this for shorter delimiters
      -> this function has no real purpose
      -> most things not implemented

ORG:TODO: clean up this function
NOTE: NOTE: current RESTRICTION / PRECONDITION: OD is a single char string and not unique in `pair-list'

ROUGH GIST:
simplified case with assumptions
    1) a single char can either be last char of OD or CD
       (i.e. not true for double quotes as used for strings in many programming languages)
       [i.e. resolved if 2 or 3 is resolved]
    2) ODs and/or CDs (of possibly different pairs) can share suffixes (i.e. same last char)
       (i.e. double quotes and escaped double quotes)
    3) ODs and/or CDs (of possibly different pairs) can be prefixes of each other
       NOTE: / TODO: PRECONDITION: this is not the case in `pair-list'
for each pair
  OD
    * OD length 1
      bind on char = OD: insert pair
    * OD length > 1 [NOTE: / TODO: NOT IMPLEMENTED / CANCELLED]
      let c = last char of OD
          p : OD = (concat c [x])
      bind on c: p in front of point? then insert pair else insert c
  CD 
    * CD length 1
      bind on char = CD: skip char if on char; else insert char
    * OD length > 1 [NOTE: / TODO: NOT IMPLEMENTED / CANCELLED]
      let c = last char of CD
          p : CD = (concat c [x])
      bind on c: p in front of point and CD after point?
                 then insert c and delete CD after point
                 else insert c
      * why not ...?
        * skip char as long as we match prefix;
           * i.e. problem when we want to insert prefix of delimiter 
             (e.g. \" delimiter, now we want to backslash escape)
handling cases excluded in assumptions [NOTE: / TODO: NOT EVERYTHING RESOLVEABLE; NOTHING IMPLEMENTED]
    1) resolved if 2 or 3 is resolved
    2) (but not 3)
       * OD, OD share suffix: ERROR:
         problem case: ab| [ODs a, ab]
         real life examples: double quotes and escaped double quotes
         WORKAROUND: expand longest possible OD
       * OD, CD share suffix: SEMI-OKAY (NOTE: as long as OD != CD)
         OD != CD no problem since if we type OD we would not do CD action; if we type CD we would not do OD action
         problem case: '|' [OD = CD = '; | is point; we just typed ']
       * CD, CD share suffix: OKAY (even if CD = CD; since they would to the same thing)
TODO: real life examples for 3)
    3) (but not 2)
       * OD prefix of another OD: ERROR: / FORBIDDEN case
         problem cases: a|b [where a is an OD and ab is an OD; | is point; we just typed a]
       * OD prefix of another CD: ERROR: / FORBIDDEN case
         problem cases: ab|abc OR ab|c [where ab is an OD and abs is a CD; | is point; we just typed ab]
         ?:TODO: better solution skip OD; afterward
       * CD prefix of another OD: ERROR: / FORBIDDEN case
         problem cases: a|ab [where a is a CD and ab is an OD; | is point; we just typed a]
                        we skip: -> aa|b [if we type b know we do not skip the longer CD]
       * CD prefix of another CD: ERROR: / FORBIDDEN case
         problem cases: a|ab [where a is a CD and ab is a  CD; | is point; we just typed a]
                        we skip: -> aa|b [if we type b know we do not skip the longer CD]
       current handling: shorter prefix \"wins\"
"
         (-flatten-n 1
          (mapcar (lambda (pair)
                    (lexical-let ((OD (car pair))
                                  (CD (cdr pair)))
                      ;; assumptions:
                      ;;  * OD, CD are single char strings
                      ;;  * OD,CD are all unique strings in `pair-list' (i.e. OD=CD=' not allowed)
                      (list
                       (list OD (lambda () (interactive)
                                  (insert OD)
                                  (save-excursion (insert CD))))
                       (list CD (lambda () (interactive)
                                  (let ((c (char-after)))
                                    (if (and c (= c (string-to-char CD)))
                                        (forward-char)
                                      (insert CD))))))))
                  pair-list))))


(progn
  ;; scala; sbt
  ;; taken from https://scalameta.org/metals/docs/editors/emacs.html
  (use-package scala-mode
    :mode "\\.s\\(cala\\|bt\\)$")

  (use-package sbt-mode
    :commands sbt-start sbt-command
    :config
    ;; WORKAROUND: https://github.com/ensime/emacs-sbt-mode/issues/31
    ;; allows using SPACE when in the minibuffer
    (substitute-key-definition
     'minibuffer-complete-word
     'self-insert-command
     minibuffer-local-completion-map))

   ;; sbt-supershell kills sbt-mode:  https://github.com/hvesalai/emacs-sbt-mode/issues/152
   (setq sbt:program-options '("-Dsbt.supershell=false")))

(progn
  ;; lsp-mode; IDE features; development; scala; c++ / cpp / cc; clangd
  (use-package lsp-mode
    :after (counsel)
    :config
    (add-hook 'lsp-mode-hook #'lsp-enable-which-key-integration)

    (add-hook 'scala-mode-hook #'lsp)
    (add-hook 'c-mode-hook #'lsp)
    (add-hook 'c++-mode-hook #'lsp)
    (my/customize 'lsp-prefer-flymake :none
                  :comment "rather use `flycheck-mode'")
    (my/customize 'lsp-signature-auto-activate nil
                  :comment "Popup can be annoying (i.e. when very large). Can be activated manually via  `lsp-signature-activate'")
    (my/customize 'lsp-headerline-breadcrumb-segments '(symbols)
                  :comment "file path is unnecessary and does not leave enough space for (nested) symbols")

    (with-eval-after-load 'counsel
      (defun my/counsel-file-jump:lsp-workspace-root (&optional initial-input)
        (interactive)
        (counsel-file-jump initial-input (lsp-workspace-root (or (buffer-file-name) default-directory))))


      (with-eval-after-load 'transient
        (transient-define-prefix  my/counsel-ag:transient-prefix ()
          :info-manual "Configure counsel with transient options"
          ["Arguments"
           ("-g" "Search in file name" "-g")
           ("-a" "Search all files (excl. hidden)" "--all-types")
           ("-h" "Search hidden files" "--hidden")
           (my/counsel-ag:option:ignore-dirs)
           (my/counsel-ag:option:directory)]
          ["Commands"
           ("a" "Run ag" my/counsel-ag:transient)
           ("RET" "Run ag" my/counsel-ag:transient)]
          [("q" "Quit" transient-quit-one)])

        (defun my/counsel-ag:transient (&optional args)
          (interactive (list (transient-args 'my/counsel-ag:transient-prefix)))
          (let* ((directory-choice (transient-arg-value "--;;directory=" args))
                 (directory (cond ((string-equal directory-choice "default-directory")
                                   default-directory)
                                  (t
                                   (message directory-choice)
                                   (lsp-workspace-root (or (buffer-file-name) default-directory)))))
                 (extra-args (string-join (remove (format "--;;directory=%s" directory-choice)
                                                  args)
                                          " ")))
            ;; (print args)
            ;; (print directory)
            ;; (print extra-args)
            (counsel-ag nil directory extra-args)))

        (setq my/counsel-ag:default-extra-args "--ignore-dir=i18n --ignore-dir=i18n_extra")

        (transient-define-infix my/counsel-ag:option:ignore-dirs ()
          :description "Directories to ignore"
          :class 'transient-option
          :shortarg "-i"
          :always-read t
          ;; set default value
          :init-value #'(lambda (obj)
                          (oset obj value
                                ;; "--ignore-dir=" is already added by :argument
                                (string-remove-prefix "--ignore-dir=" my/counsel-ag:default-extra-args)))
          :argument "--ignore-dir=")

        ;; TODO: cleaner way for closuer ⦓let / lexical let in counsel-ag:… functions does not work⦔
        (lexical-let
            ((my/counsel-ag:directory-choice "lsp-workspace-root"))

          (defun my/counsel-ag:option:directory:init-value (obj)
            (oset obj value my/counsel-ag:directory-choice))

          (defun my/counsel-ag:lsp-workspace-root (&optional initial-input)
            (interactive)
            (setq my/counsel-ag:directory-choice "lsp-workspace-root")
            (my/counsel-ag:transient-prefix))

          (defun my/counsel-ag:default-directory (&optional initial-input)
            (interactive)
            (setq my/counsel-ag:directory-choice "default-directory")
            (my/counsel-ag:transient-prefix)))

        (transient-define-infix my/counsel-ag:option:directory ()
          :description "Directory to search in"
          :class 'transient-option
          :shortarg "-d"
          :always-read t
          :init-value #'my/counsel-ag:option:directory:init-value
          ;; '--;;' is an internal argument
          :argument "--;;directory="
          :choices '("lsp-workspace-root" "default-directory"))))

    (with-eval-after-load 'project
      (cl-defmethod project-root ((project (head lsp)))
        (cdr project))
      (defun my/project-try-lsp-workspace-root (&optional dir)
        "To be used in `project-find-functions'."
        (when-let (path (lsp-workspace-root dir))
          (cons 'lsp (file-name-as-directory path))))
      (add-hook 'project-find-functions #'my/project-try-lsp-workspace-root)))

  (use-package lsp-ui
    :commands lsp-ui-mode
    :config
    (setq lsp-ui-sideline-show-hover nil)
    (setq lsp-ui-sideline-show-code-actions nil))

  ;; (use-package company-lsp
  ;;   :after (lsp-mode company)
  ;;   :config
  ;;   (require 'company-lsp)
  ;;   ;; (push 'company-lsp company-backends)
  ;;   ;; disable company-clang for clangd
  ;;   ;; https://clangd.github.io/installation.html#project-setup
  ;;   (setq company-backends (remove 'company-clang company-backends)))
  )

(defun my/get-buffer-window-list (&optional buffer-or-name minibuf all-frames)
  "like `get-buffer-window-list' but returns nil (insteaf of throwing error) if there is no live buffer `buffer-or-name'"
  (-when-let (buffer (get-buffer buffer-or-name))
    (get-buffer-window-list buffer minibuf all-frames)))

(defun my/flymake/toggle-diagnostics-buffer-window ()
  "if diagnostics buffer not visible in a window in current frame: `flymake-show-diagnostics-buffer'; ELSE close all windows displaying it."
    (interactive)
    (let* ((bname (flymake--diagnostics-buffer-name))
           (window-list (my/get-buffer-window-list bname nil nil)))
      (if window-list
          (mapc #'delete-window window-list)
        (call-interactively #'flymake-show-diagnostics-buffer))))

;; keybindings; REFACTOR:
(defvar my-global-keys-minor-mode-map
  (make-sparse-keymap)
  "Keymap for `my-global-keys-minor-mode'")
(evil-make-intercept-map counsel-find-file-map)
(define-minor-mode my-global-keys-minor-mode
  "Minor mode for my keybindings (via `my-global-keys-minor-mode-map')."
  :init-value t
  :lighter "")
(my-global-keys-minor-mode 1)
(my/kbd/custom-definer my/kbd/bind/my-global
 :keymaps 'my-global-keys-minor-mode-map
 :states  my/kbd/evil-states)


(progn
  ;; tags: javascript
  ;; tags: js
  ;; tags: typescript

  ;; requirements
  ;;   * tsserver (from typescript)
  ;;   * typescript-language-server
  (if (and
       (executable-find "tsserver")
       (executable-find "typescript-language-server"))
      (with-eval-after-load 'lsp-mode
        (add-hook 'js-mode-hook 'lsp))
    (message "init--config.el: 'tsserver' or 'typescript-language-server' not found")))

(progn
  ;; tags: rust
  (use-package rustic
    :ensure
    :config
    (defun my/rustic-cargo-comint-run-with-args ()
      "Like `rustic-cargo-comint-run' but "
      (interactive)
      (let ((current-prefix-arg '(4)))
        (call-interactively #'rustic-cargo-comint-run))))

  (with-eval-after-load 'lsp-mode
    ))

(progn
  ;; tags: clojure

  (use-package inf-clojure
    :ensure)

  (use-package cider
    :ensure)

  (use-package clojure-mode
    :ensure)

  (with-eval-after-load 'lsp-mode
    ))

(progn
  ;; tags: python
  (use-package with-venv)

  (use-package pyvenv
    :config
    (pyvenv-mode 1)
    (pyvenv-workon "onboarding"))

  ;; requirements
  ;;   * pylsp
  ;;     * python-lsp-ruff
  ;;   * ruff
  (with-eval-after-load 'pyvenv
    (with-eval-after-load 'lsp-mode
      ;; (lsp-register-custom-settings
      ;;  '(("pylsp.plugins.pycodestyle.enabled" ["E301" "E302" "E501"] t)))

      (add-hook 'python-mode-hook 'lsp)
      (add-hook 'python-mode-hook #'(lambda () (setq flycheck-checker-error-threshold 2000)))
      (add-hook 'python-mode-hook #'(lambda () (setq require-final-newline t)))
      (my/customize 'lsp-pylsp-configuration-sources ["pycodestyle"])
      (my/customize 'lsp-pylsp-plugins-black-enabled nil)
      (my/customize 'lsp-pylsp-plugins-pyflakes-enabled t)
      (my/customize 'lsp-pylsp-plugins-mccabe-enabled nil)
      (my/customize 'lsp-pylsp-plugins-pycodestyle-enabled t)
      (my/customize 'lsp-pylsp-plugins-pycodestyle-ignore ["E301" "E302" "E501"])
      (my/customize 'lsp-pylsp-plugins-pydocstyle-enabled nil)
      (my/customize 'lsp-pylsp-plugins-autopep8-enabled nil)
      (my/customize 'lsp-pylsp-plugins-yapf-enabled t)
      (my/customize 'lsp-pylsp-plugins-flake8-enabled nil)
      (my/customize 'lsp-pylsp-plugins-pylint-enabled nil)
      (add-hook 'python-mode-hook 'lsp)

      (if (and
           (executable-find "pylsp")
           (executable-find "ruff"))
          (with-eval-after-load 'lsp-mode
            (my/customize 'lsp-pylsp-plugins-pycodestyle-enabled nil)
            (my/customize 'lsp-pylsp-plugins-pyflakes-enabled nil)
            (my/customize 'lsp-pylsp-plugins-yapf-enabled nil)
            ;; NOTE:
            ;; pip install ruff-lsp
            (my/customize 'lsp-ruff-lsp-ruff-args
                          ["--select" "ALL"
                           ; "--preview" ; TODO: does not work currently
                           "--ignore" "ANN,B,C901,COM812,D,E501,E741,EM101,ERA001,FBT,I001,N,PD,PERF,PIE790,PLR,PT,Q,RET502,RET503,RSE102,RUF001,RUF012,S,SIM102,SIM108,SLF001,TID252,UP031,TRY002,TRY003,TRY300,UP038,E713,SIM117,PGH003,RUF005,RET,DTZ,FIX,TD,ARG,TRY400,TRY200,C408,PLW2901,PTH,EM102,INP001,CPY001,UP006,UP007,E266"])
            ;; TODO: alternative
            ;; register ruff
            ;;   adapted from https://github.com/emacs-lsp/lsp-mode/issues/3876#issuecomment-1366887555
            ;;   removed poetry related stuff
            ;; (defcustom lsp-ruff-executable "ruff-lsp"
            ;;   "Command to start the Ruff language server."
            ;;   :group 'lsp-python
            ;;   :risky t
            ;;   :type 'file)
            ;; ;; Register ruff-lsp with the LSP client.
            ;; (lsp-register-client
            ;;  (make-lsp-client
            ;;   :new-connection (lsp-stdio-connection (lambda () (list lsp-ruff-executable)))
            ;;   :activation-fn (lsp-activate-on "python")
            ;;   :add-on? t
            ;;   :server-id 'ruff
            ;;   :initialization-options (lambda ()
            ;;                             (list :settings
            ;;                                   (cl-list*
            ;;                                    (list
            ;;                                     :interpreter (vector "python")
            ;;                                   ; :path (vector
            ;;                                   ;        "ruff")
            ;;                                    :path (vector
            ;;                                           "ruff"
            ;;                                           "--select" "ALL"
            ;;                                           "--preview"
            ;;                                           "--ignore" "E402,ANN,B,C901,COM812,D,E501,E741,EM101,ERA001,FBT,I001,N,PD,PERF,PIE790,PLR,PT,Q,RET502,RET503,RSE102,RUF001,RUF012,S,SIM102,SIM108,SLF001,TID252,UP031,TRY002,TRY003,TRY300,UP038,E713,SIM117,PGH003,RUF005,RET,DTZ,FIX,TD,ARG,TRY400,TRY200,C408,PLW2901,PTH,EM102,INP001,CPY001,UP006,UP007,E266,PIE808")
            ;;                                     ))))))
            )
        (message "init--config.el: 'pylsp' or 'ruff' not found")))))




(progn
  ;; tags: debugging
  ;; tags: python
  ;; setup adapted from https://emacs-lsp.github.io/dap-mode/page/python-poetry-pyenv/
  (use-package dap-mode
    :after (lsp-mode with-venv transient)
    :commands dap-debug
    :hook ((python-mode . dap-ui-mode) (python-mode . dap-mode) (python-mode . dap-ui-controls-mode))
    :init

    (my/customize 'dap-ui-variable-length 80)
    (my/customize 'dap-ui-controls-mode nil
                  :commentn: "I do not use it; it may hide code.")

    (remove-hook 'dap-stopped-hook #'dap-ui--show-many-windows)
    (my/customize 'dap-auto-configure-mode nil
                  :comment "No auto-configuration of windows")
    (my/customize 'dap-auto-configure-features nil
                  :comment "No auto-configuration of windows")
    (my/customize 'dap-ui-many-windows-mode nil
                  :comment "Do not show all the windows when breakpoint is hit.")

    (my/customize 'dap-debug-restart-keep-session nil
                  :comment "Reuse same session on restart")

    (defun my/dap-switch-to-terminal-buffer ()
      (interactive)
      (let* ((debug-session (dap--cur-session))
             (title "Python Debug Console")
             (terminal-buffer (format "*%s %s*"
                                      (dap--debug-session-name debug-session)
                                      (if title (concat "- " title) "console"))))
        (switch-to-buffer terminal-buffer)))

    (progn
      ;; override to reuse terminnal buffer instead of always creating a new one

      (defun dap--calculate-unique-name (debug-session-name debug-sessions)
        "override: NOTE: just use debug-session-name; do not make unique"
        (or (cl-second (s-match "\\(.*\\)<.*>" debug-session-name))
            debug-session-name))

      (defun dap--make-terminal-buffer (title debug-session)
        "Generate an internal terminal buffer.
Th  e name is derived from TITLE and DEBUG-SESSION. This function
sh  ould be used in `dap-internal-terminal-*'."
        (get-buffer-create ;; reuse buffer
         (format "*%s %s*"
                 (dap--debug-session-name debug-session)
                 (if title (concat "- " title) "console")))))

    ;; tags: rust
    (require 'dap-lldb)
    (require 'dap-cpptools)
    (dap-cpptools-setup)  ;; downloads the VScode extension
    ;; (require 'dap-gdb-lldb) ;; TODO: alternative debuggers
    ;; TODO:?: just use (lsp-rust-analyzer-debug)
    (dap-register-debug-template "rust-lldb cppdbg"
          (list :type "cppdbg"
                :request "launch"
                :name "Rust::run"
                :miMode "lldb"
                :gdbpath "rust-lldb"
                :program "${workspaceFolder}/target/debug/${workspaceFolderBasename}"
                :cwd "${workspaceFolder}"
                :environment []))
    ;; (dap-register-debug-template
    ;;  "Rust::GDB Run Configuration from website"
    ;;  (list :type "gdb"
    ;;        :request "launch"
    ;;        :name "GDB::Run"
    ;;        :gdbpath "rust-gdb"
    ;;        :target nil
    ;;        :cwd nil))

    ;; tags: python
    (require 'dap-python)
    ;; if you installed debugpy, you need to set this
    ;; https://github.com/emacs-lsp/dap-mode/issues/306
    (setq dap-python-debugger 'debugpy)

    (my/customize 'dap-ui-controls-screen-position #'posframe-poshandler-frame-top-right-corner)

    (define-minor-mode +dap-running-session-mode
      "A mode for adding keybindings to running sessions"
      nil
      nil
      (make-sparse-keymap)
      (evil-normalize-keymaps) ;; if you use evil, this is necessary to update the keymaps
      ;; The following code adds to the dap-terminated-hook
      ;; so that this minor mode will be deactivated when the debugger finishes
      (when +dap-running-session-mode
        (lexical-let ((session-at-creation (dap--cur-active-session-or-die)))
          (add-hook 'dap-terminated-hook
                    (lambda (session)
                      (when (eq session session-at-creation)
                        (+dap-running-session-mode -1)))))))

    ;; Activate this minor mode when dap is initialized
    (add-hook 'dap-session-created-hook '+dap-running-session-mode)

    ;; Activate this minor mode when hitting a breakpoint in another file
    (add-hook 'dap-stopped-hook '+dap-running-session-mode)

    ;; Activate this minor mode when stepping into code in another file
    (add-hook 'dap-stack-frame-changed-hook (lambda (session)
                                              (when (dap--session-running session)
                                                (+dap-running-session-mode 1))))

    (defun dap-python--pyenv-executable-find (command)
      (with-venv (executable-find "python")))
    ;; (add-hook 'dap-stopped-hook
    ;;           (lambda (arg) (call-interactively #'dap-hydra)))

    (defun my/dap-delete-all-sessions-then-debug ()
      (interactive)
      (dap-delete-all-sessions)
      (call-interactively #'dap-debug))

    (my/defvar my/dap-debug:transient-prefix-function 'dap-debug
               "Function called by `my/dap-debug:transient-prefix'")

    (defun my/dap-debug:transient-prefix ()
      "Call `my/dap-debug:transient-prefix-function'"
      (interactive)
      (call-interactively my/dap-debug:transient-prefix-function))))

(progn
  ;; org-mode; epa

  (defun my/org/gpgify-buffer:current ()
    "PRECONDITION: current buffer has .org.gpg file ending"
    (interactive)
    (save-excursion
      (goto-char (point-min))
      (insert "# -*- mode:org; epa-file-encrypt-to: (\"eurl3\") -*-")
      (open-line 1)
      (org-mode-restart)))

  (defun my/org/gpgify-buffer (&optional buffer)
    "PRECONDITION: current buffer has .org.gpg file ending"
    (interactive)
    (if buffer
        (with-current-buffer buffer (my/org/gpgify-buffer:current))
      (my/org/gpgify-buffer:current)))

  (my/help/useful-unbound-function:declare 'my/org/gpgify-buffer)

  (defun my/org/gpgify-file ()
    "When `buffer-file-name' does not have '.gpg' extension then add it (switch buffers).
Call `my/org/gpgify-buffer' either way."
    (interactive)
    (when-let ((old-path (buffer-file-name)))
      (if (f-ext-p old-path "gpg")
          (my/org/gpgify-buffer)
        (let ((new-path (format "%s.gpg" old-path))
              (old-buffer (current-buffer)))
          (find-file new-path)
          (insert-buffer-substring old-buffer)
          (my/org/gpgify-buffer)
          (save-buffer)
          (revert-buffer nil t)
          (kill-buffer old-buffer)
          (when (f-file? old-path)
            (delete-file old-path))))))
  (my/help/useful-unbound-function:declare 'my/org/gpgify-file))


;; ielm
(my/customize '(ielm-prompt "ELISP>\n" :comment "start input at beginning of line"))

(defun my/ielm (&optional buffer)
  (interactive)
  (let ((buffer (or buffer (current-buffer))))
    (ielm)
    (ielm-change-working-buffer buffer)
    (goto-char (point-max))))


;; calendar
(my/customize '(calendar-week-start-day 1 :comment "Start on monday."))


(progn
  (defun my/revert-buffer ()
    "Ignores auto save files.
Only prompt if current buffer is modified."
    (interactive)
    (revert-buffer t (not (buffer-modified-p)))))


(progn
  ;; external browser
  (my/defvar my/next-browser-exe "~/next.sh"
             "path to 'next' browser executable / script")
  (defun my/browse-url-next (url)
    (start-process (format "next %s" url) nil my/next-browser-exe url))

  (my/defvar my/surf-browser-exe "~/bin/surf.sh"
             "path to 'surf' browser executable / script")
  (defun my/browse-url-surf (url)
    (start-process (format "surf %s" url) nil my/surf-browser-exe url))

  (my/customize '(browse-url-browser-function
                  (lambda (url &rest args)
                    (if (executable-find "~/bin/surf.sh")
                        (my/browse-url-surf url)
                      (message "surf browser not found")
                      (if (executable-find browse-url-firefox-program)
                          (browse-url-firefox url 'new-window)
                        (message "firefox browser not found")
                        (apply 'browse-url-default-browser url args)))))))


;; tags: ivy / counsel; company
(defun my/counsel-company ()
  "Complete using `company-candidates'."
  (interactive)
  (company-assert-enabled)
  (unless company-candidates
      (company-auto-begin))
    (ivy-read "Candidate: " company-candidates
                :action (lambda (selection) (when (company-manual-begin) (company-finish selection)))
                :caller 'counsel-company))


;; tags: minibuffer; read
(my/defun my/read-from-minibuffer (prompt)
  (let ((position-info nil)        )
    (let ((input (read-from-minibuffer
                  prompt nil
                  (let ((map (make-sparse-keymap)))
                    (set-keymap-parent map minibuffer-local-map)
                    (define-key map
                      [remap exit-minibuffer] (lambda ()
                                                (interactive)
                                                (let ((first (minibuffer-prompt-end)))
                                                  (setq position-info (list 0 (- (point) first) (- (point-max) first))))
                                                (exit-minibuffer)))
                    map))))
      (when position-info
        (cons input position-info)))))

;; tags: editing; insert
(my/defun my/insert-at-position (pos string)
 "insert string STRING after position or marker POS
PRECONDITION: pos is valid position in buffer"
  (save-excursion
    (goto-char pos)
    (insert string)))

;; tags: editing; surround
(my/defun my/surround-region (region-first region-end string-pre string-post)
"REGION-FIRST, REGION-END are positions or markers denoting a region.
STRING-PRE, STRING-POST are strings to be inserted at positions REGION-FIRST and REGION-END respectively.
PRECONDITION: (region-first region-end) represents valid region; i.e. region-end ≥ region-first"
  (interactive)
  ;; insert STRING-PRE first ⇝ position of region-end wrong
  (my/insert-at-position region-end   string-post)
  (my/insert-at-position region-first string-pre))

;; tags: editing; surround
(my/defun my/surround-region--keep-indentation (region-first region-end string-pre string-post)
"REGION-FIRST, REGION-END are positions or markers denoting a region.
STRING-PRE, STRING-POST are strings to be inserted at positions REGION-FIRST and REGION-END respectively.
After every newline (`length' STRING-PRE) spaces (u+20) will be inserted
PRECONDITION: (region-first region-end) represents valid region;
                * i.e. region-end ≥ region-first
                * region-first ≥ 0"
  (interactive)
  ;; insert STRING-PRE first ⇝ position of region-end wrong
  (my/insert-at-position region-end   string-post)
  (save-excursion
    (goto-char region-end)
    (let ((line-beg (line-beginning-position))
          (num-spaces (length string-pre)))
      ;; case line-beg = 0
      ;; ⇒⦗region-first ≥ 0⦘ line-beg = 0 ≤ region-first
      (while (> line-beg region-first)
        (message "%S %S" line-beg (point))
        (progn
          ;; insert spaces
          (goto-char line-beg)
          (save-excursion
            ;; save excursion guarantees that we are still at line-beginning
            (insert-char #x20 num-spaces)))
        (progn
          ;; calculate next line beginning
          ;; case we are at first character of buffer
          ;; ⇒⦗region-first ≥ 0⦘ line-beg = 0 ≤ region-first
          ;; ⇒loop will be broken
          (backward-char)
          (setq line-beg (line-beginning-position))))))
  (my/insert-at-position region-first string-pre))


;; tags: editing; surround; evil; minibuffer
(my/defun my/evil-surround-region-from-minibuffer ()
"uses `my/surround-region--keep-indentation' as \"backend\".
PRECONDITIONS: (evil-visual-state-p)"
  (interactive)
  ;; TODO: region-first, region-end
  (message "%S" (evil-visual-range))
  (when (evil-visual-state-p)
    (when-let ((selected-region (evil-visual-range)))
      (let ((read-info (my/read-from-minibuffer "surround ⦗point represents region to surround⦘: ")))
        (when read-info
          (cl-destructuring-bind (region-first region-end type &rest properties) selected-region
            ;; c.f. "evil-define-visual-selection $NAME" in "evil-states.el"
            (when (or (eq type 'inclusive)
                      (eq type 'line))
              (cl-destructuring-bind (input pmin p pmax) read-info
                (my/surround-region--keep-indentation
                 region-first region-end
                 (substring-no-properties input nil p)
                 (substring-no-properties input p   nil))))))))))



(progn
  ;; tags faces ; font-lock ; comment ; doc string
  (lexical-let ((col "#8899aa"))
    (custom-set-faces
     `(font-lock-comment-face ((t (:foreground ,col))))
     `(font-lock-comment-delimiter-face ((t (:foreground ,col))))
     `(font-lock-doc-face ((t (:foreground ,col)))))))



(progn
  ;; unicode input; clipboard

  (with-eval-after-load 'org
    ;; (my/defvar clipboard-buffer-mode-map
    ;;            (lexical-let ((map (make-sparse-keymap)))
    ;;              (set-keymap-parent map org-mode-map)
    ;;              (define-key map [remap quit-window]
    ;;                (lambda ()
    ;;                  (interactive)
    ;;                  (kill-current-buffer)
    ;;                  (quit-window)))
    ;;              (define-key map [remap save-buffer]
    ;;                (lambda ()
    ;;                  (interactive)
    ;;                  (kill-new (buffer-substring-no-properties (point-min) (point-max)))
    ;;                  (kill-current-buffer)
    ;;                  (quit-window)))
    ;;              map)
    ;;            "keymap for `clipboard-buffer-mode'")

    ;; (define-derived-mode clipboard-buffer-mode org-mode "CLIP"
    ;;   "see `my/spawn-clipboard-buffer'")

    ;; unicode input
    (defun my/spawn-clipboard-buffer ()
      "spawn new buffer BUF.
when closing BUF it's contents will be copied to the system clipboard.
the system clipboard may be used to paste the content to a different application.
BUF will be displayed via (`display-buffer' BUF). Thus `display-buffer-alist' can be used to customise
the display behaviour.
(`clipboard-buffer-mode') is used as major mode
TODO: rather use `my/spawn-recursive-edit-buffer'"
      (interactive)
      (lexical-let* ((b (generate-new-buffer (generate-new-buffer-name "*CLIPBOARD-BUFFER*"))))
        (with-current-buffer b
          (org-mode)
          (lexical-let ((map (make-sparse-keymap)))
            (define-key map [remap quit-window]
              (lambda ()
                (interactive)
                (kill-current-buffer)
                (quit-window)))
            (define-key map [remap save-buffer]
              (lambda ()
                (interactive)
                (kill-new (buffer-substring-no-properties (point-min) (point-max)))
                (kill-current-buffer)
                (quit-window)))
            (use-local-map map)))
        (display-buffer b)))

    (defun my/spawn-recursive-edit-buffer ()
    "BUF is created via (`generate-new-buffer' (`generate-new-buffer-name' \"*RECURSIVE-EDIT-BUFFER*\")).
`recursive-edit' is used to suspend this function in favor of editing.
When this function returns it returns the string-content of BUF via `buffer-substring-no-properties'.
This function returns when the `recursive-edit' is aborted;
2 helper functions are bound for that purpose:
  [remap quit-window] can be used to \"abort\"; this function returns nil
  [remap save-window] can be used to actually return the string-conent
BUF will be displayed via (`display-buffer' BUF). Thus `display-buffer-alist' can be used to customise
the display behaviour.
`org-mode' (with above mentioned key remaps) is used as major mode.
NOTE: can be used as the following command on the CLI to open a buffer that can be edited and receive result
   printf \"$(emacsclient -e '(my/spawn-recursive-edit-buffer)')\" | sed -z -e 's/^.//' -e '${s/.$//}'
   NOTE: printf expands '\n'
         sed removes start double quote and end double quote
TODO: currently calls `evil-insert-state' in the end
"
    (interactive)
    (lexical-let* ((ret-val nil)
                   (b (generate-new-buffer (generate-new-buffer-name "*RECURSIVE-EDIT-BUFFER*"))))
      (with-current-buffer b
        (org-mode)
        (lexical-let ((map (make-sparse-keymap)))
          (define-key map [remap quit-window]
            (lambda ()
              (interactive)
              (kill-current-buffer)
              (quit-window)
              (exit-recursive-edit)))
          (define-key map [remap save-buffer]
            (lambda ()
              (interactive)
              (setq ret-val (buffer-substring-no-properties (point-min) (point-max)))
              (kill-current-buffer)
              (quit-window)
              (exit-recursive-edit)))
          (use-local-map map)))
      (display-buffer b)
      (with-current-buffer b
        (evil-insert-state))
      (recursive-edit)
      ret-val))))


(progn
  ;; tags: plain-text links ⦓non-zk⦔; text-mode

  (my/defface face/plain-link
            '((t :foreground "#e6db74" :underline t))
            "taken from 'org-link' face; used as face to fontify links matching `my/plain-link-re' in `font-lock-keywords'")

  (my/defvar my/plain-link-re
            "\\(https?\\|gopher\\)://[^[:space:][:nonascii:]\n]*"
            "used in `font-lock-keywords' to fontify links with `face/plain-link'.")

  (my/defun my/collect-all-plain-links (start limit)
    "Finds all plain links that lie complete in \"region\" (start . limit).
RETURN-VALUE:
  list of ENTRY
    ENTRY ≙ (list LINK-START-POINT LINK-END-POINT LINK-STRING)
  list is sorted wrt LINK-START-POINT from highest to lowest (descending).
e.g. use as
(my/collect-all-plain-links (window-start) (window-end))"
    (save-excursion
      (goto-char start)
      (let ((end (search-forward-regexp my/plain-link-re limit 'no-error))
            (ret-val nil))
        (while end
          (when-let ((start (match-beginning 0)))
            (push (list start end (match-string-no-properties 0))
                  ret-val))
          (setq end (search-forward-regexp my/plain-link-re  limit 'no-error)))
        ret-val)))

  (add-hook 'font-lock-mode-hook
            #'(lambda ()
                (font-lock-add-keywords nil `((,my/plain-link-re (0 'face/plain-link)))))))


(require 'my--odoo)

(require 'my--hangeul)
(require 'my--unicode-abbrev)

;; my/zk
(require 'zk)


(require 'WIP)

(provide 'init--config)
