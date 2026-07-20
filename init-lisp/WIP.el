(add-hook 'nxml-mode-hook #'(lambda () (setq require-final-newline t)))

(add-hook 'magit-mode-hook #'(lambda () (setq truncate-lines nil)))



(my/customize 'nxml-child-indent 4
              :comment "Indent children elements with 4 spaces")

(use-package csv-mode
  :ensure t
  :init)

(progn
  ;; open links in github

  (defun my/guess-git-web-url (remote-url branch file-path line-number)
    "All arguments are strings.
   E.g. (my/guess-git-web-url \"git@github.com:odoo/odoo.git\"
                              \"master\"
                              \"addons/account/models/account_move_line.py\"
                              \"234\")"
    (cl-destructuring-bind (user . remote-url-without-user)
        (my/split-string-once (string-remove-suffix ".git" remote-url)
                              "@")
      (cl-destructuring-bind (domain . repo-path)
          (my/split-string-once (string-remove-prefix "https://" remote-url-without-user)
                                ":")
        (format "https://%s/%s/tree/%s/%s#L%s" domain repo-path branch file-path line-number))))

  (defun my/guess-git-web-url:interactive ()
    (when-let ((remote (magit-read-remote "Select remote"))
               (remote-url (car (magit-git-lines "remote" "get-url" remote)))
               (branch (magit-read-branch "Select branch"))
               (file-path (magit-current-file))
               (line-number (format "%s" (line-number-at-pos))))
      (my/guess-git-web-url remote-url branch file-path line-number)))

  (defun my/guess-and-yank-git-web-url ()
    (interactive)
    (kill-new (my/guess-git-web-url:interactive)))

  (defun my/guess-and-open-git-web-url ()
    (interactive)
    (browse-url (my/guess-git-web-url:interactive))))


(custom-set-faces
 '(ediff-fine-diff-A ((t (:background "#853900" :inherit nil)))))

(custom-set-faces
 '(ediff-fine-diff-B ((t (:background "#328b2a" :inherit nil)))))

(defun emerge-refresh-mode-line ()
  (setq emerge-number-of-differences (or emerge-number-of-differences 0))
  (setq mode-line-buffer-identification
        (list (format "Emerge: %%b   diff %d of %d%s"
                      (1+ emerge-current-difference)
                      emerge-number-of-differences
                      (if (and emerge-difference-list
                               (>= emerge-current-difference 0)
                               (< emerge-current-difference
                                  emerge-number-of-differences))
                          (cdr (assq (aref (aref emerge-difference-list
                                                 emerge-current-difference)
                                           6)
                                     '((A . " - A")
                                       (B . " - B")
                                       (prefer-A . " - A*")
                                       (prefer-B . " - B*")
                                       (combined . " - comb"))))
                        ""))))
  (force-mode-line-update))

(progn
  ;; my/tp; text properties; read-only; buffer content modification
  (my/defun my/tp/read-only:add (begin end)
    (interactive "r")
    (add-text-properties begin end '(read-only t rear-nonsticky (read-only))))
  (my/defun my/tp/read-only:remove (begin end)
    (interactive "r")
    (let ((inhibit-read-only t))
      (remove-text-properties begin end '(read-only t rear-nonsticky (read-only))))))



(defun my/read ()
  (interactive)
  (lexical-let ((minibuffer-local-map nil)
                (overriding-terminal-local-map
                 (let ((map (make-keymap)))
                   (general-define-key
                    :states my/kbd/evil-states
                    :keymaps 'map
                    "C-m" #'exit-minibuffer)
                   map))
                (global-map nil)
                (widget-global-map nil)
                (minibuffer-inactive-mode-map nil))
    (read)))

(my/defvar 6000files (let ((L nil)
                           (i 0))
                       (while (< i 6000)
                         (setq L (cons (format "/home/mirs/tmp/emacs_buffer_test2/%04d" i) L))
                         (setq i (1+ i)))
                       (reverse L)))

(defun my/tmp/load/6000 ()
   (interactive)
  (message (format-time-string "%Y.%m.%d_%H:%M:%S.%3N_UTC" nil "UTC"))
  (dolist (file 6000files)
          (find-file-noselect file))
  (message (format-time-string "%Y.%m.%d_%H:%M:%S.%3N_UTC" nil "UTC")))

(defun my/tmp/load/6000-no-buffer-list-update ()
   (interactive)
  (let ((buffer-list-update-hook nil))
    (my/tmp/load/6000))
  (dolist (fn buffer-list-update-hook)
    (funcall fn)))


(defun my/test/stdout ()
  (interactive)
  (message "test"))

(defun my/test/eval ()
"for shell: \"emacsclient -e '(my/test/eval)'\";
issue: whitespace is escaped"
  (interactive)
  (intern "test test"))

;; unicode input; recursive-edit


;; does not really work for latex
;; (progn
  ;; tags: languagetool
  ;; tags: latex
  ;; tags: markdown

  ;; (use-package lsp-ltex
  ;;   :ensure t
  ;;   :after lsp-mode
  ;;   :init
  ;;   (require 'lsp-ltex)
  ;;   ;; (if (executable-find "ltex-ls")
  ;;   ;;     (with-eval-after-load 'lsp-mode
  ;;   ;;       (add-hook 'text-mode-hook 'lsp))
  ;;   ;;   (message "init--config.el: 'ltex-ls' not found"))

  ;;   ;; start lsp manually
  ;;   (unless (executable-find "ltex-ls")
  ;;       (message "init--config.el: 'ltex-ls' not found"))
  ;;   (my/customize 'lsp-ltex-ls-path "${HOME}/zk/store/2023-04-06_11.45.34.519_UTC--mirs@wrucon.org/ltex-ls-16.0.0/bin/ltex-ls")))


(provide 'WIP)
