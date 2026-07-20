(with-eval-after-load 'magit
  (with-eval-after-load 'transient
    (defvar my/odoo/directory:workspace (or (getenv "EMACS_ODOO_WORKSPACE") "/home/odoo/src"))
    (defvar my/odoo/directory:community (f-join my/odoo/directory:workspace "odoo"))
    (defvar my/odoo/directory:enterprise (f-join my/odoo/directory:workspace "enterprise"))
    (defvar my/odoo/directory:documentation (f-join my/odoo/directory:workspace "documentation"))
    (defvar my/odoo/directory:upgrade (f-join my/odoo/directory:workspace "upgrade"))
    (defvar my/odoo/directory:upgrade-util (f-join my/odoo/directory:workspace "upgrade-util"))
    (defvar my/odoo/directory:iap-apps (f-join my/odoo/directory:workspace "iap-apps"))

    (defun my/odoo/git:transient/directories-from-args (args)
      (let* ((repo-switches
              (-select (lambda (arg)
                         (member arg '("--community"
                                       "--enterprise"
                                       "--documentation"
                                       "--upgrade"
                                       "--upgrade-util"
                                       "--iap-apps")))
                      args))
             (directories-to-checkout
              (mapcar (lambda (switch)
                        (cond
                         ((string-equal switch "--community")
                          "odoo")
                         ((string-equal switch "--enterprise")
                          "enterprise")
                         ((string-equal switch "--documentation")
                          "documentation")
                         ((string-equal switch "--upgrade")
                          "upgrade")
                         ((string-equal switch "--upgrade-util")
                          "upgrade-util")
                         ((string-equal switch "--iap-apps")
                          "iap-apps")
                         (t "")))
                      repo-switches)))
        directories-to-checkout))

    (defun my/odoo/git:transient/checkout (&optional args)
      (interactive (list (transient-args 'my/odoo/git:transient-prefix)))
      (let ((directories-to-checkout (my/odoo/git:transient/directories-from-args args)))
        (print directories-to-checkout)
        (print (shell-command-to-string (string-join (cons "git-odoo-transient-checkout.sh"
                                                           (cons (let ((default-directory my/odoo/directory:enterprise))
                                                                   (magit-read-branch "Select branch"))
                                                                 directories-to-checkout))
                                                     " ")))))

    (defun my/odoo/git:transient/fetch (&optional args)
      (interactive (list (transient-args 'my/odoo/git:transient-prefix)))
      (let ((directories-to-checkout (my/odoo/git:transient/directories-from-args args)))
        (print directories-to-checkout)
        (print (string-join (mapcar (lambda (subdir)
                                      (let ((default-directory (f-join my/odoo/directory:workspace subdir)))
                                        (message (format "git:transient fetching in %s" default-directory))
                                        (shell-command-to-string "git-odoo-fetch.sh")))
                                    directories-to-checkout)
                            "\n"))))

    ;; TODO: select single branch for all
    (defun my/odoo/git:transient/delete (&optional args)
      (interactive (list (transient-args 'my/odoo/git:transient-prefix)))
      (let ((directories-to-checkout (my/odoo/git:transient/directories-from-args args)))
        (print directories-to-checkout)
        (print (string-join (mapcar (lambda (subdir)
                                      (let* ((default-directory (f-join my/odoo/directory:workspace subdir))
                                             (branch (magit-read-branch "Select branch"))
                                             (shell-command (format "git branch -d '%s'" branch)))
                                        (message (format "git:transient deleting in %s" default-directory))
                                        (when (y-or-n-p (format "%s :: %s" subdir shell-command))
                                            (shell-command-to-string shell-command))))
                                    directories-to-checkout)
                            "\n"))))

    (defun my/odoo/git:transient/push (&optional args)
      (interactive (list (transient-args 'my/odoo/git:transient-prefix)))
      (let ((directories-to-checkout (my/odoo/git:transient/directories-from-args args))
            (stored-remote nil))
        (print directories-to-checkout)
        (print (string-join (mapcar (lambda (subdir)
                                      (when-let* ((default-directory (f-join my/odoo/directory:workspace subdir))
                                                  (current-branch (magit-get-current-branch))
                                                  (remote (or (when (not (or
                                                                          (string-prefix-p "upgrade" subdir)
                                                                          (string-prefix-p "documentation" subdir)
                                                                          (string-prefix-p "iap-apps" subdir)))
                                                                stored-remote)
                                                              (magit-read-remote (format "Select remote for '%s'" subdir)))))
                                        (setq stored-remote remote)
                                        (let ((shell-command (format "git push --force-with-lease '%s' '%s:%s'" remote current-branch current-branch)))
                                          (message (format "git:transient :: %s" shell-command))
                                          (when (y-or-n-p (format "%s :: %s" subdir shell-command))
                                            (shell-command-to-string shell-command)))))
                                    directories-to-checkout)
                            "\n"))))

    (defun my/odoo/git:transient/rebase (&optional args)
      (interactive (list (transient-args 'my/odoo/git:transient-prefix)))
      (let ((directories-to-checkout (my/odoo/git:transient/directories-from-args args))
            (stored-branch nil))
        (print directories-to-checkout)
        (print (string-join (mapcar (lambda (subdir)
                                      (let* ((default-directory (f-join my/odoo/directory:workspace subdir))
                                             (branch (or (when (not (or
                                                                     (string-prefix-p "upgrade" subdir)
                                                                     (string-prefix-p "documentation" subdir)
                                                                     (string-prefix-p "iap-apps" subdir)))
                                                           stored-branch)
                                                         (magit-read-branch (format "Select branch for '%s'" subdir)))))
                                        (setq stored-branch branch)
                                        (message (format "git:transient rebase to %s" branch))
                                        (shell-command-to-string (format "git rebase %s" branch))))
                                    directories-to-checkout)
                            "\n"))))

    (defun my/odoo/git:transient/checkout-new-branch (&optional args)
      (interactive (list (transient-args 'my/odoo/git:transient-prefix)))
      (let ((directories-to-checkout (my/odoo/git:transient/directories-from-args args)))
        (print directories-to-checkout)
        (print (shell-command-to-string (string-join (cons "git-odoo-transient-checkout-new-branch.sh"
                                                           (cons (read-from-minibuffer "branch name: ")
                                                                 directories-to-checkout))
                                                     " ")))))

    (defun my/git/get-current-branch-or-string-from-branch--list ()
      (or
       (magit-get-current-branch)
       (string-remove-prefix "* " (string-remove-suffix "\n" (shell-command-to-string "git branch --list | head -n 1")))))

    (transient-define-prefix my/odoo/git:transient-prefix ()
      :value '("--community" "--enterprise") ;; activate switches by default
      [:description (lambda ()
                      (concat
                       (propertize "Repositories\n" 'face 'transient-heading)
                       (let ((default-directory my/odoo/directory:community))
                         (format "community:      %s\n" (propertize (my/git/get-current-branch-or-string-from-branch--list)
                                                                    'face 'magit-branch-local)))
                       (let ((default-directory my/odoo/directory:enterprise))
                         (format "enterprise:     %s\n" (propertize (my/git/get-current-branch-or-string-from-branch--list)
                                                                    'face 'magit-branch-local)))
                       (let ((default-directory my/odoo/directory:documentation))
                         (format "documentation:  %s\n" (propertize (my/git/get-current-branch-or-string-from-branch--list)
                                                                    'face 'magit-branch-local)))
                       (let ((default-directory my/odoo/directory:upgrade))
                         (format "upgrade:        %s\n" (propertize (my/git/get-current-branch-or-string-from-branch--list)
                                                                    'face 'magit-branch-local)))
                       (let ((default-directory my/odoo/directory:upgrade-util))
                         (format "upgrade-util:   %s\n" (propertize (my/git/get-current-branch-or-string-from-branch--list)
                                                                    'face 'magit-branch-local)))
                       (let ((default-directory my/odoo/directory:iap-apps))
                         (format "iap-apps:       %s\n" (propertize (my/git/get-current-branch-or-string-from-branch--list)
                                                                    'face 'magit-branch-local)))))
                    ("-c" "community" "--community")
                    ("-e" "enterprise" "--enterprise")
                    ("-d" "documentation" "--documentation")
                    ("-u" "upgrade" "--upgrade")
                    ("-t" "upgrade-util" "--upgrade-util")
                    ("-i" "iap-apps" "--iap-apps")
                    ]
      [[:description "Checkout"
                     ("cc" "checkout" my/odoo/git:transient/checkout)
                     ("cb" "checkout new branch" my/odoo/git:transient/checkout-new-branch)]
       [:description "Fetch"
                     ("ff" "fetch all" my/odoo/git:transient/fetch)
                     ("fb" "fetch new branch" (lambda () (interactive) (message "fetch new branch")))]
       [:description "Delete"
                     ("xx" "delete" my/odoo/git:transient/delete)]
       [:description "Rebase"
                     ("rr" "rebase all" my/odoo/git:transient/rebase)]]
      [[:description "Push"
                     ("pp" "push all" my/odoo/git:transient/push)]
       [:description "Open"
                     ("ot" "open terminal" (lambda () (interactive) (message "open terminal")))
                     ("ob" "open buffer" (lambda () (interactive) (message "open buffer")))
                     ("og" "open github" (lambda () (interactive) (message "open github")))]]
      [:description "Buffer"
                    [("g" "magit" magit-status)]
                    [("bb" "open in browser" my/guess-and-open-git-web-url)
                     ("by" "yank github url" my/guess-and-yank-git-web-url)]]
      [("q" "Quit" transient-quit-one)])))


(with-eval-after-load 'dap-mode
  (with-eval-after-load 'dap-python

    ;; (dap-register-debug-template
    ;;  "odoo-bin :: pytest"
    ;;  (list :type "python"
    ;;        :args [""]
    ;;        :cwd nil
    ;;        :target-module (expand-file-name "~/odoo/odoo/odoo-bin")
    ;;        :module "pytest"
    ;;        :request "launch"
    ;;        :name "odoo-bin :: pytest"))
    ;; (dap-register-debug-template
    ;;  "odoo-bin :: debug"
    ;;  (list :type "python"
    ;;        :args [""]
    ;;        :cwd nil
    ;;        :env '(("DEBUG" . "1"))
    ;;        :target-module (expand-file-name "~/odoo/odoo/odoo-bin")
    ;;        :request "launch"
    ;;        :name "odoo-bin :: debug"))

    (with-eval-after-load 'transient
      (transient-define-prefix  my/odoo/dap-debug:transient-prefix ()
        :value (append '("--;;with-enterprise") (when (getenv "EMACS_ODOO_WORKSPACE") '("--;;with-iap"))) ;; activate switches by default
        :info-manual "Configure counsel with transient options"
        ["Arguments"
         ("-s" "Shell" "--;;shell") ;; not a real argument
         ("-n" "No --dev" "--;;nodev") ;; not a real argument
         (my/odoo/dap-debug:option:with-demo)
         ("-q" "Stop after init" "--stop-after-init") ;; -q not real short arg
         ("-e" "with enterprise" "--;;with-enterprise") ;; not a real argument
         ("-g" "with upgrade" "--;;with-upgrade") ;; not a real argument
         ("-a" "with iap" "--;;with-iap") ;; not a real argument
         (my/odoo/dap-debug:option:database)
         (my/odoo/dap-debug:option:psql_port)
         (my/odoo/dap-debug:option:http-port)
         (my/odoo/dap-debug:option:install)
         (my/odoo/dap-debug:option:upgrade)
         (my/odoo/dap-debug:option:test-tags)]
        ["Commands"
         ("r" "Restart" dap-debug-restart)
         ("d" "Delete all sessions & run" my/odoo/dap-debug:transient)
         ("l" "Delete all sessions & launch.json" my/dap-delete-all-sessions-then-debug)
         ("X" "Delete all sessions" dap-delete-all-sessions)
         ]
        [("q" "Quit" transient-quit-one)])

      (transient-define-infix my/odoo/dap-debug:option:with-demo ()
        :description "with demo?"
        :class 'transient-switch
        :shortarg "-o"
        :init-value #'(lambda (obj)
                        (let ((default-directory my/odoo/directory:enterprise))
                          (let ((with-demo-p
                                 ;; t except if branch name starts with broken version
                                 (if-let ((branch-name (magit-get-current-branch)))
                                     (let* ((command-line-arg-broken-in-branch-version-p
                                             (-any? (lambda (version) (string-prefix-p version branch-name))
                                                    '("16.0" "17.0" "saas-17.4" "saas-17.4" "18.0" "saas-18.1" "saas-18.2"))))
                                       (not command-line-arg-broken-in-branch-version-p))
                                   t)))
                            (oset obj value (when with-demo-p "--without-demo=False")))))
        :argument "--without-demo=False")

      (transient-define-infix my/odoo/dap-debug:option:database ()
        :description "Database"
        :class 'transient-option
        :shortarg "-d"
        :always-read t
        :init-value #'(lambda (obj)
                        (let ((default-directory my/odoo/directory:enterprise))
                          (when-let ((value (magit-get-current-branch)))
                            ;; update value
                            (oset obj value value)
                            ;; update history ; taken from #'transient-infix-read
                            (let* ((history-key (or (oref obj history-key)
                                                    (oref obj command)))
                                   (transient--history (alist-get history-key transient-history))
                                   (transient--history (if (or (null value)
                                                               (eq value (car transient--history)))
                                                           transient--history
                                                         (cons value transient--history))))
                              (setf (alist-get history-key transient-history)
                                    (delete-dups transient--history))))))
        :argument "--database=")

      (transient-define-infix my/odoo/dap-debug:option:psql_port ()
        :description "psql port"
        :class 'transient-option
        :shortarg "-p"
        :always-read t
        ;; set default value
        :init-value #'(lambda (obj)
                        (oset obj value "5432"))  ;; "5433" for v14
        :argument "--psql_port=")

      (transient-define-infix my/odoo/dap-debug:option:http-port ()
        :description "http port (web)"
        :class 'transient-option
        :shortarg "-h"
        :always-read t
        ;; set default value
        :init-value #'(lambda (obj)
                        (oset obj value (if (getenv "EMACS_ODOO_WORKSPACE") "9999" "8069")))
        :argument "--http-port=")

      (transient-define-infix my/odoo/dap-debug:option:install ()
        :description "Modules to install"
        :class 'transient-option
        :shortarg "-i"
        :always-read t
        ;; set default value
        :init-value #'(lambda (obj)
                        (oset obj value nil))
        :argument "--init=")

      (transient-define-infix my/odoo/dap-debug:option:upgrade ()
        :description "Modules to upgrade"
        :class 'transient-option
        :shortarg "-u"
        :always-read t
        ;; set default value
        :init-value #'(lambda (obj)
                        (oset obj value nil))
        :argument "--update=")

      (transient-define-infix my/odoo/dap-debug:option:test-tags ()
        :description "Tests to run"
        :class 'transient-option
        :shortarg "-t"
        :always-read t
        ;; set default value
        :init-value #'(lambda (obj)
                        (oset obj value nil))
        :argument "--test-tags=")

      (defun my/odoo/dap-debug:transient (&optional args)
        (interactive (list (transient-args 'my/odoo/dap-debug:transient-prefix)))
        (let* ((workspace-dir my/odoo/directory:workspace)
               (shellp (member "--;;shell" args))
               (nodevp (member "--;;nodev" args))
               (with-demo (member "--without-demo=False" args))
               ;; TODO: rather do addons-path like database etc
               (with-enterprise (member "--;;with-enterprise" args))
               (with-upgrade (member "--;;with-upgrade" args))
               (with-iap (member "--;;with-iap" args))
               (arg-d (transient-arg-value "--database=" args))
               (arg-i (transient-arg-value "--init=" args))
               (arg-u (transient-arg-value "--update=" args))
               (arg-p (transient-arg-value "--psql_port=" args))
               (arg-h (transient-arg-value "--http-port=" args))
               (arg--test-tags (transient-arg-value "--test-tags=" args))
               (launch-args
                (vconcat
                 (when shellp
                   ["shell"])
                 `[,(concat
                     "--addons-path="
                     (string-join (vconcat ["./odoo/addons/"]
                                           (when with-enterprise
                                             ["./enterprise/"])
                                           (when with-iap
                                             ["./iap-apps/iap_common" "./iap-apps/iap_services"]))
                                  ","))]
                 ;; ["-c" "./odoo.conf"]
                 ;; ["--limit-memory-soft" "13737418240"]
                 ;; ["--limit-memory-hard" "14811160064"]
                 (when with-upgrade
                   ["--upgrade-path=./upgrade-util/src,./upgrade/migrations"])
                 (unless nodevp
                   ["--dev=all"])
                 (when with-demo
                   ["--without-demo=False"])
                 (when arg-i
                   `["-i" ,arg-i])
                 (when arg-u
                   `["-u" ,arg-u])
                 (when arg-p
                   `["--db_port" ,arg-p])
                 (when arg-h
                   `["--http-port" ,arg-h])
                 (when arg--test-tags
                   `[,(format "--test-tags=%s" arg--test-tags)])
                 `["-d" ,arg-d
                   "--limit-time-cpu" "0"
                   "--limit-time-real" "0"
                   "--log-handler" "odoo.tools.convert:DEBUG"]))
               (dap-debug-args
                (list
                 :name "odoo-bin"
                 :type "python"
                 :request "launch"
                 :program (f-join workspace-dir "odoo/odoo-bin")
                 :args launch-args
                 :cwd workspace-dir
                 :console "integratedTerminal"
                 :host "127.0.0.1")))
          (dap-delete-all-sessions)
          (message (format "my/odoo/dap-debug:transient: args = %s" args))
          (message (format "my/odoo/dap-debug:transient: launch-args = %s" launch-args))
          (dap-debug dap-debug-args))))))

(provide 'my--odoo)
