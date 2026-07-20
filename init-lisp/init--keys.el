;; -----------
;; KEYBINDINGS
;; -----------

(general-define-key
 :keymaps 'global
 [remap suspend-frame] (lambda () (interactive) nil))

;; ---------- bind prefix maps to keys
;; NOTE: see custom definers in general
;;       or documentation of e.g. my/kbd/bind/leader
(my/customize
 '(my/kbd/quick  "SPC")
 '(my/kbd/major  "SPC k")
 '(my/kbd/leader "q"))

;; --- resolve conflicts of custom definers with default keys
(my/kbd/bind/leader "" nil)
(my/kbd/bind/quick "" nil)
(my/kbd/bind/major "" nil)

;; "q" is used for defining macros in vim / evil
(my/kbd/bind/leader
 "q" 'evil-record-macro)


(general-define-key
 :keymaps '(git-rebase-mode-map
            git-commit-mode-map
            magit-revision-mode-map
            magit-status-mode-map
            magit-blame-mode-map
            magit-diff-mode-map)
 "<SPC>"  nil
 "q"      nil)

;; --- define other keys dependent of major prefix
 ;; org-mode; DEPENDENCY: prefix major key
(my/kbd/bind/major
 :keymaps 'org-mode-map
 "k" #'org-ctrl-c-ctrl-c)

;; latex
(my/kbd/bind/major
 :keymaps 'LaTeX-mode-map
 "k" 'TeX-command-master)

;; ---------- bind keys

;; ----- aborting stuff

;; TODO: ? explicit C-g binding?
(general-define-key
 "C-M-g" 'abort-recursive-edit)

;; ----- vim emulation

(my/kbd/bind/mnv
  "C-u"    'evil-scroll-up
  "C-d"    'evil-scroll-down)

(my/kbd/bind/global
  "C-i"    'evil-jump-forward
  "<tab>"  'evil-jump-forward
  "C-o"    'evil-jump-backward)

;; --- shadowed emacs bindings: <C-u>
(my/kbd/bind/mnv
  "U"      'universal-argument
  "-"      'negative-argument)

;; ----- readline compatability
(my/kbd/bind/global
  "C-h" #'evil-delete-backward-char
  "C-a" #'move-beginning-of-line
  "C-e" #'move-end-of-line
  )

;; ----- terminal compatability
(define-key key-translation-map
  (kbd "<C-;>") (kbd ";"))
(define-key key-translation-map
  (kbd "<S-backspace>") (kbd "<backspace>"))
(define-key key-translation-map 
  (kbd "<S-iso-lefttab>") (kbd "<tab>"))


;; ----- help
(general-simulate-key
  "<f1>"
  :state nil
  :keymap nil
  :lookup nil
  :name my/simulate/help-prefix
  :docstring "open help-prefix"
  :which-key "help-prefix")

(my/kbd/bind/leader "h" 'my/simulate/help-prefix)
;; TODO:
;; (my/kbd/prefix/misc/bind   "h" 'my/simulate/help-prefix)
;; (my/kbd/prefix/misc/bind   "]" 'my/simulate/help-prefix)


;; ----- minibuffer

;; TODO: gather keymaps for globally applicable commands (evil-delete-backward-word ...)

(general-define-key
 :keymaps my/kbd/minibuffer-maps
 my/key/delete-backward-word   'evil-delete-backward-word
 my/key/delete-backward-word2  'evil-delete-backward-word
 my/key/paste-from-register    'evil-paste-from-register)



;; ----- window & buffer management

(my/kbd/bind/leader
 "br" 'my/revert-buffer)

(my/kbd/bind/mnv
  "Q" 'my/quit-some-windows-on:current-frame)

(my/kbd/bind/quick
 "q" 'quit-window
 "Q" 'my/quit-some-windows-on:current-frame)


(my/kbd/bind/quick
 "f"   'counsel-find-file
 "w"   'save-buffer
 "b"   'switch-to-buffer
 "C-b" 'kill-current-buffer
 )

;; ----- commands

(my/kbd/bind/quick
 "e" 'execute-extended-command)




;; ----- editing

(my/kbd/bind/global+
 :prefix "M-w"
 "u" 'my/last-WORD/upcase
 "l" 'my/last-WORD/downcase)

(my/kbd/bind/global+
 :prefix "C-M-w"
 "u" 'my/last-word/upcase
 "l" 'my/last-word/downcase)


;; ----- os interaction


(my/kbd/bind/quick
    "t" #'my/terminal:external)

(my/kbd/bind/leader
    "fs" 'sudo-edit-current-file
    "fS" 'sudo-edit)


;; ----- snippets and completion
;; NOTE: requires
;;   company
;;   yasnippets
;;   evil
;;   counsel

;; remove default vim style keys for completion
(my/kbd/bind/i
     "C-p" nil
     "C-n" nil)

;; delete  default bindings from yas keymaps
;; `yas-minor-mode-map' is active if yas-minor-mode is active;
(setq yas-minor-mode-map (make-keymap))
;; `yas-keymap' is active if snippet expansion is in progression
(setq yas-keymap (make-keymap))

;; yas keybindings
(general-define-key
 :keymaps '(yas-keymap)
  "<tab>"                              'yas-next-field
  "TAB"                                'yas-next-field
  "C-i"                                'yas-next-field
  "C-o"                                'yas-prev-field
;;   my/key/interactively-choose-special  'yas-expand
  "C-d"                                'yas-skip-and-clear-or-delete-char
  "C-w"                                'yas-skip-and-clear-or-delete-char
  "C-g"                                'yas-abort-snippet)

;; remove default company bindings
(setq company-active-map (make-keymap))

;; entry points for completion / snippets
(my/kbd/bind/i
  :keymaps 'global
  my/key/interactively-choose          'my/counsel-company
  my/key/choose-current-special        'yas-expand
  my/key/interactively-choose-special  'yas-insert-snippet
  "M-/"                                'hippie-expand)

(general-define-key
 :keymaps 'company-active-map
 my/key/interactively-choose            nil
 "C-s"                                  'my/counsel-company
 "C-f"                                  'my/counsel-company)


(general-define-key
 :keymaps '(company-active-map)
  "C-a"                       'company-show-location
  "C-d"                       'company-show-doc-buffer
  "C-s"                       'company-search-candidates

  "C-f"                       'company-filter-candidates

  my/key/move-down            'company-select-next
  my/key/move-up              'company-select-previous
  my/key/complete-common      'company-complete-common
  my/key/choose-current       'company-complete-selection

  "C-g"                       'company-abort
  [escape]                    '(lambda () (interactive)
                                 (company-abort)
                                 ;; NOTE: one could just call normal-mode but this is more general
                                 ;;        (e.g. good for evil-iedit-insert-state) 
                                 (funcall (general-simulate-keys "ESC")))
  [return]                    nil
  (kbd "RET")                 nil
  "TAB"                       nil
  "<tab>"                     nil)


;; =========================
;; FLAT LIST OF TAGGED FORMS
;; =========================
(progn
  ;; evil-nerd-commenter; comments
  (my/kbd/bind/quick
   "c"   'evilnc-comment-operator
   "C-c" 'evilnc-copy-and-comment-lines
   "C"   'evilnc-copy-and-comment-lines))

(progn
  ;; swiper; searching

  (general-define-key
   :keymaps 'isearch-mode-map
   "M-s" 'swiper-from-isearch)

  
  ;; swiper; searching finding files
  (my/kbd/bind/quick
    "s" 'swiper
    "S" 'swiper-all
    "F" #'counsel-file-jump
    "C-f" #'my/counsel-file-jump:lsp-workspace-root))

(progn
  ;; searching; ag
  (my/kbd/bind/quick
   "a" #'my/counsel-ag:lsp-workspace-root
   "A" #'my/counsel-ag:default-directory))

(progn
  ;; iedit; evil iedit; replace multiple
  (my/kbd/bind/quick
   ;; "I" 'evil-iedit-insert-state ;; TODO:
   "i" 'evil-iedit-state/iedit-mode))

;; quickrun; running programs
(my/kbd/bind/quick
   "r"   'quickrun
   "C-r" 'my/quickrun-shell)


;; ledger
(my/kbd/bind/major
   :keymaps 'ledger-mode-map
    "a" 'ledger-post-align-dwim
    "n" '(lambda() (interactive) (call-interactively #'ledger-add-transaction) (just-one-space) (evil-append 1))
    "r" 'ledger-report
    "R" 'ledger-reconcile
    "D" 'ledger-delete-current-transaction
    "e" 'ledger-post-edit-amount
    "c" 'ledger-mode-clean-buffer
    "C" 'ledger-sort-buffer ;; clean also sorts
    "t" 'ledger-toggle-current
    "o" 'ledger-occur
    "p" 'ledger-display-balance-at-point
    "y" 'ledger-set-year
    "m" 'ledger-set-month
    "l" 'ledger-display-ledger-stats)


;; git; magit
(my/kbd/bind/quick
 "g" #'my/git:transient-prefix)


;; (my/kbd/bind/quick
;;  ;; infix C-g;; git (not magit)
;;  "C-g y" #'my/guess-and-yank-git-web-url
;;  "C-g o" #'my/guess-and-open-git-web-url
;;  "C-g g" #'my/odoo/git:transient-prefix
;;  )

;; text editing; line actions
(my/kbd/bind/leader
 "la"    #'my/line/insert-empty:below
 "l SPC" #'my/line/make-empty
 "li"    #'my/line/insert-empty:above)


;; text editing; indenting
(my/kbd/bind/global+
 "M-t"  #'my/indent/wrt-line-above:forward
 "M-d"  #'my/indent/wrt-line-above:backward)


;; counsel; make; c-mode-base
(my/kbd/bind/major
 :keymaps 'c-mode-base-map
 "m" 'counsel-make)

;; counsel; find-file
(my/kbd/bind/major
 :keymaps 'c-mode-base-map
 "m" 'counsel-make)

(progn
  ;; counsel; imenu; semantic; jump; quick-"j"

  (my/kbd/bind/quick
   "j" 'my/counsel:imenu-or-semantic)
  
  (my/kbd/bind/quick
   :keymaps 'org-mode-map
   ;; "j" 'counsel-outline
   "j" '(lambda ()
          (interactive)
          (let ((org-refile-targets '((nil . (:maxlevel . 10)))
                                    ))
            (org-refile '(U U))))))

;; counsel; pasting
(my/kbd/bind/global
 "M-p" #'counsel-yank-pop)

;; TODO: also for REPLs
(general-define-key
 :keymaps my/kbd/minibuffer-maps
 "C-n" #'next-history-element
 "C-p" #'previous-history-element)

;; TODO:
;; tags: avy ; navigation
(my/kbd/bind/quick
 "/" 'avy-goto-word-0)



(progn
  ;; ace-link ; plain link ; zk link
  
  ;; [o]pen
  (my/kbd/bind/m
    "o"   'my/ace-link:open
    "C-o" 'my/ace-link:make-frame-open
    "M-o" 'my/ace-link:external-prog)

  (my/kbd/bind/quick
    "o"   'my/ace-link:open
    "C-o" 'my/ace-link:make-frame-open
    "M-o" 'my/ace-link:external-prog))


(progn
  ;; ivy; ivy minibuffer

  ;; TODO:
  ;; (my/kbd/bind/quick
  ;;  "r" 'ivy-resume
  ;;  ) 

  (evil-make-intercept-map ivy-minibuffer-map)
  (evil-make-intercept-map ivy-switch-buffer-map)

  (general-define-key
   ;; NOTE: / TODO: ivy-switch-buffer-map defines "C-k" [as of 2019-10-23]
   :keymaps '(ivy-minibuffer-map
              ivy-switch-buffer-map)
   "C-j"                                    'electric-newline-and-maybe-indent
   ;; select
   my/key/move-down                         'ivy-next-line
   my/key/move-up                           'ivy-previous-line
   my/key/complete-common                   'ivy-partial-or-done
   my/key/choose-current                    'ivy-alt-done   ;; go into directory or select file
   my/key/choose-current-special            'ivy-dispatching-done
   my/key/choose-input                      'ivy-immediate-done
   "RET"                                    'ivy-immediate-done
   ;; paste stuff
   my/key/paste-current-selection           'ivy-insert-current
   my/key/paste-word-at-point               'ivy-yank-word
   my/key/paste-from-register               'evil-paste-from-register
   ;; kill ring
   my/key/save-current-in-kill-ring         'ivy-kill-ring-save ;; save current candidate into kill ring
   ;; editing
   my/key/delete-backward-word              'ivy-backward-kill-word
   my/key/delete-backward-word2             'ivy-backward-kill-word
   ;; -------
   "C-o"  'ivy-occur)

  ;; WORKAROUND: switch in and out of normal state at start of minibuffer
  ;; PROBLEM:    ivy / counsel etc. minibuffer keybindings do
  ;;             not always really work
  ;;             (rather default evil state bindings are used)
  (add-hook 'minibuffer-setup-hook
            (lambda () (evil-normal-state) (evil-insert-state))))


;; org-mode; zk

(my/kbd/bind/quick
  "zk"    #'my/zk/find:prev
  "zj"    #'my/zk/find:next

  "zf"    #'my/zk/note:find_filtered
  "zF"    #'my/zk/note:find

  ;; n new
  "znn"   #'my/zk/note:find_new:plain
  "znc"   #'my/zk/note:find_new:plain+child
  "zng"   #'my/zk/note:find_new:encrypted   ;; gpg
  "znt"   #'my/zk/note:find_new:temporary
  "znb"   #'my/zk/note:find_new:expository
  "znl"   #'my/zk/note:find_new:log_note
  "znd"   #'my/zk/note:find_new:day_file
  ;; TODO: find_new
  ;;       entertainment
  ;;       music

  ;; d for day file
  "zdl"   #'my/zk/insert-day-link:interactive
  "zdd"   #'my/zk/insert-day-link:today
  "zdo"   #'my/zk/insert-on-day-link:interactive
  "zdn"   #'my/zk/day_note:interactive
  "zdt"   #'my/zk/day_note:today
  "zdv"   #'my/zk/view:links-to-a-days-notes:interactive
  ;; d for delimited section stuff
  "zd<x"  #'my/zk/delimited-section:sort-note-link-list:XID:string<:interactive
  "zd>x"  #'my/zk/delimited-section:sort-note-link-list:XID:string>:interactive
  "zd<d"  #'my/zk/delimited-section:sort-note-link-list:description:my/string<-i:interactive
  "zd>d"  #'my/zk/delimited-section:sort-note-link-list:description:my/string>-i:interactive
  ;; w for week
  "zwl"   #'my/zk/insert-week-link:interactive
  "zwd"   #'my/zk/insert-week-link:today
  "zwo"   #'my/zk/insert-on-week-link:interactive
  "zwn"   #'my/zk/week_note:interactive
  "zwt"   #'my/zk/week_note:today
  "zwv"   #'my/zk/view:links-to-a-weeks-notes:interactive

  ;; s store
  "zsf"    #'my/zk/store:find
  "zss"    #'my/zk/store:find:current-buffer
  "zst"    #'my/zk/store-dir:terminal:external
  "zsy"    #'my/zk/store-dir:kill-new
  "zsm"    #'my/zk/create-store-ln:buffer

  ;; c cite
  "zcc"   #'my/zk/insert-cite-link-to-note
  "zcn"   #'my/zk/cite-new-note:plain
  "zcm"   #'my/zk/cite-new-note:plain+transcluded

  ;; l link
  "zln"   #'my/zk/insert-note-link-to-note
  "zld"   #'my/zk/insert-date-link-to-day
  "zlD"   #'my/zk/insert-note-link-to-day
  "zlc"   #'my/zk/insert-cite-link-to-note
  "zls"   #'my/zk/insert-store-link:interactive
  "zlz"   #'my/zk/insert-store_zk-link-to-note
  "zlm"   #'my/zk/insert-meta_is-link-to-note
  "zli"   #'my/zk/insert-is-link-to-note
  "zla"   #'my/zk/insert-about-link-to-note
  "zlx"   #'my/zk/insert-context-link-to-note
  "zlr"   #'my/zk/insert-creator-link-to-note
  "zlp"   #'my/zk/insert-part_of-link-to-note
  "zlt"   #'my/zk/insert-sseq-link-to-note           ;; teilmenge
  "zll"   #'my/zk/insert-log-link-to-note
  ;; t task / thread related
  "ztp"   #'my/zk/ensure-part_of-active_task:interactive
  "ztb"   #'my/zk/find-time_budget-note
  "ztin"  #'my/zk/insert-note-link-to-active_task
  "ztic"  #'my/zk/insert-cite-link-to-active_task
  "ztiz"  #'my/zk/insert-store_zk-link-to-active_task
  "ztim"  #'my/zk/insert-meta_is-link-to-active_task
  "ztii"  #'my/zk/insert-is-link-to-active_task
  "ztia"  #'my/zk/insert-about-link-to-active_task
  "ztix"  #'my/zk/insert-context-link-to-active_task
  "ztir"  #'my/zk/insert-creator-link-to-active_task
  "ztip"  #'my/zk/insert-part_of-link-to-active_task
  "ztit"  #'my/zk/insert-sseq-link-to-active_task           ;; teilmenge
  "ztil"  #'my/zk/insert-log-link-to-active_task
  "ztt"   #'my/zk/active_task_note:interactive
  "zth"   #'my/zk/thread_note:interactive
  "ztn"   #'my/zk/find-new-subtask_note:interactive
  "ztd"   #'my/zk/log-task_note:current-buffer ;; done
  "ztl"   #'my/zk/find-new-log_note-for-active_task:interactive
  "zt;"   #'my/zk/find-new-log_note-for-current-buffer

  ;; x delete
  "zxl"   #'my/zk/delete-link-at-point-remove-side-effects
  "zxn"   #'my/zk/delete-note:find-interactive:prompt
  "zxx"   #'my/zk/delete-note:prompt

  ;; b buffer
  "zba"    #'my/zk/archive-current-buffer
  "zble"   #'my/zk/update-ensure-all-links
  "zblu"   #'my/zk/update-all-link-descriptions
  "zbs"    #'my/zk/add-symbol-for-current-note
  "zbdu"   #'my/zk/cache/update-description:buffer
  "zbm"    #'my/zk/buffer-note:make_consumable_medium
  "zbp"    #'my/zk/buffer-note:create_and_store_screenshot_and_insert_link_at_point
  "zbyz"   #'my/zk/store-dir/yank-buffer-file-link:global
  "zbys"   #'my/zk/store-dir/yank-buffer-file-link:local
  "zbfn"   #'my/zk/store-dir/find-note

  ;; a "all buffers"
  "zao"    #'my/zk/occur-all
  "zab"    #'my/zk/occur-all:buffer-XID
  "zalt"   #'my/zk/link-details-visibility--toggle

  ;; TODO: ?: quick tags
  ;; TODO: ?: quick tags for music genres / song or album/EP [song_collection]
  ;; "zii"    #'my/zk/insert-is-link ;; TODO:
  ;; "zib"    #'my/zk/ensure-link:expository ;; TODO:
  ;; "zie"    #'my/zk/ensure-link:entertainment ;; TODO:
  ;; "zia"    #'my/zk/ensure-link:application ;; TODO:
  ;; TODO: multimedia type
  )


(progn
  ;; org-mode
  (general-define-key
   :states my/kbd/evil-states
   :keymaps 'org-mode-map
   "M-i" 'my/org-insert-item
   "M-n" 'my/org-insert-heading)

  (general-define-key
   :states my/kbd/evil-states
   :keymaps 'org-mode-map
   "M-h" #'my/org-metaleft
   "M-j" #'org-metadown
   "M-k" #'org-metaup
   "M-l" #'my/org-metaright)
  
   ;; org-mode; lists; list bullets
  (my/kbd/bind/major
   :keymaps 'org-mode-map :infix "l"
   "*" #'my/org/list-style-set:list
   "1" #'my/org/list-style-set:enumeration)

  ;; org-mode; org source code blocks
  (my/kbd/bind/major
   :keymaps 'org-mode-map
   "e" 'org-edit-src-code)

  (progn
    ;; org-mode; links
    (my/kbd/bind/major
     :keymaps 'org-mode-map
     "f" 'my/org-insert-link/file)
    
    (my/kbd/bind/major
     :keymaps 'org-mode-map :infix "l"
     "t" 'org-toggle-link-display
     "s" 'org-store-link
     "i" 'org-insert-link
     "f" 'my/org-insert-link/file
     "r" 'my/org-store-link-with-outline-path-completion:insert
     "R" 'my/org-store-link-with-outline-path-completion
     "l" 'org-insert-last-stored-link))

  (progn 
    ;; org-mode; tables
    (my/kbd/bind/major
     :keymaps 'org-mode-map
     "t" '(:ignore t :which-key "TABLE"))


    (my/kbd/bind/major
     :keymaps 'org-mode-map
     :infix "t"
     "t" 'org-table-create
     "T" 'org-table-create-with-table.el
     ;; [e]valuate table
     "SPC e" 'my/org-table-recalculate:iterate
     "ee" 'org-table-recalculate 
     "ea" 'my/org-table-recalculate:all
     "ei" 'my/org-table-recalculate:iterate
     "eb" 'org-table-recalculate-buffer-tables
     "ef" 'org-table-eval-formula ;; eval [f]ormula
     "a" 'org-table-align
     "c" 'org-table-insert-column
     "C" 'org-table-delete-column
     "r" 'org-table-insert-row
     "R" 'org-table-delete-row
     "d" 'org-table-blank-field
     "h" 'org-table-hline-and-move
     "H" 'org-table-hline)

    ;; movement between fields
    (general-define-key
     :states my/kbd/evil-states
     :keymaps 'org-mode-map
     ;; NOTE: / TODO: movement between rows can be achieved via
     ;;               `next-line' `previous-line' and `org-return'
     "C-n" 'org-table-next-field
     "C-p" 'org-table-previous-field)
    ;; TODO?: moving positions of rows and columns via M-{h,j,k,l}; see promotion / demotion subtree
    )

  ;; org-mode; timestamps; date; datetime
  (my/kbd/bind/major
   :keymaps 'org-mode-map
   ;; TODO: NEXT:
   ;; my/prefix/major      'org-ctrl-c-ctrl-c
   "dd"      #'my/org/timestamp-insert:date:now
   "dt"      #'my/org/timestamp-insert:datetime:now)

  (my/kbd/bind/major
   :keymaps 'org-mode-map
   :infix "r"
   "r" 'org-refile
   "R" 'org-refile-goto-last-stored
   "y" 'org-copy
   "Y" 'org-copy
   "c" 'org-refile-cache-clear
   )
  ;; org-babel
  (my/kbd/bind/major
   :keymaps 'org-mode-map
   :infix "b" ;; babel
   "t" 'org-babel-tangle))



;; evil; editing
(my/kbd/bind/v
 "M-%"    'evil-visual-replace-query-replace
 "C-M-%"  'evil-visual-replace-replace-regexp)

(progn
  ;; evil; editing; evil textobjects; visual mode ; surround
  (my/kbd/bind/v
    "s" 'evil-surround-region)

  ;; editing; evil; surround
  (general-define-key
   :states '(visual)
   [remap evil-surround-region] #'my/evil-surround-region-from-minibuffer)

  (general-define-key
   :keymaps '(magit-status-mode-map)
   :states '(visual)
   "s"  #'magit-stage))




;; init-lisp; easily open init lisp files
(my/kbd/bind/leader
 :infix "f"
 "i" #'my/init/find-files)



(progn
  ;; tags: flycheck
  ;; leader d; flymake; debugging; error list
  (my/kbd/bind/leader :infix "d"
   "l" '(my/flycheck/toggle-error-list-window :which-key "flymake-error-window"))

  (my/kbd/bind/mnv
    :keymaps 'flycheck-error-list-mode-map
    "RET"    #'flycheck-error-list-goto-error)
  
  (my/kbd/bind/leader :infix "d"
   "l" '(my/flycheck/toggle-error-list-window :which-key "flymake-error-window")))


(progn
  ;; latex

  ;; TODO?: underline

  (my/kbd/bind/major
   :keymaps 'LaTeX-mode-map
   :infix "f"
   "r"  'latex/font-remove
   "q"  'latex/font-remove
   
   "n"  'latex/font-normal
   "b"  'latex/font-bold
   "m"  'latex/font-medium
   
   "t"  'latex/font-teletype       ; "cleaner" in "ff" put ; frequently used
   
   "c"  'latex/font-calligraphic
   
   "e"  'latex/font-emphasis
   "i"  'latex/font-italic
   "s"  'latex/font-slanted
   
   "fc" 'latex/font-small-caps
   "fs" 'latex/font-sans-serif
   "fr" 'latex/font-roman
   "fr" 'latex/font-serif
   "ft" 'latex/font-teletype)

  (my/kbd/bind/major
   :keymaps 'LaTeX-mode-map
   "bs"   #'(lambda() (interactive)
               (let ((current-environment (LaTeX-current-environment)))
                 ;; TODO: does not account for extra parameters
                 ;; NOTE: closing with 'reopen does not copy parameters but asks for them again'
                 (LaTeX-close-environment)
                 (insert (format "\\begin{%s}\n\n" current-environment))
                 (backward-char 1)))
   "bm"   #'(lambda() (interactive)
            (LaTeX-environment 'modify))
   "C-e"  #'LaTeX-close-environment
   "e"    #'LaTeX-environment
   "s"    #'LaTeX-section
   "m"    #'TeX-insert-macro
   "c"    #'my/latex-compile)

  (general-define-key
   :states '(normal insert)
   :keymaps 'LaTeX-mode-map
   "M-i" 'LaTeX-insert-item))


;; electric pair; editing; automatic pair; my/auto-pair
(cl-loop for (char-string fn) in (my/auto-pair/bind my/auto-pair/list)
           do (my/kbd/bind/i :keymaps 'global char-string fn))

;; unicode; utf-8; my/unicode-abbrev
(my/kbd/bind/my-global
  "C-c" #'insert-char
  "C-k" #'my/unicode-abbrev/expand)

(progn
 ;; ielm; comint-mode
 (general-define-key :keymaps '(comint-mode-map ielm-map)
   "C-d" nil
   "M-n" nil
   "M-p" nil)

 (my/kbd/bind/i :keymaps '(comint-mode-map ielm-map)
   "C-d" #'comint-delchar-or-maybe-eof)

 (my/kbd/bind/all-states :keymaps '(comint-mode-map ielm-map)
   "C-p" #'comint-previous-input
   "C-n" #'comint-next-input)

 (my/kbd/bind/i :keymaps 'ielm-map
   "C-m" #'ielm-send-input
   "C-j" #'newline))

;; emacs-lisp-mode
(my/kbd/bind/major :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map) :infix "e"
 "r" #'eval-region
 "b" #'eval-buffer
 "l" #'eval-last-sexp
 "d" #'eval-defun)


(progn
  ;; debugger; debugging
  (my/kbd/bind/all-states :keymaps 'debugger-mode-map
  "c" #'debugger-continue      ;; continue to next break point (`debug-on-entry')
  "C" #'debugger-jump          ;; continue; ignore all (`debug-on-entry')
  "s" #'debugger-step-through  ;; step
  "x" #'debugger-toggle-locals
  ))

(my/kbd/bind/quick
 ;; infix l;; lsp-mode
 "ld" #'lsp-find-definition
 "lr" #'lsp-find-references
 "li" #'lsp-rename
 "lp" #'lsp-describe-thing-at-point
 "l=b" #'lsp-format-buffer
 "l==" #'lsp-format-buffer
 "l=r" #'lsp-format-region
 "l SPC" lsp-command-map
 )


(my/kbd/bind/quick
 ;; infix d;; dap-mode
 "dd" #'my/dap-debug:transient-prefix
 "dD" #'dap-debug
 "dt" #'dap-breakpoint-toggle ;; [t]oggle
 "dbt" #'dap-breakpoint-toggle ;; [t]oggle
 "dbx" #'dap-breakpoint-delete
 "dbX" #'dap-breakpoint-delete-all
 "dbl" #'dap-breakpoint-log-message
 "dbc" #'dap-breakpoint-condition
 "dbg" #'dap-ui-breakpoints-goto
 "dbs" #'dap-ui-breakpoints-browse ;; [s]earch
 "dh" #'dap-hydra
 "dx" #'dap-delete-session
 "dX" #'dap-delete-all-sessions
 "dq" #'dap-disconnect
 "de" #'dap-eval
 "di" #'dap-ui-repl
 "dui" #'dap-ui-repl
 "dul" #'dap-ui-locals
 "due" #'dap-ui-expressions
 "dub" #'dap-ui-breakpoints
 "dus" #'dap-ui-sessions
 "duh" #'dap-ui-hydra
 "duo" #'dap-go-to-output-buffer
 "dut" #'my/dap-switch-to-terminal-buffer
 "ds" #'dap-step-in
 "dr" #'dap-step-out ;; [r]eturn
 "dn" #'dap-next ;; "step over"
 "dc" #'dap-continue
 "dfk" #'dap-up-stack-frame
 "dfs" #'dap-switch-stack-frame
 "dfj" #'dap-down-stack-frame
 )



;; evil default keys
(general-define-key
 :states my/kbd/evil-states
 "C-z" nil)
(general-define-key
 :states my/kbd/evil-states
 "C-z" nil)


;; i.e. for minibuffer newlines
(my/kbd/bind/i
 "C-j" #'self-insert-command)

(my/kbd/bind/global+
 "<f7>" #'my/ielm)

;; evil default keys; editing
(general-define-key
 :states my/kbd/evil-states
  [remap evil-join] 'evil-join-whitespace)




;; frame, window, buffer management; evil
(define-key evil-window-map "f" #'make-frame)


;; input; hangul
(my/kbd/bind/quick
 "h" 'my/hangeul/input)

;; unicode; utf-8; my/unicode-abbrev
(my/kbd/bind/my-global
  "C-c" #'insert-char
  "C-k" #'my/unicode-abbrev/expand)

(progn
  ;; tags: rust
  (my/kbd/bind/major
   :keymaps 'rustic-mode-map
   "c" #'rustic-compile
   "r" #'my/rustic-cargo-comint-run-with-args
   "dd" #'rustic-cargo-doc
   "de" #'rustic-cargo-doc
   "R" #'rustic-cargo-comint-run
   "=" #'rustic-cargo-fmt)

  (my/kbd/bind/major
   :keymaps 'org-mode-map
   "t" '(:ignore t :which-key "test"))

  (my/kbd/bind/major
   :keymaps 'rustic-mode-map
   :infix "t"
   "t" #'rustic-cargo-test
   "c" #'rustic-cargo-current-test))

;; evil default keys; editing
(general-define-key
  :keymaps 'csv-mode-map
  [remap evil-next-line] 'evil-next-visual-line
  [remap evil-previous-line] 'evil-previous-visual-line
  )

(provide 'init--keys)
