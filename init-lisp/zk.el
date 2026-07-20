(my/defun my/string<-i (string1 string2)
  "case insensitive version of `string<'"
  (string< (downcase string1) (downcase string2)))

(my/defun my/string>-i (string1 string2)
  "case insensitive version of `string>'"
  (string> (downcase string1) (downcase string2)))

(progn
  ;; my/zk
  ;; abbrevs:
  ;;    * ID:        created via `my/zk/ID'
  ;;    * zk-subdir: direct subdir (depth 1) of zk-subdir
  ;;    * XID:      extended ID
  ;;      * currently = path relatiive to a zk-subdir
  ;;        * for notes = ID + file extension = rel-path
  ;;        * for store = NOTE-XID/REL-PATH
  ;;    * filename: = XID [for notes]

  (progn
    ;; my/zk timestamp / ID / XID
    (my/defun my/zk/timestamp (&optional time)
      "i.e. used for `my/zk/ID'"
      (format-time-string "%Y-%m-%d_%H.%M.%S.%3N_UTC" time "UTC"))

    (macrolet ((def-parse (unit start len &optional can-parse-day_XID)
                 `(defun ,(intern (format "my/zk/timestamp:parse-%s" (symbol-name unit)))
                      (string)
                    ,(if can-parse-day_XID
                         "PRECONDITION: `string' starts with a timestamp in format of `my/zk/timestamp'
or `my/zk/day_XID'."
                       "PRECONDITION: `string' starts with a timestamp in format of `my/zk/timestamp'")
                    (string-to-number (substring string ,start ,(+ start len))))))
      (def-parse year         0 4 t)
      (def-parse month        5 2 t)
      (def-parse day          8 2 t)
      (def-parse hour        11 2)
      (def-parse minute      14 2)
      (def-parse second      17 2)
      (def-parse millisecond 20 3))

    (defmacro my/zk/timestamp:with-parse-abbrevs (ts-str &rest forms)
      "replaces parse-UNIT with (my/zk/timestamp:parse-UNIT `ts-tr') in `forms'"
      (declare (indent 1))
      `(symbol-macrolet ((parse-year        (my/zk/timestamp:parse-year        ,ts-str))
                         (parse-month       (my/zk/timestamp:parse-month       ,ts-str))
                         (parse-day         (my/zk/timestamp:parse-day         ,ts-str))
                         (parse-hour        (my/zk/timestamp:parse-hour        ,ts-str))
                         (parse-minute      (my/zk/timestamp:parse-minute      ,ts-str))
                         (parse-second      (my/zk/timestamp:parse-second      ,ts-str))
                         (parse-millisecond (my/zk/timestamp:parse-millisecond ,ts-str)))
         ,@forms))

    (my/defun my/zk/timestamp:parse (ts-str)
      "i.e. used to parse the result of `my/zk/ID' into a list of
(YEAR MONTH DAY HOUR MINUTE SECOND MILLISECOND \"UTC\")."
      (my/zk/timestamp:with-parse-abbrevs ts-str
        (cl-values
         parse-year parse-month  parse-day
         parse-hour parse-minute parse-second parse-millisecond
         "UTC")))

    (my/defun my/zk/test/timestamp:parse ()
      (let ((ID (my/zk/ID)))
        (list ID
              (my/zk/timestamp:parse ID))))

    (my/defun my/zk/ID ()
      "the following functions depend on this format
  * my/zk/BOX:first-today
  * my/zk/BOX:last-today
"
      (format "%s--%s@%s"
              (my/zk/timestamp)
              (string-remove-suffix "\n" (shell-command-to-string "id -un"))
              (string-remove-suffix "\n" (shell-command-to-string "hostname"))))

    (my/defun my/zk/note_XID:plain ()
      "filename / XID for unencrypted notes [including extension; exluding directory]"
      (format "%s.org" (my/zk/ID)))

    (my/defun my/zk/note_XID:encrypted ()
      "filename / XID for encrypted notes [including extension; excluding directory]"
      (format "%s.gpg" (my/zk/note_XID:plain)))

    (my/defun my/zk/note_XID-re ()
      "matches XIDs created from `my/zk/note_XID:plain' or `my/zk/note_XID:encrypted'
(and some more with illegal dates)."
      (let ((year-re    "\\([0-9][0-9][0-9][0-9]\\)")
            (month-re   "\\([0-9][0-9]\\)")
            (day-re     "\\([0-9][0-9]\\)")
            (hour-re    "\\([0-9][0-9]\\)")
            (minute-re  "\\([0-9][0-9]\\)")
            (second-re  "\\([0-9][0-9]\\)")
            (msecond-re "\\([0-9][0-9][0-9]\\)"))
        (format "%s\\-%s\\-%s_%s.%s.%s\\.%s_UTC--\\(.*?\\)\\.org\\(\\.gpg\\)?"
                year-re month-re day-re hour-re minute-re second-re msecond-re))))

  (progn
    ;; my/zk; links

    (my/defun my/zk/link-1 (info)
      (format "[[%s:%s][%s]]" (car info) (cadr info) (caddr info)))

    (my/defun my/zk/link-3 (link-prefix XID description)
      (format "[[%s:%s][%s]]" link-prefix XID description))

    (my/defun my/zk/link-re (link-prefix-re XID-re description-re)
      "Returns regexp searching for `my/zk/note:link' with `XID-re' and `description-re' in place
of XID and DESCRIPTION respectivelye"
      (format "\\[\\[\\(%s\\):\\(%s\\)]\\[\\(%s\\)]]" link-prefix-re XID-re description-re))

    (my/defun my/zk/link-parse-prefix (link-string link-prefix-re)
      "If `link-string' contains a link matching (`my/zk/link-re' LINK-PREFIX-RE .*? .*?)
then: parse first occurence and RETURN (list LINK-PREFIX-SYM XID DESCRIPTION)
else: RETURN nil"
      (save-match-data
        (when-let ((start (string-match (my/zk/link-re link-prefix-re ".*?" ".*?") link-string)))
          (list (intern (match-string 1 link-string))
                (match-string 2 link-string)
                (match-string 3 link-string)))))

    (my/defun my/zk/link-parse-prefix-fn (link-prefix-re)
      (my/lambda (link-string)
        (my/zk/link-parse-prefix link-string link-prefix-re)))

    (progn
      ;; core link setup

      ;; TODO: this should be a struct or sth
      (my/defun my/zk/link-setup (link-prefix-sym)
        "Returns list (= link-setup specific to LINK-PREFIX-SYM) where
           nth0 = LINK-PREFIX-STRING
           nth1 = ARGS-FN [list of link type specific args → list of args compatible with `my/zk/link-1']
                  * i.e. cons link-prefix
                  * i.e. cons link-prefix
           nth2 = ADD-DERIVED-ARGS-FN [list of core link type specific args args → list of full link type specific args]
                  * i.e. description
           nth3 = GET-CORE-ARGS-FN [unary function: XID → list of _core_ link type specific args]
                  * NOTE: possibly interactive
           nth4 = PARSE-FN [(PREFIX LINK DESCRIPTION) → PARSE-FN resulut]
               * NOTE: PARSE-FN result = (cons prefix-sym <list of full link type specific args>)
           nth5 = ENSURE-SIDE-EFFECT-FN [<list of full link type specific args> → ? (executed for side effects)]
               * NOTE: should be \"idempotent\" in a way w.r.t my/zk as a whole
                       (calling the function if the effect's are already present should do no harm)
               * c.f. `my/zk/ensure-side-effect'
           nth6 = TAKE-CORE-ARGS-FN [PARSE-FN result (prefix sym + full link type specific args) → list of _core_ link type specific args]
               * c.f. `my/zk/take-core-args'
           nth7 = FILE-PATH-FN [PARSE-FN result (prefix sym + full link type specific args) → path to linked file]
               * c.f. `my/zk/parse-result:file-path'
           nth8 = ENSURE-NO-SIDE-EFFECT-FN [<list of full link type specific args> → ? (executed for side effects)]
               * NOTE: should be \"idempotent\" in a way w.r.t my/zk as a whole
                       (calling the function if the effect's are not present should do no harm)
               * c.f. `my/zk/ensure-no-side-effect'
               * \"inverse\" of ENSURE-SIDE-EFFECT-FN
NOTE: full link type specific args exclude the prefix sym (but include all other syms (also non core))
      * ⇒ prefix sym also not in core args
WHEN no appropriate setup for LINK-PREFIX-SYM is found return nil
⇝
get-xid-fn                        ≔ 'note           ↦ #'my/zk/cache/select-XID:filtered
                                  , 'day            ↦ #'my/date:interactive
                                  , 'week           ↦ #'my/week:interactive
                                  , 'current-buffer ↦ #'my/zk/buffer-XID
    c.f. `my/zk/link-setup:get-XID-fn'
complete-args-fn:interactive      ≔ ADD-DERIVED-ARGS-FN ∘ GET-CORE-ARGS-FN ∘ funcall
link-fn               ≔ link-1 ∘ ARGS-FN
link-fn:core          ≔ link-fn ∘ ADD-DERIVED-ARGS-FN
link-fn:XID-fn        ≔ link-fn ∘ complete-args-fn:interactive
link-fn:interactive   ≔ link-fn:XID-fn ∘ get-xid-fn

link-parse-fn ≔ my/skip-nil(PARSE-FN) ∘ my/zk/link-parse-prefix-fn(LINK-PREFIX-STRING)

cdr ∘ PARSE-FN ∘ ARGS-FN          ≔ identity
TAKE-CORE-ARGS-FN ∘ PARSE-FN ∘ ARGS-FN = (list of core args)
    ;; TODO: DEFERRED: PERFORMANCE: have to retrieve setup twice to get core args
    ;; ?: IDEA: maybe always additionaly return setup with all functions (as 'car') ⇝ easy chaining

insert-link-fn:pure         ≔ insert ∘ link-fn
insert-link-fn              ≔ ENSURE-SIDE-EFFECT-FN ∘ my/arg-as-result-fn(insert-link-fn:pure)
insert-link-fn:core         ≔ insert-link-fn ∘ ADD-DERIVED-ARGS-FN
insert-link-fn:XID-fn       ≔ insert-link-fn ∘ complete-args-fn:interactive
insert-link-fn:interactive  ≔ insert-link-fn:XID-fn ∘ get-xid-fn
"
        (lexical-let*
            ((TODO: (lambda ()
                      (error "my/zk/link-setup %s NOT IMPLEMENTED" link-prefix-sym)))
             (args:nth2-as-ds
              (my/lambda1 (link-prefix XID nth2 description)
                (list link-prefix (format "%s〈%s〉" XID nth2) (format "%s〈%s〉" description nth2))))
             (append-description:car-is-XID
              (my/lambda1l (&rest args)
                (append args (list (my/zk/cache/note-description (car args))))))
             (parse:ds-as-middle-arg
              (my/lambda1l (sym link desc)
                (when-let ((link:split
                            (with-temp-buffer
                              (insert link)
                              (my/zk/delimited-section:with-section-start-end
                                  "" start end
                                (cons (buffer-substring (point-min) start)
                                      (buffer-substring (+ start 1) (- end 1))))))
                           (desc:split
                            (with-temp-buffer
                              (insert desc)
                              (my/zk/delimited-section:with-section-start-end
                                  "" start end
                                (cons (buffer-substring (point-min) start)
                                      (buffer-substring (+ start 1) (- end 1)))))))
                  (when (string= (cdr link:split) (cdr desc:split))
                    (list sym (car link:split) (cdr link:split) (car desc:split))))))
             (ensure-this-files-note-link-in-section
              (my/lambda (other:XID other:section)
                (if-let ((l (my/zk/simple-link-to-buffer-file)))
                    (my/zk/with-weak-find-file-hook
                      (my/in-file-buffer:ensure+save (my/zk/note:path other:XID)
                        (my/lambda:apply-0
                         #'my/zk/delimited-section:ensure-note-link (list other:section l))))
                  (user-error "current buffer is not part of my/zk"))))
             (ensure-this-files-note-link-NOT-in-section
              (my/lambda (other:XID other:section)
                (if-let ((XID:current-buffer (my/zk/buffer-XID)))
                    (my/zk/with-weak-find-file-hook
                      (my/in-file-buffer:ensure+save (my/zk/note:path other:XID)
                        (my/lambda:apply-0
                         #'my/zk/delimited-section:remove-note-link (list other:section XID:current-buffer))))
                  (user-error "current buffer is not part of my/zk"))))
             (mk-setup:ensure-link:fixed-section
              (my/lambda (link-prefix fixed-section description-prefix)
                (list link-prefix
                      (∘ (my/cons-fn link-prefix)
                         (my/call-at 1 (ap #'format (format "%s%%s" description-prefix)))
                         (my/list-id '(XID description)))
                      append-description:car-is-XID
                      #'list
                      (∘ (my/call-at 2 (lambda (str)
                                         (save-match-data
                                           (string-trim-left str description-prefix))))
                         (my/list-id '(link-sym XID desc)))
                      (my/lambda1 (XID description) (funcall ensure-this-files-note-link-in-section XID fixed-section))
                      (∘ (my/take-indices-fn 1) (my/list-id '(sym XID description)))
                      (∘ #'my/zk/note:path (my/nth-fn 1) (my/list-id '(sym XID section description)))
                      (my/lambda1 (XID description) (funcall ensure-this-files-note-link-NOT-in-section XID fixed-section))))))
          (cond
           ((eq link-prefix-sym 'note)
            (list "note"
                  (∘ (my/cons-fn "note") (my/list-id '(XID description)))
                  append-description:car-is-XID
                  #'list
                  (my/list-id '(link-sym XID desc))
                  (my/NOP-fn)
                  (∘ (my/take-indices-fn 1) (my/list-id '(sym XID description)))
                  (∘ #'my/zk/note:path (my/nth-fn 1) (my/list-id '(sym XID description)))
                  (my/NOP-fn)))
           ((eq link-prefix-sym 'store_zk)
            (list "store_zk"
                  (∘ args:nth2-as-ds (my/cons-fn "store_zk") (my/list-id '(XID rel-path description)))
                  append-description:car-is-XID
                  (∘ (my/snd (lambda (XID)
                               (f-relative (my/zk/store:read-path XID)
                                                 (my/zk/store:path XID))))
                     (my/dup-fn))
                  parse:ds-as-middle-arg
                  (my/NOP-fn)
                  (∘ (my/take-indices-fn 1 2) (my/list-id '(sym XID rel-path description)))
                  (my/lambda1 (sym XID rel-path description)
                    (my/zk/store:path XID rel-path))
                  (my/NOP-fn)))
           ((eq link-prefix-sym 'store)
            (list "store"
                  ;; ?: TODO: manual description
                  ;;          note: automatic update of link descriptions
                  (my/lambda1 (rel-path)
                    (list "store" (format "%s" rel-path) (format "%s" rel-path)))
                  (my/list-id '(rel-path))
                  (lambda (XID)
                       (list (f-relative (my/zk/store:read-path XID)
                                         (my/zk/store:path XID))))
                  (∘ (my/take-indices-fn 0 1) (my/list-id '(sym link description)))
                  (my/NOP-fn)
                  (∘ (my/take-indices-fn 1) (my/list-id '(sym rel-path)))
                  (my/lambda1 (sym rel-path)
                    (my/zk/store:path (my/zk/buffer-XID) rel-path))
                  (my/NOP-fn)))
           ((eq link-prefix-sym 'ds)
            (list "ds"
                  (∘ args:nth2-as-ds
                     (my/call-at 2 (lambda (str) (save-match-data (string-trim-right str))))
                     (my/cons-fn "ds") (my/list-id '(XID section description)))
                  append-description:car-is-XID
                  (lambda (XID)
                       (TODO:))
                  parse:ds-as-middle-arg
                  (my/NOP-fn)
                  (∘ (my/take-indices-fn 1 2) (my/list-id '(sym XID section description)))
                  (∘ #'my/zk/note:path (my/nth-fn 1) (my/list-id '(sym XID section description)))
                  (my/NOP-fn)))
           ((eq link-prefix-sym '∈)
            (list "∈"
                  (∘ args:nth2-as-ds (my/cons-fn "∈") (my/list-id '(XID section description)))
                  append-description:car-is-XID
                  (lambda (XID)
                       (TODO:))
                  parse:ds-as-middle-arg
                  (my/lambda (XID section description) (funcall ensure-this-files-note-link-in-section XID section))
                  (∘ (my/take-indices-fn 1 2) (my/list-id '(sym XID section description)))
                  (∘ #'my/zk/note:path (my/nth-fn 1) (my/list-id '(sym XID section description)))
                  (my/lambda (XID section description) (funcall ensure-this-files-note-link-NOT-in-section XID section))))
           ((eq link-prefix-sym 'cite)
            (funcall mk-setup:ensure-link:fixed-section "cite"     "citations\n"       "↗ "))
           ((eq link-prefix-sym 'about)
            (funcall mk-setup:ensure-link:fixed-section "about"    "resources\n"       "↦ "))
           ((eq link-prefix-sym 'context)
            (funcall mk-setup:ensure-link:fixed-section "context"  "forms\n"           "○ ")) ;; U+25cb
           ((eq link-prefix-sym 'creator)
            (funcall mk-setup:ensure-link:fixed-section "creator"  "works\n"           "↢ ")) ;; U+ 211s
           ((eq link-prefix-sym 'is)
            ;; c.f. group: is, meta_is, part_of, sseq
            (funcall mk-setup:ensure-link:fixed-section "is"       "instances\n"       "≼ ")) ;; U+227c
           ((eq link-prefix-sym 'meta_is)
            ;; c.f. group: is, meta_is, part_of, sseq
            (funcall mk-setup:ensure-link:fixed-section "meta_is"  "meta-instances\n"  "⊰ ")) ;; U+22B0
           ((eq link-prefix-sym 'part_of)
            ;; c.f. group: is, meta_is, part_of, sseq
            (funcall mk-setup:ensure-link:fixed-section "part_of"  "parts\n"           "∈ "))
           ((eq link-prefix-sym 'sseq)
            ;; c.f. group: is, meta_is, part_of, sseq
            (funcall mk-setup:ensure-link:fixed-section "sseq"     "subsets\n"         "⊆ ")) 
           ((eq link-prefix-sym 'log)
            ;; c.f. group: log, meta_log
            (funcall mk-setup:ensure-link:fixed-section "log"      "journal\n"         "⤳ ")) ;; U+2933
           ((eq link-prefix-sym 'meta_log)
            ;; c.f. group: log, meta_log
            (funcall mk-setup:ensure-link:fixed-section "meta_log" "meta_journal\n"    "meta_log: "))
           ;; ((eq link-prefix-sym 'date)
           ;;  (list "date"
           ;;        (∘ (my/cons-fn "date") (my/call-at 0 #'my/zk/day_XID) (my/list-id '(date description)))
           ;;        (my/lambda1 (date)
           ;;          (list date (format-time-string "(%Y-%m-%d %a)" (encode-time 0 0 0 (caddr date) (cadr date) (car date)))))
           ;;        (∘ (my/list-id '(date)) #'my/date:interactive)
           ;;        (my/lambda1 (link-sym XID desc)
           ;;          (list link-sym (my/zk/day_XID-to-date XID) desc))
           ;;        (my/lambda1 (date description)
           ;;          (funcall ensure-this-files-note-link-in-section (my/zk/day_XID date) "mentions\n"))
           ;;        (∘ (my/take-indices-fn 1) (my/list-id '(sym date description)))
           ;;        (∘ #'my/zk/note:path
           ;;           #'my/zk/day_XID
           ;;           (my/nth-fn 1)
           ;;           (my/list-id '(sym date description)))
           ;;        (my/lambda1 (date description)
           ;;          (funcall ensure-this-files-note-link-NOT-in-section (my/zk/day_XID date) "mentions\n"))))
           ((eq link-prefix-sym 'date)
            (list "date"
                  (∘ (my/cons-fn "date") (my/list-id '(XID description)))
                  append-description:car-is-XID
                  #'list 
                  (my/list-id '(link-sym XID desc))
                  (my/lambda1 (XID description)
                    (funcall ensure-this-files-note-link-in-section XID "mentions\n"))
                  (∘ (my/take-indices-fn 1) (my/list-id '(sym XID description)))
                  (∘ #'my/zk/note:path
                     (my/nth-fn 1)
                     (my/list-id '(sym XID description)))
                  (my/lambda1 (XID description)
                    (funcall ensure-this-files-note-link-NOT-in-section XID "mentions\n"))))
           ((eq link-prefix-sym 'on)
            (list "on"
                  (∘ (my/cons-fn "on") (my/list-id '(XID description)))
                  append-description:car-is-XID
                  #'list
                  (my/list-id '(link-sym XID desc))
                  (my/lambda1 (XID description)
                    (funcall ensure-this-files-note-link-in-section XID "schedule\n"))
                  (∘ (my/take-indices-fn 1) (my/list-id '(sym XID description)))
                  (∘ #'my/zk/note:path
                     (my/nth-fn 1)
                     (my/list-id '(sym XID description)))
                  (my/lambda1 (XID description)
                    (funcall ensure-this-files-note-link-NOT-in-section XID "schedule\n"))))
           (t nil))))

      (my/defun my/zk/link-setup→complete-args-fn:interactive (setup)
        (my/skip-nil (∘ (my/if-fn #'null
                         (lambda (null)
                           (user-error "unable to retrieve XID"))
                         (∘ (nth 2 setup) (nth 3 setup)))
                       #'funcall)))

      (my/defun my/zk/link-setup:get-XID-fn (symbol)
"return XID-fn for SYMBOL"
        (cond
         ((eq symbol 'note)
          #'my/zk/cache/select-XID:filtered)
         ((or (eq symbol 'day)
              (eq symbol 'date))
          (∘ (my/skip-nil #'my/zk/day_XID) #'my/date:interactive))
         ((eq symbol 'week)
          (∘ #'my/zk/week_XID #'my/week:interactive))
         ((eq symbol 'today)
          (∘ #'my/zk/day_XID #'my/date:today))
         ((eq symbol 'current-week)
          (∘ #'my/zk/week_XID #'my/week:today))
         ((eq symbol 'active_task)
          #'my/zk/active_task-select:XID:interactive)
         ((eq symbol 'current-buffer)
          #'my/zk/buffer-XID)
         (t (error "unknown XID-fn"))))

      (my/defun my/zk/link-setup→link-fn (setup)
        (∘ #'my/zk/link-1 (nth 1 setup)))

      (my/defun my/zk/link-setup→link-fn:core (setup)
        (∘ (my/zk/link-setup→link-fn setup) (nth 2 setup)))

      (my/defun my/zk/link-setup→link-fn:XID-fn (setup)
        (∘ (my/skip-nil (my/zk/link-setup→link-fn setup))
           (my/zk/link-setup→complete-args-fn:interactive setup)))

      (my/defun my/zk/link-setup→link-fn:interactive (setup)
        (lexical-let ((link:XID-fn (my/zk/link-setup→link-fn:XID-fn setup)))
          (lambda (XID-fn-abbrev)
            (lexical-let ((XID-fn (my/zk/link-setup:get-XID-fn XID-fn-abbrev)))
              (lambda ()
                (funcall link:XID-fn XID-fn))))))

      (my/defun my/zk/link-setup→add-derived-description-fn (setup)
        (nth 2 setup))

      (my/defun my/zk/link-setup→link-parse-fn (setup)
        (∘ (my/skip-nil(nth 4 setup)) (my/zk/link-parse-prefix-fn (car setup))))

      ;; NOTE: :pure since it does not have side effects from link-insertion or arguments-retrieval
      (my/defun my/zk/link-setup→insert-link-fn:pure (setup)
        (∘ #'insert (my/zk/link-setup→link-fn setup)))

      (my/defun my/zk/link-setup→insert-link-fn (setup)
        (∘ (nth 5 setup) (my/arg-as-result-fn (my/zk/link-setup→insert-link-fn:pure setup))))

      (my/defun my/zk/link-setup→insert-link-fn:core (setup)
        (∘ (my/zk/link-setup→insert-link-fn setup) (nth 2 setup)))

      (my/defun my/zk/link-setup→insert-link-fn:XID-fn (setup)
        (∘ (my/skip-nil (my/zk/link-setup→insert-link-fn setup))
           (my/skip-nil (my/zk/link-setup→complete-args-fn:interactive setup))))

      (my/defun my/zk/link-setup→insert-link-fn:interactive (setup)
        (lexical-let ((insert:XID-fn (my/zk/link-setup→insert-link-fn:XID-fn setup)))
          (lambda (XID-fn-abbrev)
            (lexical-let ((XID-fn (my/zk/link-setup:get-XID-fn XID-fn-abbrev)))
              (lambda ()
                (funcall insert:XID-fn XID-fn))))))))

    (progn
      ;; prefix-sym ↦ some further function
      (defalias 'my/zk/link-fn                         (∘  #'my/zk/link-setup→link-fn                       #'my/zk/link-setup))
      (defalias 'my/zk/link-fn:core                    (∘  #'my/zk/link-setup→link-fn:core                  #'my/zk/link-setup))
      (defalias 'my/zk/link-fn:XID-fn                  (∘  #'my/zk/link-setup→link-fn:XID-fn                #'my/zk/link-setup))
      (defalias 'my/zk/link-fn:interactive             (∘  #'my/zk/link-setup→link-fn:interactive           #'my/zk/link-setup))
      (defalias 'my/zk/add-derived-description-fn      (∘  #'my/zk/link-setup→add-derived-description-fn    #'my/zk/link-setup))
      (defalias 'my/zk/complete-args-fn                (∘  #'my/zk/link-setup→complete-args-fn:interactive  #'my/zk/link-setup))
      (defalias 'my/zk/insert-link-fn:pure             (∘  #'my/zk/link-setup→insert-link-fn:pure           #'my/zk/link-setup))
      (defalias 'my/zk/insert-link-fn                  (∘  #'my/zk/link-setup→insert-link-fn                #'my/zk/link-setup))
      (defalias 'my/zk/insert-link-fn:core             (∘  #'my/zk/link-setup→insert-link-fn:core           #'my/zk/link-setup))
      (defalias 'my/zk/insert-link-fn:XID-fn           (∘  #'my/zk/link-setup→insert-link-fn:XID-fn         #'my/zk/link-setup))
      (defalias 'my/zk/insert-link-fn:interactive      (∘  #'my/zk/link-setup→insert-link-fn:interactive    #'my/zk/link-setup))
      (defalias 'my/zk/link-parse-fn                   (∘  #'my/zk/link-setup→link-parse-fn                 #'my/zk/link-setup)))

    ;; TODO: RESEARCH
    (my/defun my/chain-resulting-function-after (new-fn fn)
      "example:
(funcall (funcall (my/chain-resulting-function-after #'list (my/const 'length)))
         1 2 3 4 5)
⇝ 5"
      (lambda (&rest args)
        (∘ (apply fn args) new-fn)))

    ;; TODO: RESEARCH
    (my/defun my/wrap-resulting-function (wrap-fn fn)
      "example:
(funcall (funcall (my/wrap-resulting-function #'my/skip-nil (my/const '+)))
         nil)
⇝ nil"
      (lambda (&rest args)
        (funcall wrap-fn (apply fn args))))

    ;; TODO: DEFERRED: performance: macros to fetch functions for prefix at compile time

    ;; functions: prefix-sym ↦ [fn: &rest args ↦ result]
    (defalias 'my/zk/link-fn*                    (my/chain-resulting-function-after     #'list          #'my/zk/link-fn))
    (defalias 'my/zk/link-fn:core*               (my/chain-resulting-function-after     #'list          #'my/zk/link-fn:core))
    (defalias 'my/zk/insert-link-fn:pure*        (my/chain-resulting-function-after     #'list          #'my/zk/insert-link-fn:pure))
    (defalias 'my/zk/insert-link-fn*             (my/chain-resulting-function-after     #'list          #'my/zk/insert-link-fn))
    (defalias 'my/zk/insert-link-fn:core*        (my/chain-resulting-function-after     #'list          #'my/zk/insert-link-fn:core))
    ;; functions: prefix-sym, xid-fn ↦ [fn: () ↦ result]
    (defalias 'my/zk/link-fn:XID-fn*             (my/uncurry-1 #'my/zk/link-fn:interactive))
    (defalias 'my/zk/insert-link-fn:XID-fn*      (my/uncurry-1 #'#'my/zk/insert-link-fn:interactive))
    ;; functions: prefix-sym, xid-fn-abbrev ↦ [fn: () ↦ result]
    (defalias 'my/zk/link-fn:interactive*        (my/uncurry-1 #'my/zk/link-fn:interactive))
    (defalias 'my/zk/insert-link-fn:interactive* (my/uncurry-1 #'my/zk/insert-link-fn:interactive ))
    ;; functions: prefix-sym ↦ parse_fn | nil
    (defalias 'my/zk/link-parse*                 (my/wrap-resulting-function            #'my/skip-nil    #'my/zk/link-parse-fn))

    ;; functions: prefix-sym &rest args ↦ result
    ;; [`my/zk/link-parse' is treated differently for better usability (unknown link-prefix-sym)]
    (defalias 'my/zk/link                        (my/uncurry-1 #'my/zk/link-fn*))
    (defalias 'my/zk/link:core                   (my/uncurry-1 #'my/zk/link-fn:core*))
    (defalias 'my/zk/link-parse:from-prefix-parse (my/skip-nil (∘ (my/if-fn #'car
                                                                    #'apply
                                                                    (my/const nil))
                                                                  (my/fst (∘ (my/skip-nil (ap 'nth 4)) #'my/zk/link-setup #'car))
                                                                  (my/dup-fn))))
    (defalias 'my/zk/link-parse                  (my/lambda (link-string &optional link-prefix-sym)
                                                    (if link-prefix-sym
                                                        (funcall (my/zk/link-parse* link-prefix-sym) link-string)
                                                      (funcall (∘ #'my/zk/link-parse:from-prefix-parse
                                                                  (my/zk/link-parse-prefix-fn ".*?"))
                                                               link-string))))
    (defalias 'my/zk/insert-link:pure         (my/uncurry-1 #'my/zk/insert-link-fn:pure*))
    (defalias 'my/zk/insert-link              (my/uncurry-1 #'my/zk/insert-link-fn*))
    (defalias 'my/zk/insert-link:core         (my/uncurry-1 #'my/zk/insert-link-fn:core*))

    (defalias 'my/zk/link:XID-fn              (∘ #'funcall #'my/zk/link-fn:XID-fn*))
    (defalias 'my/zk/link:interactive         (∘ #'funcall #'my/zk/link-fn:interactive*))
    (defalias 'my/zk/insert-link:XID-fn       (∘ #'funcall #'my/zk/insert-link-fn:XID-fn*))
    (defalias 'my/zk/insert-link:interactive  (∘ #'funcall #'my/zk/insert-link-fn:interactive*))

    (defun my/zk/ensure-side-effect (link-parse-result)
      "Ensures that the link's (represented by LINK-PARSE-RESULT) side effects are in effect.
This function is \"idempotent\" in a way (w.r.t my/zk as a whole): Calling this function if the effects are already in effect does no harm."
      (when-let ((fn (nth 5 (my/zk/link-setup (car link-parse-result)))))
        (funcall fn (cdr link-parse-result))))
    (defun my/zk/take-core-args (link-parse-result)
      "removes non-core args from LINK-PARSE-RESULT
Also removes link-prefix-sym"
      (when-let ((fn (nth 6 (my/zk/link-setup (car link-parse-result)))))
        (funcall fn link-parse-result)))
    (defun my/zk/parse-result:file-path (link-parse-result)
      "Creates path to file from LINK-PARSE-RESULT
Also removes link-prefix-sym"
      (when-let ((fn (nth 7 (my/zk/link-setup (car link-parse-result)))))
        (funcall fn link-parse-result)))
    (defun my/zk/ensure-no-side-effect (link-parse-result)
      "Ensures that the link's (represented by LINK-PARSE-RESULT) side effects are NOT in effect.
This function is \"idempotent\" in a way (w.r.t my/zk as a whole): Calling this function if the effects are not in effect does no harm."
      (when-let ((fn (nth 8 (my/zk/link-setup (car link-parse-result)))))
        (funcall fn (cdr link-parse-result))))

    ;; specialisations for bindings

    ;; tag: my/zk/insert-LINK_SYM-link-to-XID_FN_ABBREV
    ;;      my/zk/insert-%s-link-to-%s LINK_SYM XID_FN_ABBREV
    (cl-loop for link-sym in '(note
                               store_zk ;; NOTE: special def for 'store' link
                               cite about context creator is meta_is part_of sseq log
                               date on)
             do (cl-loop
                 for xid-fn-abbrev in '(note day week today current-week active_task) ;; NOTE: no 'current-buffer'
                 do (defalias (intern (format "my/zk/insert-%S-link-to-%S" link-sym xid-fn-abbrev))
                      (my/cmd (my/zk/insert-link-fn:interactive* link-sym xid-fn-abbrev)))))

    (defalias 'my/zk/insert-store-link:interactive
      (my/cmd (my/zk/insert-link-fn:interactive* 'store 'current-buffer)))

    ;; further specialisations
    (defalias 'my/zk/insert-day-link:today            #'my/zk/insert-date-link-to-today)
    (defalias 'my/zk/insert-week-link:today           #'my/zk/insert-date-link-to-current-week)
    (defalias 'my/zk/insert-day-link:interactive      #'my/zk/insert-date-link-to-day)
    (defalias 'my/zk/insert-week-link:interactive     #'my/zk/insert-date-link-to-week)
    (defalias 'my/zk/insert-on-day-link:interactive   #'my/zk/insert-on-link-to-day)
    (defalias 'my/zk/insert-on-week-link:interactive  #'my/zk/insert-on-link-to-week)

    (my/defun my/zk/test/link-parse ()
      (mapcar (my/test-fn/via-apply #'my/zk/link-parse)
              '((("[[note:XID][nil]]")                                         . (note     "XID" "description"))
                (("[[note:XID][nil]]"                          note)           . (note     "XID" "description"))
                (("[[note:XID:with:colons][nil]]"              note)           . (note     "XID:with:colons" "description"))
                (("[[store_zk:XID〈rel-path〉][nil〈rel-path〉]]")                   . (store_zk "XID" "rel-path" "description"))
                (("[[store_zk:XID〈rel-path〉][nil〈rel-path〉]]"    store_zk)       . (store_zk "XID" "rel-path" "description"))
                (("[[store:rel-path][rel-path]]")                                      . (store          "rel-path"))
                (("[[store:rel-path][rel-path]]"                       store)          . (store          "rel-path"))
                (("[[ds:XID〈section〉][nil〈section〉]]")                           . (ds       "XID" "section" "description"))
                (("[[ds:XID〈section〉][nil〈section〉]]"            ds)             . (ds       "XID" "section" "description"))
                (("[[∈:XID〈section〉][nil〈section〉]]")                            . (∈        "XID" "section" "description"))
                (("[[∈:XID〈section〉][nil〈section〉]]"             ∈)              . (∈        "XID" "section" "description"))
                (("[[cite:XID][↗ nil]]")                                       . (cite     "XID" "description"))
                (("[[cite:XID][↗ nil]]"                        cite)           . (cite     "XID" "description"))
                (("[[about:XID][↦ nil]]")                                 . (about    "XID" "description"))
                (("[[about:XID][↦ nil]]"                  about)          . (about    "XID" "description"))
                (("[[is:XID][≼ nil]]")                                       . (is       "XID" "description"))
                (("[[is:XID][≼ nil]]"                        is)             . (is       "XID" "description"))
                ((""                                                       )           . nil)
                ((""                                                   note)           . nil)
                ((""                                                   store_zk)       . nil)
                ((""                                                   store)          . nil)
                ((""                                                   ds)             . nil)
                ((""                                                   ∈)              . nil)
                ((""                                                   cite)           . nil))))

    (progn
      ;; hardcoded notes; TODO: ⇝ config; rest lib?
      (my/defvar my/zk/XID/day_file              "2020-01-27_12.31.21.539_UTC--mirs@wrucon.org")
      ;; (defvar my/zk/XID/log_note_OLD          "2020-01-30_06.04.11.481_UTC--mirs@wrucon.org") ;; dead
      (my/defvar my/zk/XID/log_note              "2020-02-06_07.21.15.422_UTC--mirs@wrucon.org.gpg")
      (my/defvar my/zk/XID/expository            "2020-01-27_11.22.00.246_UTC--mirs@wrucon.org")
      (my/defvar my/zk/XID/my_physical_library   "2020-01-27_12.50.47.203_UTC--mirs@wrucon.org")
      (my/defvar my/zk/XID/temporary             "2020-01-27_12.29.31.310_UTC--mirs@wrucon.org")
      (my/defvar my/zk/XID/archived              "2020-03-04_14.13.15.033_UTC--mirs@wrucon.org")
      (my/defvar my/zk/XID/to_review             "2020-01-27_12.28.23.928_UTC--mirs@wrucon.org")
      (my/defvar my/zk/XID/thread                "2020-01-30_08.16.52.422_UTC--mirs@wrucon.org.gpg")
      (my/defvar my/zk/XID/time_budget           "2020-02-13_07.06.00.469_UTC--mirs@wrucon.org.gpg")
      (my/defvar my/zk/XID/MONITOR               "2020-01-26_16.55.25.017_UTC--mirs@wrucon.org.gpg")
      (my/defvar my/zk/XID/tasks_productive      "2020-03-03_14.51.07.852_UTC--mirs@wrucon.org.gpg")
      (my/defvar my/zk/XID/tasks_noon_window     "2020-03-03_11.15.58.393_UTC--mirs@wrucon.org.gpg")
      (my/defvar my/zk/XID/tasks_evening_window  "2020-03-03_11.15.50.386_UTC--mirs@wrucon.org.gpg")
      (progn
        (my/defvar my/zk/XID/calendar_note             "2020-02-05_08.30.13.029_UTC--mirs@wrucon.org.gpg")
        (my/defvar my/zk/XID/day_note              "2020-02-01_09.59.31.746_UTC--mirs@wrucon.org.gpg")
        (my/defvar my/zk/XID/week_note             "2020-02-05_08.07.47.299_UTC--mirs@wrucon.org.gpg"))
      (my/defvar my/zk/XID/my_symbol               "2020-03-11_16.15.38.471_UTC--mirs@wrucon.org"))

    ;; TODO: ?: revamp link-setup
    (defconst my/zk/link-re:any (my/zk/link-re "[^[].*?" ".*?" ".*?")
               "i.e. used in `my/zk/search-forward-link';
DO NOT CHANGE THIS VALUE ⦓many functions using `my/zk/search-forward-link' rely on the sub-expressions as defined here⦔")

    (my/defun my/zk/search-forward-link (&optional bound)
      "Searches for next `my/zk/link-re:any'  via (`search-forward-regexp' bound 'no-error) (c.f. for  BOUND).
Info can be extracted from match-data [e.g. `match-string', `match-beginning', ...] (match-data will be overwritten).
NOTE: not everything found via `my/zk/search-forward-link' is a my/zk link."
      ;; NOTE: [^[] at start of link-re to get innermost double bracket
      (search-forward-regexp my/zk/link-re:any bound 'no-error))

    ;; TODO: delete
    (defalias 'my/zk/search-forward-link-parse
      (∘ (my/skip-nil
          (∘ (° (∘ (lambda (end) (when end (list (match-beginning 0) end))))
                (∘ #'my/zk/link-parse:from-prefix-parse
                   (lambda (end)
                     (when end
                       (list (intern (match-string 1)) (match-string 2) (match-string 3))))))))
         #'my/zk/search-forward-link)
      "Returns nil OR (list start (prefix-sym &rest link-args))")

    ;; TODO: delete
    (defun my/zk/test/search-forward-link-parse ()
      (mapcar #'my/test
              (list
               (lexical-let ((link-args '(note "xid" "description")))
                 (cons (my/lambda ()
                         (with-temp-buffer
                           (save-excursion
                             (apply (∘ #'insert #'my/zk/link) link-args))
                           (my/zk/search-forward-link-parse)))
                       (list
                        (cons 1 (+ 1 (length (apply 'my/zk/link link-args))))
                        link-args))))))

    (my/defun my/zk/update-all-link-descriptions ()
      "Updates the description of all links in the current buffer.
Also see `my/zk/update-ensure-all-links'"
      (interactive)
      (when (or (not (buffer-modified-p))
                (y-or-n-p (format "current buffer (modified) might be changed and file '%s' will be overwritten. okay?" (buffer-file-name))))
        (save-excursion
          (goto-char (point-min))
          (let ((end (my/zk/search-forward-link)))
            (while end
              (when-let ((start (match-beginning 0))
                         (parse-args (list (intern (match-string 1)) (match-string 2) (match-string 3)))
                         (parse-result (my/zk/link-parse:from-prefix-parse parse-args))) 
                (cl-destructuring-bind (prefix-sym XID &rest args-rest) parse-result
                  (my/replace-region start end (funcall (my/zk/link-fn:core prefix-sym) (my/zk/take-core-args parse-result)))))
              (setq end (my/zk/search-forward-link)))))
        (my/zk/save-buffer:no-hook)))

    (my/defun my/zk/update-ensure-all-links ()
      "Updates all links in the curent buffer.
    * update descriptions (c.f. `my/zk/update-all-link-descriptions')
    * ensure side effects"
      (interactive)
      (when (or (not (buffer-modified-p))
                (y-or-n-p (format "current buffer (modified) might be changed and file '%s' will be overwritten. okay?" (buffer-file-name))))
        (save-excursion
          (goto-char (point-min))
          (let ((end (my/zk/search-forward-link)))
            (while end
              (message "link-candidate %S" (substring-no-properties (match-string 0)))
              (when-let ((start (match-beginning 0))
                         (parse-args (list (intern (match-string 1)) (substring-no-properties (match-string 2)) (substring-no-properties (match-string 3))))
                         (parse-result (my/zk/link-parse:from-prefix-parse parse-args)))
                (message "update-ensure link %S" parse-result)
                (cl-destructuring-bind (prefix-sym XID &rest args-rest) parse-result
                  (when-let* ((core-args (my/zk/take-core-args parse-result))
                              (link-fn:core (my/zk/link-fn:core prefix-sym))
                              (new-link (funcall link-fn:core core-args)))
                    (my/replace-region start end new-link)
                    (my/zk/ensure-side-effect parse-result))))
              (setq end (my/zk/search-forward-link)))))
        (my/zk/save-buffer:no-hook)))


      ;; tag: zk link
    (my/defun my/zk/collect-all-links (start limit)
      "Finds all links that lie complete in \"region\" (start . limit).
RETURN-VALUE:
  list of ENTRY
    ENTRY ≙ (list LINK-START-POINT LINK-END-POINT PARSE-ARGS PARSE-RESULT)
  list is sorted wrt LINK-START-POINT from highest to lowest (descending).
Related function: `my/collect-all-plain-links'
                  `my/zk/ace-link--collect'"
      (save-excursion
          (goto-char start)
          (let ((end (my/zk/search-forward-link limit))
                (ret-val nil))
            (while end
              (when-let ((start (match-beginning 0))
                         (parse-args (list (intern (match-string-no-properties 1))
                                           (match-string-no-properties 2)
                                           (match-string-no-properties 3)))
                         (parse-result (my/zk/link-parse:from-prefix-parse parse-args)))
                (push (list start end parse-args parse-result)
                      ret-val))
              (setq end (my/zk/search-forward-link)))
            ret-val)))


    (with-eval-after-load 'ace-link
      ;; tag: zk link ; ace-link ; plain link

      (progn
        ;; TODO: refactor: put somehwere else?
        ;; tag: ace-link ; button ; compilation
        (defun my/ace-link--button-collect ()
          "Collect the positions of buttons in the current buffer."
          (let ((button (next-button (window-start) 'count-current))
                (pos (window-start))
                button-list)
            (while button
              (let ((pos (button-start button)))
                (push (list pos button) button-list)
                (setq button (next-button pos nil))))
            (nreverse button-list)))

        ;; TODO: ace-link-button action
        )

      (my/defun my/zk/ace-link--collect ()
        "adapted from `ace-link--org-collect'
RETURN-VALUE is list of ENTRY
  ENTRY ≙ (list LINK-START-POINT TYPE-SYMBOL PATH-STRING)
    LINK-START-POINT is '(point)' of link start
    TYPE-SYMBOL is from {'file 'web}
    PATH-STRING describes the path"
        ;; TODO:BUG:?: plain-link may appear nested inside zk-link
        (let ((zk-links    (my/zk/collect-all-links (window-start) (window-end)))
              (plain-links (my/collect-all-plain-links (window-start) (window-end))))
          (nreverse (merge 'list
                           (mapcar #'(lambda (x)
                                       (list (nth 0 x)
                                             'file ;; TODO:REVISE:
                                             (car (my/zk/absolute-path:from-link-parse-result (nth 3 x)))))
                                   zk-links)
                           (mapcar #'(lambda (x)
                                       (list (car x)
                                             'web
                                             (nth 2 x)))
                                   plain-links)
                           #'(lambda (l r)
                               (>= (car l) (car r)))))))

      (defun my/zk/ace-link:path ()
        "get path specified by link.
NOTE: / TODO: also works with url / uri
              TODO: rename to ace-link:uri or sth ?
adapted from `ace-link-org' and `ace-link--org-action'
RETURN-VALUE is element of (`my/zk/ace-link--collect')"
        (when-let* ((cands (my/zk/ace-link--collect)))
          (avy-with avy-forward-item
            (avy-process
             cands
             (avy--style-fn avy-style)))))

      (defun my/zk/ace-link:open ()
        "Open a visible zk-link.
adapted from `ace-link-org' and `ace-link--org-action'"
        (interactive)
        (when-let ((path-info (my/zk/ace-link:path)))
          (cl-destructuring-bind
              (__link-start-point type-symbol path-string)
              path-info
            (cond
             ((eq type-symbol 'file)
              (find-file path-string))
             ((eq type-symbol 'web)
              (browse-url path-string))))))

      (defun my/zk/ace-link:make-frame-open ()
        "similar to `my/zk/ace-link:open' but creates a frame
before following link in same emacs frame."
        (interactive)
        (when-let ((path-info (my/zk/ace-link:path)))
          (cl-destructuring-bind
              (__link-start-point type-symbol path-string)
              path-info
            (cond
             ((eq type-symbol 'file)
              (when-let ((f (make-frame)))
                (select-frame f)
                (find-file path-string)))
             ((eq type-symbol 'web)
              (browse-url path-string))))))

      ;; TODO: config
      (my/defcustom my/zk/ace-link:external-prog
                      "openi.sh"
                      "path to program used for `my/zk/ace-link:external-prog'")

      (defun my/zk/ace-link:external-prog ()
        "Open a visible zk-link.
adapted from `ace-link-org' and `ace-link--org-action'"
        (interactive)
        (if (executable-find my/zk/ace-link:external-prog)
            (when-let ((path-info (my/zk/ace-link:path)))
              (cl-destructuring-bind
                  (__link-start-point __type-symbol path-string)
                  path-info
                (start-process (format "openi.sh %s" path-string)
                               nil
                               my/zk/ace-link:external-prog path-string)))))

      (defun my/zk/ace-link:external-prog-with-args ()
        "Open a visible zk-link.
adapted from `ace-link-org' and `ace-link--org-action'"
        (interactive)
        (if (executable-find my/zk/ace-link:external-prog)
            (when-let ((path-info (my/zk/ace-link:path)))
              (cl-destructuring-bind
                  (__link-start-point __type-symbol path-string)
                  path-info
                (start-process (format "openi.sh %s" path-string)
                               nil
                               my/zk/ace-link:external-prog path-string)))))

    (defun my/ace-link--fn (default-fn)
"create wrapper function around DEFAULT-FN"
      `(lambda ()
         (interactive)
         (cond
          ((eq major-mode 'Info-mode)
           (ace-link-info))
          ((eq major-mode 'help-mode)
           (ace-link-help))
          ((derived-mode-p 'compilation-mode)
           (ace-link-compilation))
          (t
           (,default-fn)))))

    (defalias 'my/ace-link:open
      (my/ace-link--fn 'my/zk/ace-link:open)
      "(`my/ace-link:open') = (`my/ace-link--fn' '`my/zk/ace-link:open')")

    (with-eval-after-load 'evil
      ;; evil; evil jumps; ace-link
      (advice-add 'my/ace-link:open :around  #'my/evil-jump--push-location:around))

    (defalias 'my/ace-link:make-frame-open
      (my/ace-link--fn 'my/zk/ace-link:make-frame-open)
      "(`my/ace-link:make-frame-open') = (`my/ace-link--fn' '`my/zk/ace-link:make-frame-open')")

    (defalias 'my/ace-link:external-prog
      (my/ace-link--fn 'my/zk/ace-link:external-prog)
      "(`my/ace-link:external-prog') = (`my/ace-link--fn' '`my/zk/ace-link:external-prog')"))

    (progn
      ;; tags: zk links ; font-lock
      ;; NOTE: most important functions are
      ;;         * `my/zk/propertize-all-links'
      ;;             * behaviour relies on `my/zk/link-details-visibility'
      ;;         * `my/zk/link-font-lock--fontify-region'
      ;;             * behaviour relies on `link-font-lock-enabled'

      (my/defun my/zk/propertize-all-links (&optional limit)
        "Adds the following text properties to all links.
  whole link:
    `(face      ,(my/zk/link-prefix-face LINK-PREFIX-SYM))
      ;; where LINK-PREFIX-SYM is parsed and interned from the lilnk
  everything except description:
    '(invisible zk-link-details)
NOTE: when `my/zk/link-details-visibility' is set; parts of link are made invisible
      TODO: details
NOTE: MONITOR: can be reverse via `my/zk/depropertize-all-links'
"
        ;; TODO: keep in sync with `my/zk/depropertize-all-links'
        (interactive)
        (with-silent-modifications ;; NOTE: / TODO:  we will not modify buffer contents
          (save-excursion
            (goto-char (point-min))
            (let ((end (my/zk/search-forward-link limit)))
              (while end
                (when-let ((start (match-beginning 0))
                           (desc-pos (cons (match-beginning 3) (match-end 3)))
                           (prefix-sym (intern (match-string 1))))
                  (add-text-properties start
                                       end
                                       `(font-lock-face  ,(my/zk/link-prefix-face prefix-sym)
                                         face            ,(my/zk/link-prefix-face prefix-sym)
                                         rear-nonsticky  (font-lock-face)))
                  ;; TODO: DEFERRED: perfomance; make this decision outside loop
                  (unless my/zk/link-details-visibility
                    (add-text-properties start
                                         (car desc-pos)
                                         '(invisible       t
                                           rear-nonsticky  (face font-lock-face invisible)))
                    (add-text-properties (cdr desc-pos)
                                         end
                                         '(invisible       t
                                           rear-nonsticky  (face font-lock-face invisible)))))
                (setq end (my/zk/search-forward-link)))))))

      (my/defun my/zk/depropertize-all-links (&optional limit)
        "reverses `my/zk/propertize-all-links'"
        (interactive)
        (with-silent-modifications ;; NOTE: / TODO:  we will not modify buffer contents
          (save-excursion
            (goto-char (point-min))
            (let ((end (my/zk/search-forward-link limit)))
              (while end
                (when-let ((start (match-beginning 0))
                           (desc-pos (cons (match-beginning 3) (match-end 3)))
                           (prefix-sym (intern (match-string 1))))
                  (remove-text-properties start
                                          end
                                          `(font-lock-face  ,(my/zk/link-prefix-face prefix-sym)
                                            face            ,(my/zk/link-prefix-face prefix-sym)
                                            rear-nonsticky  (font-lock-face)))
                  ;; TODO: DEFERRED: perfomance; make this decision outside loop
                  (unless my/zk/link-details-visibility
                    (remove-text-properties start
                                            (car desc-pos)
                                            '(invisible       t
                                              rear-nonsticky  (font-lock-face invisible)))
                    (remove-text-properties (cdr desc-pos)
                                            end
                                            '(invisible       t
                                              rear-nonsticky  (font-lock-face invisible)))))
                (setq end (my/zk/search-forward-link)))))))

      (progn
        (my/defun my/zk/link-details-visibility--set (bool)
"changes value of `my/zk/link-details-visibility' and calls `font-lock-flush'"
          (set-default 'my/zk/link-details-visibility bool)
          (font-lock-flush))

        (my/defun my/zk/link-details-visibility--toggle ()
          "toggles value of `my/zk/link-details-visibility' via `my/customize' (⇒ \"side effects\" are executed).
"
          (interactive)
          (my/customize 'my/zk/link-details-visibility (not my/zk/link-details-visibility)))

        (my/defcustom my/zk/link-details-visibility
                      nil
                      "nil ⇔ some part of the links are hidden via text-properties and `add-to-invisibility-spec'.
Uses wrapper around `my/zk/link-details-visibility--set' <f> to :set the value."
                      :set #'(lambda (__var-sym value)
                               (my/zk/link-details-visibility--set value))
                      :type 'boolean))

      (progn
        (defun my/zk/link-font-lock-enabled--set (bool)
          "changes value of `my/zk/link-font-lock-enabled' and
calls `font-lock-flush'
Does not change value of `my/zk/link-details-visibility'."
          (set-default 'my/zk/link-font-lock-enabled bool)
          (font-lock-flush))

        (my/defun my/zk/link-font-lock-enabled--toggle ()
          "toggles value of `my/zk/link-font-lock-enabled' via `my/customize' (⇒ \"side effects\" are executed).
See `my/zk/link-font-lock-enabled--enforce' for side effects.
"
          (interactive)
          (my/customize 'my/zk/link-font-lock-enabled (not my/zk/link-font-lock-enabled)))

        (my/defcustom my/zk/link-font-lock-enabled
                      t
                      "disabled ⇔ nil;
Used in `my/zk/link-font-lock--fontify-region'
Related value: `my/zk/link-details-visibility'.
NOTE: `my/zk/note:setup-buffer' enforces the \"consequences\" / (side effects) of this value via
      `my/zk/link-font-lock-enabled--enforce'."
                      :set #'(lambda (__var-sym value)
                               (my/zk/link-font-lock-enabled--set value))
                      :type 'boolean))

      (defun my/zk/link-font-lock--fontify-region (beg end &optional _ignored)
        "depends on `my/zk/link-font-lock-enabled'
and `my/zk/link-details-visibility' (due to `my/zk/propertize-all-links')"
        (interactive)
        (save-excursion
          (goto-char beg)
          (if my/zk/link-font-lock-enabled
              (my/zk/propertize-all-links end)
            (my/zk/depropertize-all-links end))))

      ;; tag: font-lock
      (defun my/zk/font-lock-fontify-region (beg end &optional loudly)
        (font-lock-default-fontify-region beg end loudly)
        (my/zk/link-font-lock--fontify-region beg end loudly)
        ;; TODO: color whitespace in links
        ;; TODO:PERFORMANCE:
        ;;   colored twice currently
        ;;   ⦓once via `font-lock-default-fontify-region'⦔
        (let ((font-lock-keywords whitespace-font-lock-keywords))
          (font-lock-fontify-keywords-region beg end loudly))))

    (my/defun my/zk/delete-link-at-point-remove-side-effects ()
"NOTE: assumes link is contained in a single line"
      (interactive)
      (let ((link-p nil))
        (save-excursion
          (save-match-data
            (when (or (progn
                        (skip-chars-backward "[")
                        (looking-at-p "\\[\\["))
                      (search-backward-regexp "\\[\\[" (line-beginning-position) t))
              (when-let ((end (my/zk/search-forward-link (line-end-position))))
                (when-let ((start (match-beginning 0))
                           (parse-args (list (intern (match-string 1))
                                             (substring-no-properties (match-string 2))
                                             (substring-no-properties (match-string 3))))
                           (parse-result (my/zk/link-parse:from-prefix-parse parse-args))) 
                  (setq link-p t)
                  (message "deleting '%s'" (buffer-substring-no-properties start end))
                  (my/zk/ensure-no-side-effect parse-result)
                  (delete-region start end))))))
        (unless link-p
          (user-error "no link found at point"))))

    (my/defun my/zk/delete-all-links-remove-side-effects ()
      "Removes all links in the curent buffer.
    * ensure no side effects of deleted links in effect"
      (interactive)
      (when (or (not (buffer-modified-p))
                (y-or-n-p (format "current buffer (modified) might be changed and file '%s' will be overwritten. okay?" (buffer-file-name))))
        (save-excursion
          (goto-char (point-min))
          (let ((end (my/zk/search-forward-link)))
            (while end
              (message "link-candidate %S" (substring-no-properties (match-string 0)))
              (when-let ((start (match-beginning 0))
                         (parse-args (list (intern (match-string 1))
                                           (substring-no-properties (match-string 2))
                                           (substring-no-properties (match-string 3))))
                         (parse-result (my/zk/link-parse:from-prefix-parse parse-args))) 
                (message "update-ensure-no link %S" parse-result)
                (my/zk/ensure-no-side-effect parse-result)
                (delete-region start end))
              (setq end (my/zk/search-forward-link)))))
        (my/zk/save-buffer:no-hook)))

    

    (progn
      ;; my/zk link ; font-lock

      (my/defface face/zk2/link/default
                  '((t :foreground "#00e6e6" :underline t))
                  "Default face for my/zk links")

      (my/defface face/zk2/link/store
                  '((t :foreground "#ff428f" :underline t))
                  "Default face for my/zk store links")

      (my/defface face/zk2/link/complex
                  '((t :foreground "#51a3ff" :underline t))
                  "Default face for complex my/zk links")

      (my/defface face/zk2/link/cite
                  '((t :foreground "#f2a252" :underline t))
                  "Default face for my/zk cite links")

      (my/defface face/zk2/link/meta
                  '((t :foreground "#d163ff" :underline t))
                  "Default face for my/zk meta links")

      (my/defface face/zk2/link/date
                  '((t :foreground "#d8bfd8" :underline t))
                  "Default face for my/zk date links")

      (my/defface face/zk2/link/unknown
                  '((t :foreground "#ffffff" :underline t))
                  "Default face for unknown links")

      ;; TODO:  make part of `my/zk/link-setup'
      (my/defun my/zk/link-prefix-face (prefix-sym)
        (cond
         ((eq prefix-sym 'note)
          'face/zk2/link/default)
         ((or (eq prefix-sym 'store_zk)
              (eq prefix-sym 'store))
          'face/zk2/link/store)
         ((eq prefix-sym 'cite)
          'face/zk2/link/cite)
         ((or (eq prefix-sym '∈)
              (eq prefix-sym 'about)
              (eq prefix-sym 'context)
              (eq prefix-sym 'creator)
              (eq prefix-sym 'is)
              (eq prefix-sym 'part_of)
              (eq prefix-sym 'sseq)
              (eq prefix-sym 'log))
          'face/zk2/link/complex)
         ((eq prefix-sym 'meta_is)
          'face/zk2/link/meta)
         ((or (eq prefix-sym 'date)
              (eq prefix-sym 'on))
          'face/zk2/link/date)
         ((eq prefix-sym 'ds)
          'face/zk2/link/default)
         (t
          'face/zk2/link/unknown)))

      ;; TODO:  make part of `my/zk/link-setup'
      (my/defun my/zk/absolute-path:from-link-parse-result (parse-result)
        "returns (list 
                   ABSOLUTE-PATH 
                   LINK-PREFIX-SYM
                   ADDITIONAL-INFO)
NOTE: assumes links relative to current buffer (i.e. for 'store links)"
        (cl-destructuring-bind (prefix-sym XID &rest args-rest) parse-result
          (cond
           ((eq prefix-sym 'store)
            ;; XID is not actually the XID but just path relative to store dir
            ;; ⦓link type has no XID⦔
            (list (my/zk/store:path (my/zk/buffer-XID) XID)
                  prefix-sym
                  nil))
           ((eq prefix-sym 'store_zk)
            (list (my/zk/store:path XID (car args-rest))
                  prefix-sym
                  nil))
           ((or (eq prefix-sym 'note)
                (eq prefix-sym 'cite)
                (eq prefix-sym '∈)
                (eq prefix-sym 'about)
                (eq prefix-sym 'context)
                (eq prefix-sym 'creator)
                (eq prefix-sym 'is)
                (eq prefix-sym 'part_of)
                (eq prefix-sym 'sseq)
                (eq prefix-sym 'log)
                (eq prefix-sym 'meta_is)
                (eq prefix-sym 'date)
                (eq prefix-sym 'on))
            (list (my/zk/note:path XID)
                  prefix-sym
                  nil))
           ((eq prefix-sym 'ds)
            (TODO:NOT_IMPLEMENTED_YET))
           (t
            (TODO:ILLEGAL_PREFIX-SYM)))))

      ;; (org-link-set-parameters
      ;;  "note"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/default)

      ;; (org-link-set-parameters
      ;;  "store_zk"
      ;;  :follow (my/lambda (link)
      ;;            (when-let ((split (with-temp-buffer
      ;;                                (insert link)
      ;;                                (my/zk/delimited-section:with-section-start-end
      ;;                                    "" start end
      ;;                                  (cons (buffer-substring (point-min) start)
      ;;                                        (buffer-substring (+ start 1) (- end 1)))))))
      ;;              (find-file (my/zk/store:path (car split) (cdr split)))))
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/store)

      ;; (org-link-set-parameters
      ;;  "store"
      ;;  :follow (my/lambda (link)
      ;;            (find-file (my/zk/store:path (my/zk/buffer-XID) link)))
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/store)

      ;; (org-link-set-parameters
      ;;  "ds"
      ;;  :follow (my/lambda (link)
      ;;            (when-let ((split (my/split-string-once link "〈"))
      ;;                       (XID (car split)))
      ;;              (find-file (my/zk/note:path XID)))) 
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/default)

      ;; (org-link-set-parameters
      ;;  "∈"
      ;;  :follow (my/lambda (link)
      ;;            (when-let ((split (my/split-string-once link "〈"))
      ;;                       (XID (car split)))
      ;;              (find-file (my/zk/note:path XID)))) 
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/complex)

      ;; (org-link-set-parameters
      ;;  "cite"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/cite)

      ;; (org-link-set-parameters
      ;;  "about"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/complex)

      ;; (org-link-set-parameters
      ;;  "context"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/complex)

      ;; (org-link-set-parameters
      ;;  "creator"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/complex)

      ;; (org-link-set-parameters
      ;;  "is"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/complex)

      ;; (org-link-set-parameters
      ;;  "meta_is"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/meta) 

      ;; (org-link-set-parameters
      ;;  "part_of"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/complex)

      ;; (org-link-set-parameters
      ;;  "sseq"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/complex)

      ;; (org-link-set-parameters
      ;;  "log"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/complex)

      ;; (org-link-set-parameters
      ;;  "date"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/date)

      ;; (org-link-set-parameters
      ;;  "on"
      ;;  :follow (∘ #'find-file #'my/zk/note:path)
      ;;  :complete #'TODO:currently-unimplemented
      ;;  :face 'face/zk2/link/date)
      )
  

  (my/defvar my/zk/dir:root
             (f-canonical "~/zk/")
             "All my/zk operations will be performed relative to this root directory")

  (my/defun my/zk/expand-path (rel-path)
    (f-expand rel-path my/zk/dir:root))

  (my/defvar my/zk/dir:note
             (my/zk/expand-path "note/")
             "Directory where notes (text) are be stored")

  (my/defvar my/zk/dir:store
             (my/zk/expand-path "store/")
             "Directory where files (i.e. non-text) are be stored")

  (my/defun my/zk/note:path (XID)
    (f-expand XID my/zk/dir:note))

  (my/defun my/zk/store:path (XID &optional rel-path)
    (if rel-path
        (f-join my/zk/dir:store XID rel-path)
      (concat (f-expand XID my/zk/dir:store) (f-path-separator))))

  (my/defun my/zk/parse-path (path)
    "Parse `path' into (cons DIR-SYMBOL XID)
or `nil' if `path' is not a valid path in my/zk
PRECONDITION: `path' is a valid path. (i.e. not nil)"
    ;; TODO: performance (DEFERRED: until critical)
    (when path
      (let ((path (f-canonical path)))
        (when (f-ancestor-of-p my/zk/dir:root path)
          (let* ((rel-path (f-relative path my/zk/dir:root))
                 (split (my/split-string-once rel-path (f-path-separator))))
            (let ((dir-sym (intern (car split))))
              (when (-any-p (lambda (x) (eq dir-sym x)) my/zk/subdir-syms)
                (let ((rest (cdr split)))
                  (cons dir-sym (or rest "."))))))))))

  (defalias 'my/zk/buffer-XID (∘ (my/skip-nil #'cdr)
                                 (my/skip-nil #'my/zk/parse-path)
                                 #'buffer-file-name)
    "Returns a buffer's XID (current buffer's if no arg).
Return nil if buffer-file-name is not part of my/zk")

  (my/defun my/zk/test/parse-path ()
    (mapcar (my/test-fn/via-apply #'my/zk/parse-path)
            (list
             (cons (list my/zk/dir:note) '(note . ""))
             (let ((xid "XID"))
               (cons (list (my/zk/note:path xid)) (cons 'note xid))))))

  (my/defun my/zk/simple-link-to-path (path)
    "Returns simple link to my/zk file PATH.
Returns ni if PATH is not a my/zk file"
    (when-let* ((info (my/zk/parse-path path))
                (dir-sym (car info))
                (XID (cdr info)))
      (when-let* ((link-sym (cond
                             ((eq dir-sym 'store)
                              'store_zk)
                             ((eq dir-sym 'note)
                              'note)
                             (t nil)))
                  (link-fn (my/zk/link-fn:core* link-sym)))
        (funcall link-fn XID))))

  (defalias 'my/zk/simple-link-to-buffer-file (∘ #'my/zk/simple-link-to-path #'buffer-file-name)
    "Returns simple link to to buffer `buffer' (or if nil: buffer = (`current-buffer'))")
  

  (my/defun my/zk/note:path-p (path)
    "Is `path' a path to a note?"
    (when-let ((result (my/zk/parse-path path)))
      (eq 'note (car result))))

  (my/defun my/zk/store:path-p (path)
    "Is `path' a path to a store element?"
    (when-let ((result (my/zk/parse-path path)))
      (eq 'store (car result))))

  (my/defun my/zk/INBOX:path-p (path)
    "Is `path' a path to an INBOX element?"
    (when-let ((result (my/zk/parse-path path)))
      (eq 'INBOX (car result))))

  (my/defvar my/zk/subdir-syms '(INBOX note store)
             "list of subdirs (depth = 1) of `my/zk/dir:root as symbols")

  

  (my/defun my/zk/note:list-files:string> ()
    "Return list of all files in `my/zk/dir:note' sorted via `string>' (most recent first)"
    (sort (f-files my/zk/dir:note) #'string>))

  (my/defun my/zk/note:first ()
    "Return path to note in `my/zk/dir:note' with lowest XID (lexicograpahically)."
    ;; TODO: use cache for file list
    ;;       DEFERRED: until perforamnce demands it
    (let ((candidates (f-files my/zk/dir:note)))
      (-min-by #'string> candidates)))

  (my/defun my/zk/note:last ()
    "Return path to note in `my/zk/dir:note' with highest XID (lexicograpahically)."
    ;; TODO: use cache for file list
    ;;       DEFERRED: until perforamnce demands it
    (let ((candidates (f-files my/zk/dir:note)))
      (-max-by #'string> candidates)))

  ;; (my/defvar my/zk/cache/note-descriptions:note
  ;;            ;; TODO: use (my/note:first) to bootstrap
  ;;            "/home/mirs/zk/note/2020-01-18_16.47.45.550_UTC--mirs@wrucon.org.gpg"
  ;;            "Note that serves as cache for the first line of all other notes")

  (my/defvar my/zk/cache/note-descriptions:note
             ;; TODO: use (my/note:first) to bootstrap
             (my/zk/note:path "2020-05-14_12.20.31.370_UTC--mirs@wrucon.org")
             "Note that serves as cache for the first line of all other notes
previously: '2020-01-18_16.47.45.550_UTC--mirs@wrucon.org.gpg'")

  (progn
    ;; my/zk; note creation
    (defalias 'my/zk/note:find_new:plain
      (my/cmd (∘ (° #'identity
                    (∘ #'select-window #'display-buffer))
                 #'find-file-noselect
                 #'my/zk/note:path
                 #'my/zk/note_XID:plain)))
    (defalias 'my/zk/note:find_new:encrypted
      (my/cmd (∘ (° #'identity
                    (∘ #'select-window #'display-buffer))
                 (lambda (buffer)
                   (with-current-buffer buffer
                     (my/org/gpgify-buffer)
                     ;; TODO: DEFERRED: `my/org/gpgify-buffer' zk setup somehow (probably due to `org-mode-restart')
                     (my/zk/note:setup-buffer 'no-link-updates)
                     (goto-char (point-max))
                     (set-buffer-modified-p nil))
                   buffer)
                 #'find-file-noselect
                 #'my/zk/note:path
                 #'my/zk/note_XID:encrypted))) 
    ;; TODO: DEPRRECATE day_file
    ;; (defun my/zk/note:find_new:day_file ()
    ;;   (interactive)
    ;;   (let ((ret (my/zk/note:find_new:encrypted)))
    ;;     (insert "day file ")
    ;;     (insert (format-time-string "<%Y-%m-%d %G-W%V-%u %a>" (current-time) "UTC"))
    ;;     (insert (my/newline))
    ;;     (my/zk/insert-link:core 'meta_is my/zk/XID/day_file)
    ;;     (insert (my/newline))
    ;;     (insert (my/newline))
    ;;     (set-buffer-modified-p nil)
    ;;     ret))
    (defun my/zk/note:find_new:log_note ()
      (interactive)
      (let ((ret (my/zk/note:find_new:encrypted)))
        (insert "〈log〉 ")
        (let ((time (current-time)))
          (my/zk/insert-link:core 'log (my/zk/day_XID (my/time-to-date time)))
          (insert (format-time-string " %H:%M:%S%z" time)))
        (save-excursion
          (insert (my/newline))
          (my/zk/insert-link:core 'meta_is my/zk/XID/log_note)
          (insert (my/newline))
          (insert (my/newline)))
        (set-buffer-modified-p nil)
        ret))
    (defun my/zk/note:find_new:expository ()
      (interactive)
      (let ((ret (my/zk/note:find_new:plain)))
        (insert (my/newline))
        (my/zk/insert-link:core 'is my/zk/XID/expository)
        (insert (my/newline))
        (my/zk/note:goto-beginning-of-first-content-line)
        (set-buffer-modified-p nil)
        ret))
    (defun my/zk/note:find_new:temporary ()
      (interactive)
      (let ((ret (my/zk/note:find_new:encrypted)))
        (insert "tmp: ")
        (let ((time (current-time)))
          (my/zk/insert-link:core 'log (my/zk/day_XID (my/time-to-date time)))
          (insert (format-time-string " %H:%M:%S" time)))
        (save-excursion
          (insert (my/newline))
          (my/zk/insert-link:core 'meta_is my/zk/XID/temporary)
          (insert (my/newline))
          (my/zk/insert-link:core 'meta_is my/zk/XID/to_review)
          (insert (my/newline))
          (insert (my/newline)))
        (set-buffer-modified-p nil)
        ret)))
  

  ;; ?:TODO: new_path
  ;; ?:TODO: link_find_new
  (defun my/zk/find:prev ()
    (interactive)
    (when-let ((l (sort (f-files my/zk/dir:note (lambda (path) (string< path (buffer-file-name)))) #'string>)))
               (find-file (car l))
               (revert-buffer t t)))
  (defun my/zk/find:next ()
    (interactive)
    (when-let ((l (sort (f-files my/zk/dir:note (lambda (path) (string> path (buffer-file-name)))) #'string<)))
      (find-file (car l))
      (revert-buffer t t)))

  (my/defun my/zk/note:goto-beginning-of-first-content-line ()
    "Go to first line of buffer that does not start with '#' (`?#'; (hash / number sign))"
    (interactive)
    (goto-char (point-min))
      (while (and (< (point) (point-max))
                  (= ?# (char-after)))
        (beginning-of-line 2)))

  (my/defun my/zk/note:description-section-string ()
    "Derives a _raw_ description string for the current buffer.
Lines at the beginning of the buffer starting with '#' (`?#'; (hash / number sign)) will be skipped."
    (save-excursion
      (my/zk/note:goto-beginning-of-first-content-line)
      (if (< (point) (point-max))
          (my/line-string :no-properties t)
        "")))

  (defalias 'my/zk/note:derive-description-from-string
    (∘
     (my/if-fn #'string-empty-p
       (my/const "<missing description>")
       #'identity)
     (ap #'replace-regexp-in-string "\\[" "(")
     (ap #'replace-regexp-in-string "\\]" ")")
     (ap #'replace-regexp-in-string (my/zk/link-re ".*?" ".*?" ".*?") "(\\3)")
     #'string-trim)
    "Derives a description string from an input string.
I.e. special characters and unnecessary whitespace are removed and an empty string is indicated by \"<missing description>\"")

  (defalias 'my/zk/note:derive-description:short
    (∘    (lambda (string)
            (let ((split (my/split-string-once string "//")))
              (if (cdr split) (string-trim (cdr split))
                (car split))))
          #'my/zk/note:derive-description)
    "= `my/zk/note:derive-description' and then only take part after first //")

  (defalias 'my/zk/note:derive-description
    (∘    #'my/zk/note:derive-description-from-string
          #'my/zk/note:description-section-string)
    "= (∘ `my/zk/note:derive-description-from-string' `my/zk/note:description-section-string')")

  (my/defun my/zk/note:derive-description:XID (XID)
    "Derives a description string from note belonging to XID via live buffer or by opening the file
and then calling `my/zk/note:derive-description'"
    ;; TODO: ?: performance of buffer search [DEFERRED:]
    (my/zk/with-weak-find-file-hook
      (my/in-file-buffer:ensure+read-only
          (my/zk/note:path XID)
        (lambda ()
          (my/zk/note:derive-description)))))


  (my/defun my/zk/note:after-save-hook ()
    "I.e. update caches.
PRECONDITIONS: * `buffer-file-name' is a my/zk note
               * `my/zk/cache/note-descriptions:note' is valid"
    (interactive)
    (my/zk/cache/memorise-note (my/zk/buffer-XID))
    ;; TODO: keep auto link description update permanently disabled:
    ;; (unless (f-equal-p (buffer-file-name) my/zk/cache/note-descriptions:note)
    ;;   (my/zk/update-all-link-descriptions))
    (my/zk/note:rename-buffer))

  (my/defun my/zk/save-buffer:no-hook ()
    "2 functions
1. `save-buffer' without `my/zk/note:after-save-hook'
2. do not save if file does not exist yet. [i.e. saving empty .gpg file throws error due to missing recipient line]"
    (interactive)
    (when-let ((file (buffer-file-name))
               ((f-exists? file))) 
      (let ((after-save-hook (remove 'my/zk/note:after-save-hook after-save-hook)))
        (save-buffer))))

  (my/defun my/zk/cache/forget-note (XID)
    (with-current-buffer (find-file-noselect my/zk/cache/note-descriptions:note)
      (my/zk/delimited-section:remove-note-link "note-links\n" XID)
      ;; c.f. `my/zk/note:after-save-hook'
      (my/zk/save-buffer:no-hook))
    (ht-remove! my/zk/cache/ht XID))

  (my/defun my/zk/cache/memorise-note (XID)
"
NOTE: note is not stored persistently on disk (only in my/zk/cache/ht)
      only saved via `my/zk/cache/ht:save-in-note'
      or via `my/zk/cache/add-notes-without-entry-in-cache-file'
"
    (let* ((description (my/zk/note:derive-description:XID XID))
           (link (my/zk/link 'note XID description)))
      ;; (unless (ht-get my/zk/cache/ht XID)
      ;;   (with-current-buffer (find-file-noselect my/zk/cache/note-descriptions:note)
      ;;     (my/zk/delimited-section:ensure-note-link "note-links\n" link)
      ;;     ;; save cache buffer (without this hook)
      ;;     (let ((after-save-hook (remove 'my/zk/note:after-save-hook after-save-hook)))
      ;;       (save-buffer))))
      (ht-set! my/zk/cache/ht XID description)))

  (my/defun my/zk/cache/add-notes-without-entry-in-cache-file ()
    "c.f. `my/zk/cache/memorise-note'"
    (interactive)
    (let ((cache-file my/zk/cache/note-descriptions:note))
        (message (format-time-string "my/zk/cache/add-notes-without-entry-in-cache-file %Y.%m.%d_%H:%M:%S.%3N_UTC START" nil "UTC"))
        (when-let ((notes (sort
                           (remove nil
                                   (mapcar
                                    (lambda (path)
                                      (when-let* ((x (and (f-file-p path)
                                                          (my/zk/parse-path path)))
                                                  (XID (cdr x)))
                                        XID))
                                    (f-files my/zk/dir:note)))
                           #'string>)))
          (let ((notes-with-descriptions
                 (sort  (my/zk/with-weak-find-file-hook
                         (my/in-file-buffer:ensure+read-only my/zk/cache/note-descriptions:note
                           (lambda ()
                             (mapcar (lambda (item) (cadr item))
                                     (my/zk/delimited-section:parsed-note-list "note-links\n")))))
                       #'string>)))
            (when-let ((new-notes (let ((result nil))
                                    ;; like "merge" in merge-sort
                                    ;; but delete duplicates or elements only in 'nodes-with-descriptions'
                                    (while (and notes notes-with-descriptions)
                                      (let ((new (car notes))
                                            (old (car notes-with-descriptions)))
                                        (cond
                                         ((string= new old)
                                          (pop notes)
                                          (pop notes-with-descriptions))
                                         ((string> new old)
                                          (push new result)
                                          (pop notes))
                                         (t
                                          ;; TODO: case: "obsolete note" (note in cache but no file exists anymore)
                                          ;;       gather notes
                                          (pop notes-with-descriptions)))))
                                    (while notes
                                      (push (car notes) result)
                                      (pop notes))
                                    result)))
              (message "new notes: %S" new-notes)
              (with-current-buffer (find-file-noselect cache-file)
                (when-let ((link-region (my/zk/delimited-section:find-body "note-links\n")))
                  (goto-char (cdr link-region))
                  (dolist (XID new-notes)
                    (my/zk/insert-link 'note XID (my/zk/note:derive-description:XID XID))
                    (insert (my/newline)))
                  (my/zk/save-buffer:no-hook)))))))
        (message (format-time-string "my/zk/cache/add-notes-without-entry-in-cache-file %Y.%m.%d_%H:%M:%S.%3N_UTC END" nil "UTC")))

  (my/defun my/zk/cache/update-description (XID)
    (let* ((description (my/zk/note:derive-description:XID XID))
           (link (my/zk/link 'note XID description)))
      (with-current-buffer (find-file-noselect my/zk/cache/note-descriptions:note)
          (my/zk/delimited-section:ensure-note-link "note-links\n" link)
          ;; save cache buffer (without this hook)
          (let ((after-save-hook (remove 'my/zk/note:after-save-hook after-save-hook)))
            (save-buffer)))))

  (my/defun my/zk/cache/update-description:buffer ()
    (interactive)
    (when-let ((XID (my/zk/buffer-XID)))
      (my/zk/cache/update-description XID)))

  (my/defun my/zk/cache/note-descriptions:rebuild ()
    "(Re)Create `my/zk/cache/note-descriptions:note'.
NOTE: overwrites that file
NOTE: rebuild can (usually) be avoided by always using `my/zk/cache/ht:save-in-note' to persist cached info"
    (interactive)
    ;; TODO: performance [DEFERRED: unitl critical]
    ;;    * take descriptions from cache
    (let ((cache-file my/zk/cache/note-descriptions:note))
      (when (y-or-n-p (format "zk: rebuild cache-file '%s' (might take a while)?"
                              cache-file))
        (my/replace-file
            cache-file
          (lambda ()
            (message "REBUILD")
            ;; (let ((buffer-list-update-hook (remove 'powerline-set-selected-window buffer-list-update-hook))))
            (let ((buffer-list-update-hook nil))
              (message (format-time-string "%Y.%m.%d_%H:%M:%S.%3N_UTC" nil "UTC"))
              (insert "note list / note link description cache\n\n")
              (my/zk/delimited-section:insert "note-links\n")
              (dolist (path (my/zk/note:list-files:string>))
                (when-let* ((x (and (f-file-p path)
                                    (my/zk/parse-path path)))
                            (XID (cdr x)))
                  (my/zk/insert-link 'note XID (my/zk/note:derive-description:XID XID))
                  (insert (my/newline))))
              (message (format-time-string "%Y.%m.%d_%H:%M:%S.%3N_UTC" nil "UTC")))
            (dolist (fn buffer-list-update-hook)
               (funcall fn)))))))

  ;; TODO: cache alist in some var (update on insert)
  ;;       DEFERRED: until perforamnce demands it
  (my/defun my/zk/cache/note-descriptions:alist:from-note ()
    "Create alist from `my/zk/cache/note-descriptions:note'.
PRECONDITIONS: * file exists
               * delimited section in file exists
               * note list has at least 1 item [cache file itself] 
ENTRIES: (DESCRIPTION . XID)"
    (interactive)
    ;; TODO: performance [DEFERRED: until necessary]
    (my/zk/with-weak-find-file-hook
      (my/in-file-buffer:ensure+read-only my/zk/cache/note-descriptions:note
        (lambda ()
          (mapcar (lambda (item) (cons (caddr item) (cadr item)))
                  (my/zk/delimited-section:parsed-note-list "note-links\n"))))))

    (my/defun my/zk/cache/note-descriptions:pairs:from-note ()
      "Create list from `my/zk/cache/note-descriptions:note'.
PRECONDITIONS: * file exists
               * delimited section in file exists
               * note list has at least 1 item [cache file itself] 
PAIRS (XID DESCRIPTION)"
      (interactive)
      ;; TODO: performance [DEFERRED: until necessary]
      (my/zk/with-weak-find-file-hook
        (my/in-file-buffer:ensure+read-only my/zk/cache/note-descriptions:note
          (lambda ()
            (mapcar (lambda (item) (list (cadr item) (caddr item)))
                    (my/zk/delimited-section:parsed-note-list "note-links\n"))))))

  (progn
    ;; hash table cache

    (my/defvar my/zk/cache/ht nil
               "c.f. my/zk/cache/ht:build-from-note")

    (my/defun my/zk/cache/ht:build-from-note ()
      "Build `my/zk/cache/ht' from `my/zk/cache/note-descriptions:note'"
      (interactive)
      (setq my/zk/cache/ht (eval `(ht ,@(my/zk/cache/note-descriptions:pairs:from-note)))))

    (my/defun my/zk/cache/ht:save-in-note ()
      "Save `my/zk/cache/ht' in `my/zk/cache/note-descriptions:note'
NOTE: useful as 1 of 'kill-emacs-query-functions'.
also see `my/zk/cache/note-descriptions:rebuild'"
      (interactive)
      (let ((cache-file my/zk/cache/note-descriptions:note))
        (when (y-or-n-p (format "zk: save cache/ht in cache-file '%s' (might take a while)?"
                                cache-file))
          (my/replace-file
              cache-file
            (lambda ()
              (insert "# -*- coding: utf-8 -*-\n") ;; WORKAROUND: else delimiters for delimited section parsed correctly on startup
              (insert "note list / note link description cache\n\n")
              (my/zk/delimited-section:insert "note-links\n")
              (ht-each (lambda (XID description)
                         (my/zk/insert-link 'note XID description)
                         (insert (my/newline)))
                       my/zk/cache/ht))))))

    ;; TODO:NEXT:(ht to note)

    (my/defun my/zk/cache/note-description (XID)
      "Get description of XID via `my/zk/cache/ht'"
      (ht-get my/zk/cache/ht XID)))


  ;; TODO: cache alist in some var (update on insert)
  ;;       DEFERRED: until perforamnce demands it
  (my/defun my/zk/cache/note-descriptions:alist ()
    "Create alist from `my/zk/cache/ht'.
ENTRIES: (DESCRIPTION . XID)"
    (interactive)
    (sort
     (mapcar (lambda (item) (cons (cdr item) (car item)))
             (ht->alist my/zk/cache/ht))
     (lambda (item1 item2)
       (let ((xid1 (cdr item1))
             (xid2 (cdr item2)))
         (let ;; TODO: better detection of "special" notes
             ((item1special (< (length xid1) 32))
              (item2special (< (length xid1) 32)))
           (cond
            ((or (and item1special item2special)
                 (not (or item1special item2special)))
             (string> xid1 xid2))
            (item1special
             nil)
            (item2special
             t)))))))

  (progn
    ;; delimited sections
    ;;  * boundaries
    ;;    * opening delimiter 〈; closing delimiter 〉
    ;;    * parses until balanced with opening delimter
    ;;  * fiels separator = newline

    (my/defun my/zk/delimited-section:insert (name)
      "insert delimited-section at point"
      (interactive "M")
      (insert "〈")
      (insert name)
      (save-excursion
        (insert "〉")))

    (my/defun my/zk/delimited-section:find (name)
      "Finds delimited section beginning with string name
if not found: Return 'nil'
else: Return (section-start section-end name-start name-end body-start body-end) "
      (save-match-data
        (save-excursion
          (goto-char (point-min))
          (let ((OD (string-to-char "〈")) ;; had some problems with font-lock when using ?〈 directly
                (CD (string-to-char "〉")))
            (when-let* ((name-end (search-forward-regexp (format "%c%s" OD name) nil t))
                        (section-start (match-beginning 0))
                        (name-start (+ 1 section-start))
                        (body-start name-end))
              (when (< (point) (point-max))
                (when-let* ((body-end
                             (cl-do* ((c (char-after)
                                         (char-after))
                                      (level (cond
                                              ((= c OD) 2)
                                              ((= c CD) 0)
                                              (t 1))
                                             (cond
                                              ((= c OD) (1+ level))
                                              ((= c CD) (1- level))
                                              (t level))))
                                 ((or (= 0 level)
                                      (progn (forward-char) (>= (point) (point-max))))
                                  (when (= 0 level)
                                    (point)))))
                            (section-end (+ body-end 1)))
                  (list section-start section-end name-start name-end body-start body-end))))))))

    (my/defun my/zk/test/delimited-section:find ()
      (mapcar #'my/test
              '(((lambda ()
                   (with-temp-buffer
                     (insert "〈〉")
                     (my/zk/delimited-section:find "")))
                 . (1 3 2 2 2 2))
                ((lambda ()
                   (with-temp-buffer
                     (insert "〈note-links
[[note:2020-01-19_09.33.19.543_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-19_09.26.13.971_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-18_16.47.45.550_UTC--mirs@wrucon.org][nil]]
〉")
                     (my/zk/delimited-section:find "note-links\n")))
                 . (1 251 2 13 13 250)))))


    (my/defun my/zk/delimited-section:find+ (name)
      "Returns wrapper functionc around result of `my/zk/delimited-section:find'.
if not found: Return 'nil'
else: Return function ∀ SYM ∈ {section-start section-send name-start name-end body-start body-end}: SYM ↦ position"
      (lexical-let* ((result (my/zk/delimited-section:find name))
                     (ss (nth 0 result))
                     (se (nth 1 result))
                     (ns (nth 2 result))
                     (ne (nth 3 result))
                     (bs (nth 4 result))
                     (be (nth 5 result)))
        `(lambda (sym)
           (cond
            ((eq sym 'section-start) ,ss)
            ((eq sym 'section-end)   ,se)
            ((eq sym 'name-start)    ,ns)
            ((eq sym 'name-end)      ,ne)
            ((eq sym 'body-start)    ,bs)
            ((eq sym 'body-end)      ,be)
            (t (error "my/zk/delimited-section:find+: invalid arg %S (must be ∈ {section-start section-send name-start name-end body-start body-end})" sym))))))

    (my/defun my/zk/delimited-section:find-body (name)
      "Finds via `my/zk/delimited-section:find'.
if not found: Return 'nil'
else: Return (cons body-start body-end) "
      (when-let ((result (my/zk/delimited-section:find name))
                 (start (nth 4 result))
                 (end (nth 5 result)))
        (cons start end))) 

    (defmacro my/zk/delimited-section:with-section-start-end (name start-sym end-sym &rest forms)
      "Introduces bindings START-SYM and END-SYM (refering to start and end of section NAME) into FORMS.
FORMS are only executed if delimited section `name' is found is found"
      (declare (indent 3))
      (lexical-let ((result-sym (gensym)))
        `(when-let ((,result-sym (my/zk/delimited-section:find ,name))
                    (,start-sym  (car ,result-sym))
                    (,end-sym    (cadr ,result-sym)))
           ,@forms)))

    (defmacro my/zk/delimited-section:with-body-start-end (name start-sym end-sym &rest forms)
      "Introduces bindings START-SYM and END-SYM (refering to (`my/zk/delimited-section:find-body' NAME)) into FORMS.
FORMS are only executed if delimited section `name' is found is found"
      (declare (indent 3))
      (lexical-let ((region-sym (gensym)))
        `(when-let ((,region-sym (my/zk/delimited-section:find-body ,name))
                    (,start-sym  (car ,region-sym))
                    (,end-sym    (cdr ,region-sym)))
           ,@forms)))

    (my/defun my/zk/delimited-section:body-string (name)
      "Finds via `my/zk/delimited-section:find'.
if not found: Return 'nil'
else: Return body as string (with text properties)"
      (my/zk/delimited-section:with-body-start-end name start end
        (buffer-substring start end)))

    (my/defun my/zk/delimited-section:string (name)
      "Finds via `my/zk/delimited-section:find'.
if not found: Return 'nil'
else: Return section as string (with text properties)"
      (my/zk/delimited-section:with-section-start-end name start end
        (buffer-substring start end)))

    (my/defun my/zk/delimited-section:listify-region (start end separator)
      "Finds via `my/zk/delimited-section:find'.
if not found: Return 'nil'
else: Return list of items (seperated by SEPARATOR) in region [(incl) START, (excl) END]
      [NOTE: if the region is empty '(\"\") will be returned]"
      (let ((bs (buffer-substring-no-properties start end)))
        (split-string bs separator)))

    (my/defun my/zk/delimited-section:list (name separator)
      "Finds via `my/zk/delimited-section:find'.
if not found: Return 'nil'
else: Return list of items in delimited section "
      (my/zk/delimited-section:with-body-start-end name start end
        (my/zk/delimited-section:listify-region start end separator)))

    (my/defun my/zk/test/delimited-section:list ()
      "Tests `my/zk/test/delimited-section:list'."
      (mapcar #'my/test
              '(((lambda ()
                   (with-temp-buffer
                     (insert "〈〉")
                     (my/zk/delimited-section:list "" "\n")))
                 . (""))
                ((lambda ()
                   (with-temp-buffer
                     (insert "〈note-links
[[note:2020-01-19_09.33.19.543_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-19_09.26.13.971_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-18_16.47.45.550_UTC--mirs@wrucon.org][nil]]
〉")
                     (my/zk/delimited-section:list "note-links\n" "\n")))
                 . ("[[note:2020-01-19_09.33.19.543_UTC--mirs@wrucon.org][nil]]"
                    "[[note:2020-01-19_09.26.13.971_UTC--mirs@wrucon.org][nil]]"
                    "[[note:2020-01-18_16.47.45.550_UTC--mirs@wrucon.org][nil]]"
                    ""))))) 

    (my/defun my/zk/parse-list-of-note-link-strings (list)
      "Parse items in LIST via `my/zk/link-parse'.
Omit entries that cannot be successfully parsed."
      (cl-do* ((items list (cdr items))
               (x (my/zk/link-parse (car items) 'note)
                  (my/zk/link-parse (car items) 'note))
               (result (when x (list x)) (if x (cons x result) result)))
          ((null (cdr items))
           (reverse result))))


    (my/defun my/zk/delimited-section:parsed-note-list (name)
      "Finds via `my/zk/delimited-section:find'.
if not found: Return 'nil'
else: Return list of items in delimited section "
      (my/zk/parse-list-of-note-link-strings
       (my/zk/delimited-section:list name (my/newline))))

    (my/defun my/zk/test/delimited-section:parsed-note-list ()
      "Tests `my/zk/test/delimited-section:parsed-note-list'."
      (mapcar #'my/test
              '(((lambda ()
                   (with-temp-buffer
                     (insert "〈note-links
[[note:2020-01-19_09.33.19.543_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-19_09.26.13.971_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-18_16.47.45.550_UTC--mirs@wrucon.org][nil]]
〉")
                     (my/zk/delimited-section:parsed-note-list "note-links\n")))
                 . ((note "2020-01-19_09.33.19.543_UTC--mirs@wrucon.org" "test note 2.0")
                    (note "2020-01-19_09.26.13.971_UTC--mirs@wrucon.org" "test // test note")
                    (note "2020-01-18_16.47.45.550_UTC--mirs@wrucon.org" "note list / note link description cache"))))))

    (my/defun my/zk/delimited-section:modify-region-as-list (start end separator modifying-fn)
      (declare (indent 3))
      (save-excursion
        (let* ((new-list (funcall modifying-fn (my/zk/delimited-section:listify-region start end separator))))
          (my/replace-region start end (string-join new-list separator)))))

    (my/defun my/zk/delimited-section:modify-body-as-list (name separator modifying-fn)
      "Finds via `my/zk/delimited-section:find'.
if not found: Return 'nil'
else:  "
      (declare (indent 2))
      (my/zk/delimited-section:with-body-start-end name start end
        (my/zk/delimited-section:modify-region-as-list start end separator modifying-fn)))

    (my/defun my/zk/test/delimited-section:modify-body-as-list ()
      "Tests `my/zk/test/delimited-section:modify-body-as-list'."
      (mapcar #'my/test
              (list (lexical-let ((ds-name "note-links\n")
                                  (ds-string "〈note-links
[[note:2020-01-19_09.33.19.543_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-19_09.26.13.971_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-18_16.47.45.550_UTC--mirs@wrucon.org][nil]]
〉"))
                      (cons
                       (lambda ()
                         (with-temp-buffer
                           (insert ds-string)
                           (my/zk/delimited-section:modify-body-as-list
                               ds-name (my/newline)
                             'identity)
                           (my/zk/delimited-section:string ds-name)))
                       ds-string)))))

    (my/defun my/zk/delimited-section:sort-list (name separator compare-fn)
      "COMPARE-FN: item1, item2 ↦ (position(item1) < position(item2)) [c.f. predicate arg in `sort']
NOTE: on interactive input: use C-q C-j to insert new line (C-q = quoted-insert)"
      (declare (indent 2))
      (my/zk/delimited-section:modify-body-as-list name separator
        (lambda (list)
          (sort list compare-fn))))

    (my/defun my/zk/delimited-section:sort-note-link-list (name compare-fn)
      "COMPARE-FN: arg1[link-parse-result], arg2[link-parse-result] ↦ (position(arg1) < position(arg2)) [c.f. predicate arg in `sort']
NOTE: on interactive input: use C-q C-j to insert new line (C-q = quoted-insert)"
      (declare (indent 1))
      (when-let ((parse-fn (my/zk/link-parse-fn 'note)))
        (my/zk/delimited-section:modify-body-as-list name (my/newline)
          (lambda (list)
            (sort list (lambda (l1 l2)
                         (funcall compare-fn (funcall parse-fn l1) (funcall parse-fn l2))))))))

    (my/defun my/zk/delimited-section:sort-note-link-list:XID:string> (name)
      " NOTE: on interactive input: use C-q C-j to insert new line (C-q = quoted-insert)"
      (interactive "M")
      (my/zk/delimited-section:sort-note-link-list name
        (lambda (pr1 pr2)
          (string> (cadr pr1) (cadr pr2)))))

    (my/defun my/zk/delimited-section:sort-note-link-list:XID:string< (name)
      " NOTE: on interactive input: use C-q C-j to insert new line (C-q = quoted-insert)"
      (interactive "M")
      (my/zk/delimited-section:sort-note-link-list name
        (lambda (pr1 pr2)
          (string< (cadr pr1) (cadr pr2)))))

    (my/defun my/zk/delimited-section:sort-note-link-list:description:my/string>-i (name)
      " NOTE: on interactive input: use C-q C-j to insert new line (C-q = quoted-insert)"
      (interactive "M")
      (my/zk/delimited-section:sort-note-link-list name
        (lambda (pr1 pr2)
          (my/string>-i (caddr pr1) (caddr pr2)))))

    (my/defun my/zk/delimited-section:sort-note-link-list:description:my/string<-i (name)
      " NOTE: on interactive input: use C-q C-j to insert new line (C-q = quoted-insert)"
      (interactive "M")
      (my/zk/delimited-section:sort-note-link-list name
        (lambda (pr1 pr2)
          (my/string<-i (caddr pr1) (caddr pr2)))))

    (cl-loop for (pos-sym comp-sym) in '((description my/string<-i) (description my/string>-i) (XID string<) (XID string>))
             do (defalias (intern (format "my/zk/delimited-section:sort-note-link-list:%s:%s:interactive" pos-sym comp-sym))
                  `(lambda ()
                     (interactive)
                     (save-match-data
                       (save-excursion
                         (let ((OD (string-to-char "〈")) ;; had some problems with font-lock when using ?〈 directly
                               (CD (string-to-char "〉"))
                               (ds-name nil))
                           ;;   we are in a delimited section
                           ;; ⇔ we are between a matching OD, CD pair
                           ;; ⇔ ∃ OD,CD region including (point and only matching OD,CD pairs)
                           ;; ⇒ there must be an unmatched OD pair in front of point
                           (when (> (point) (point-min))
                             (when-let* ((name-start
                                          (cl-do* ((c (char-before) (char-before))
                                                   (level (cond
                                                           ((= c OD) 0)
                                                           ((= c CD) 2)
                                                           (t 1))
                                                          (cond
                                                           ((= c OD) (1- level))
                                                           ((= c CD) (1+ level))
                                                           (t level))))
                                              ((or (= 0 level)
                                                   (progn (backward-char) (<= (point) (point-min))))
                                               (when (= 0 level)
                                                 (point)))))
                                         (name-end (search-forward-regexp (my/newline) nil t)))
                               ;; NOTE: it is still possible that we are not in a delimited section (if the OD we found is never closed)
                               ;;       TODO: also error message in that case
                               (setq ds-name (buffer-substring-no-properties name-start name-end))
                               (message "trying to sort candidate ds '%s' via (%s,%s)" ds-name ',pos-sym ',comp-sym)))
                           (if ds-name
                               (funcall ',(intern (format "my/zk/delimited-section:sort-note-link-list:%s:%s" pos-sym comp-sym))
                                        ds-name)
                             (message "not in a delimited section"))))))))

    (my/defun my/zk/delimited-section:ensure-note-link (name note-link)
      "Counterpart to `my/zk/delimited-section:remove-note-link'.
WHEN  NOTE-LINK is invalid note link abort;
IF    ∃ delimited section NAME?
      IF    NOTE-LINK ∈ delimited section NAME
      THEN  update link description
      ELSE  add link (NOTE: / TODO: currently just somewhere)
ELSE  create it with this single link
"
      ;; TODO: DEFERRED: performance
      ;;     * ?: use array
      ;;     * ensure list stays sorted
      ;;       * ?: ⇒ binary search [need array]
      ;;       * stop search if date becomes too low / high
      (save-excursion
        (when-let ((l (my/zk/link-parse note-link)))
          (unless
              (my/zk/delimited-section:with-body-start-end name start end
                (my/zk/delimited-section:modify-region-as-list
                    start end (my/newline)
                  (lexical-let ((l l)
                                (note-link note-link))
                    (lambda (list)
                      (let* ((links (my/zk/parse-list-of-note-link-strings list))
                             (hit (-find-index (lexical-let ((xid (cadr l)))
                                                 (lambda (x) (string= (cadr x) xid)))
                                               links)))
                        (if hit
                            (-replace-at hit note-link list)
                          (cons note-link list))))))
                t)
            (goto-char (point-max))
            (insert (my/newline))
            (my/zk/delimited-section:insert name)
            (insert note-link)))))

    (my/defun my/zk/test/delimited-section:ensure-note-link ()
      "Tests `my/zk/test/delimited-section:ensure-note-link'."
      (mapcar #'my/test
              (list
               (lexical-let ((link (my/zk/link 'note "XID" "DESC")))
                 (cons (lambda ()
                         (with-temp-buffer
                           (my/zk/delimited-section:ensure-note-link "test\n" link)
                           (buffer-substring-no-properties (point-min) (point-max))))
                       "\n〈test
[[note:XID][nil]]〉"))
               (lexical-let ((ds-name "note-links\n")
                             (ds-string "〈note-links
[[note:2020-01-19_09.33.19.543_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-19_09.26.13.971_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-18_16.47.45.550_UTC--mirs@wrucon.org][nil]]
〉")
                             (link (my/zk/link 'note "XID" "DESC")))
                 (cons
                  (lambda ()
                    (with-temp-buffer
                      (insert ds-string)
                      (my/zk/delimited-section:ensure-note-link ds-name link)
                      (my/zk/delimited-section:string ds-name)))
                  "〈note-links
[[note:XID][nil]]
[[note:2020-01-19_09.33.19.543_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-19_09.26.13.971_UTC--mirs@wrucon.org][nil]]
[[note:2020-01-18_16.47.45.550_UTC--mirs@wrucon.org][nil]]
〉")))))

    (my/defun my/zk/delimited-section:remove-note-link (name xid)
      "Counterpart to `my/zk/delimited-section:ensure-note-link'.
WHEN  delimited section NAME exists:
THEN  remove all links with xid XID from ds NAME"
      ;; TODO: DEFERRED: performance; c.f. `my/zk/delimited-section:ensure-note-link'
      (save-excursion
        (my/zk/delimited-section:with-body-start-end name start end
          (my/zk/delimited-section:modify-region-as-list
              start end (my/newline)
            (lambda (list)
              (let* ((links (my/zk/parse-list-of-note-link-strings list))
                     (hits (-find-indices (lambda (x) (string= (cadr x) xid))
                                          links)))
                (if hits
                    (-remove-at-indices hits list)
                  list))))))))

  (my/defun my/zk/note:rename-buffer ()
    "Renames the buffer
PRECONDITION: `buffer-file-name' is a my/zk note"
    (interactive)
    (rename-buffer (format "zk: %s" (my/zk/note:derive-description)) 'unique))


  (my/defun my/zk/note:setup-buffer (&optional no-link-descriptions-update)
    "Sets up buffer.
PRECONDITION: `buffer-file-name' is a my/zk note"
    (interactive)
    (my/zk/note:rename-buffer)
    (unless (or no-link-descriptions-update
                (f-equal-p (buffer-file-name) my/zk/cache/note-descriptions:note)
                (not (f-exists? (buffer-file-name))))
      (my/zk/update-all-link-descriptions))
    ;; tag: font-lock
      ;; TODO: what to do when `font-lock-fontify-region-function' changed previously or after this
      (when (eq font-lock-fontify-region-function
                'font-lock-default-fontify-region)
        (setq font-lock-fontify-region-function
              'my/zk/font-lock-fontify-region)
        ;; TODO: to refontify properly after changes
        ;;       NOTE: / TODO:  not really needed as long as org-mode is used
        (setq-local font-lock-extend-after-change-region-function
                    'org-fontify-extend-region))
      (font-lock-flush)
      ;; (funcall font-lock-fontify-region-function (point-min) (point-max))
    ;; TODO: problem: saving a file is not atomic (since we modify multiple files)
    (add-hook 'after-save-hook 'my/zk/note:after-save-hook nil t))

  (my/defun my/zk/note:setup-buffer-cancel ()
    "Sets up buffer.
PRECONDITION: `buffer-file-name' is a my/zk note (`my/zk/note:path-p')"
    (interactive)
    ;; tag: font-lock
      ;; TODO: see `my/zk:setup-buffer'
      (when (eq font-lock-fontify-region-function
                'my/zk/font-lock-fontify-region)
        (setq font-lock-fontify-region-function
              'font-lock-default-fontify-region))
      (font-lock-flush)
    (remove-hook 'after-save-hook 'my/zk/note:after-save-hook t)
    (rename-buffer (f-filename (buffer-file-name)) 'unique))

  (my/defvar my/zk/note:find-file-hook:no-link-descriptions-update nil
             "c.f. code of `my/zk/note:find-file-hook' and `my/zk/with-weak-find-file-hook'")

  (my/defun my/zk/note:find-file-hook ()
    (when (my/zk/note:path-p (buffer-file-name))
      (my/zk/note:setup-buffer my/zk/note:find-file-hook:no-link-descriptions-update)))

  (my/defun my/zk/note:find-file-hook:enable ()
    (add-hook 'find-file-hook #'my/zk/note:find-file-hook t))

  (my/defun my/zk/note:find-file-hook:disable ()
    (remove-hook 'find-file-hook #'my/zk/note:find-file-hook))

  (my/zk/note:find-file-hook:enable)

  (defmacro my/zk/with-weak-find-file-hook (&rest forms)
"Execute FORMS with the side effect that `my/zk/note:find-file-hook' does not fully execute (i.e. to save time for not shown buffers)"
    (declare (indent 0))
    `(let ((my/zk/note:find-file-hook:no-link-descriptions-update t))
       ,@forms))

  (my/defun my/zk/select_interactively_from_description-XID-alist (alist)
    "ALIST is list of (description . XID)
Returns element (XID . description)"
    (lexical-let ((result nil))
      (ivy-read "" alist
                :require-match t
                :action (lambda (ret) (setq result (cons (cdr ret) (car ret)))))
      result))

  (defalias 'my/zk/cache/select-XID
    (∘ #'car #'my/zk/select_interactively_from_description-XID-alist #'my/zk/cache/note-descriptions:alist)
    "Select XID from (`my/zk/cache/note-descriptions:alist')")


  (progn
    ;; zk: cache, XID, filtered
    (my/defvar my/zk/select-XID:default-filter-fn
               (ap #'-remove
                   (lambda (x)
                     (cl-destructuring-bind (description &rest XID) x
                       (string-prefix-p "〈log〉" description))))
               "default value for `my/zk/select-XID:filter-fn'")

    (my/defvar my/zk/select-XID:filter-fn
               my/zk/select-XID:default-filter-fn)


    (defun my/zk/cache/select-XID:define (filter-fn)
      "create `my/zk/cache/select-XID:filtered' with FILTER-FN used to filter candidates"
      (defalias 'my/zk/cache/select-XID:filtered
        (∘ #'car #'my/zk/select_interactively_from_description-XID-alist
                 filter-fn
                 #'my/zk/cache/note-descriptions:alist)
        "Select XID from filtered version of (`my/zk/cache/note-descriptions:alist')"))

    (defun my/zk/cache/select-XID:define-filtered-as-filtered ()
      (interactive)
      (my/zk/cache/select-XID:define my/zk/select-XID:filter-fn))
    (my/help/useful-unbound-function:declare 'my/zk/cache/select-XID:define-filtered-as-filtered)

    (defun my/zk/cache/select-XID:define-filtered-as-unfiltered ()
      (interactive)
      (my/zk/cache/select-XID:define #'identity))
    (my/help/useful-unbound-function:declare 'my/zk/cache/select-XID:define-filtered-as-unfiltered)

    (my/zk/cache/select-XID:define-filtered-as-filtered))


  (defalias 'my/zk/note:find_filtered
    (my/cmd (∘ (my/skip-nil (∘ #'find-file
                              #'my/zk/note:path))
               #'my/zk/cache/select-XID:filtered))
    "Find note file via `my/zk/cache/select-XID:filtered'")

  (defalias 'my/zk/note:find
    (my/cmd (∘ (my/skip-nil (∘ #'find-file
                              #'my/zk/note:path))
               #'my/zk/cache/select-XID))
    "Find note file via `my/zk/cache/select-XID'")


  (my/defun my/zk/store:read-path (XID)
    "Find path to file in local store (this files store)"
    (when-let* ((XID-store (my/dir:ensure (my/zk/store:path XID))))
      (read-file-name "" XID-store)))

  (defalias 'my/zk/store:find (my/cmd (∘ #'find-file #'my/zk/store:read-path #'my/zk/cache/select-XID:filtered))
    "Find file via `my/zk/store:read-path'")

  (defalias 'my/zk/store:find:current-buffer (my/cmd (∘ (my/skip-nil #'find-file) (my/skip-nil #'my/zk/store:read-path) #'my/zk/buffer-XID))
    "Find XID via `my/zk/buffer-XID'. Then ind file via`my/zk/store:read-path'")

  (my/defun my/zk/store_zk:read-path ()
    "Return path via `read-file-name' in (my/zk/store:path \".\")"
    (interactive)
    (read-file-name "" (my/zk/store:path ".")))

  (defalias 'my/zk/store_zk:find (my/cmd (∘ #'find-file #'my/zk/store_zk:read-path))
    "Find file via `my/zk/store_zk:read-path'")

  (my/defun my/zk/bootstrapped-p ()
    "Currently just checks existence of the dirs and `my/zk/cache/note-descriptions:note'.
TODO: flesh out."
    (cl-flet ((dir-p (lambda (path)
                       (and path (f-dir? path))))
              (file-p (lambda (path)
                        (and path (f-file? path)))))
      (and (-all-p #'file-p (list my/zk/cache/note-descriptions:note))
           (-all-p #'dir-p  (list my/zk/dir:root my/zk/dir:note my/zk/dir:store)))))


  (progn
    ;; my/zk delete note

    (my/defun my/zk/delete-note (&optional XID)
      "DWIM version of `my/zk/delete-note-1'."
      (interactive)
      (let ((XID (or XID (my/zk/buffer-XID))))
        (my/zk/delete-note-1 XID)))

    (my/defun my/zk/delete-note-1 (XID)
      "Purpose: Delete
                       file,
                       buffer
                       store-dir (when exists) belonging to XID.
                       cached stuff
Case: sth. exists at store-dir that is not an empty-directory
      ⇝ an error is thrown and nothing else is done.
NOTE:/TODO: does not check incoming links from other files"
      (let* ((store-dir (my/zk/store:path XID))
             (has-empty-store-dir
              (and (f-directory-p store-dir)
                   (f-empty-p store-dir))))
        (if (or (not (f-exists-p store-dir))
                has-empty-store-dir)
            (progn
              (my/zk/cache/forget-note XID)
              (my/zk/delete-all-links-remove-side-effects)
              (when-let ((path (my/zk/note:path XID)))
                (when-let ((live-buffer (find-buffer-visiting path)))
                  (kill-buffer live-buffer))
                (delete-file path))
              (when has-empty-store-dir
                (f-delete store-dir)))
          (error "will not delete '%s': store-dir is not empty" XID))))

    (my/defun my/zk/delete-note:prompt (&optional XID)
      "version of `my/zk/delete-note' which prompts via `y-or-n-p'."
      (interactive)
      (when (y-or-n-p (format "delete note '%s' [XID='%s']?"
                              (if  XID (my/zk/note:derive-description:XID XID) (my/zk/note:derive-description))
                              XID))
        (my/zk/delete-note XID)))

    (defalias 'my/zk/delete-note:find-interactive
      (my/cmd (∘ #'my/zk/delete-note-1 #'my/zk/cache/select-XID:filtered))
      "(∘ #'`my/zk/delete-note' #'`my/zk/cache/select-XID:filtered')")

    (defalias 'my/zk/delete-note:find-interactive:prompt
      (my/cmd (∘ #'my/zk/delete-note:prompt #'my/zk/cache/select-XID:filtered))
      "(∘ #'`my/zk/delete-note:prompt' #'`my/zk/cache/select-XID:filtered')"))

  (my/defun my/zk/load-buffers ()
    "All note buffers will be loaded.
I.e speeds up / enables `my/zk/occur-all'."
    (interactive)
    (message "my/zk/load-buffers")
    (let* ((file-list (my/zk/note:list-files:string>)))
      ;; TEST: ⦗currently links not updated on initial load ⇝ save time / most buffers not looked at anyway⦘
      (my/zk/with-weak-find-file-hook
        (mapcar #'find-file-noselect file-list))))
  (my/help/useful-unbound-function:declare 'my/zk/load-buffers)

  (my/defun my/zk/init ()
    "use to bootstrap
* cache
* delimited sections in files
NOTE: only really needed to bootstrap from existing files
      without complex links (i.e. no 'citations' list due to 'cite' links)
      or recover from data loss
NOTE: takes a couple of minutes to execute"
    (interactive)
    ;; TODO: performace: only touch each buffer once
    ;;       TODO: implement transducers
    (when (yes-or-no-p "really want to init zk? (may take a long while)")
      (message "my/zk/init")
      (display-buffer (messages-buffer))
      (let ((debug-on-error t))
        (let ((buffers (my/zk/load-buffers))
              (cache-file my/zk/cache/note-descriptions:note))
          ;; NOTE: buffer-list is sorted (more recently created files first)
          (message "rebuild cache in '%s'" cache-file)
          (my/replace-file cache-file
            (lambda ()
              (insert "note list / note link description cache\n\n")
              (my/zk/delimited-section:insert "note-links\n")
              (my/zk/delimited-section:modify-body-as-list "note-links\n" (my/newline)
                (my/const (mapcar #'my/zk/simple-link-to-buffer-file
                                  buffers)))))
          (mapc (lambda (buffer)
                  (with-current-buffer buffer
                    (message "update-ensure: '%s' [%s]" (buffer-name) (buffer-file-name))
                    (my/zk/update-ensure-all-links)))
                (reverse
                 (let ((cache-buffer (find-buffer-visiting cache-file)))
                   (if cache-buffer
                       (-remove-item cache-buffer buffers)
                     buffers))))))))

  (progn
    ;my/zk search via occur
    (my/defun my/zk/occur-all (regexp)
      (interactive "Mregexp: ")
      (let ((buffers (my/zk/load-buffers)))
        (multi-occur buffers regexp)))

    (my/defun my/zk/occur-all:buffer-XID ()
      (interactive)
      (let ((buffers (my/zk/load-buffers)))
        (multi-occur buffers (my/zk/buffer-XID)))))

  (progn
    ;my/zk replace-regexp
    (my/defun my/zk/replace-all (regexp new-text)
      (interactive "Mregexp: \nMnew-text: ")
      (let ((buffers (my/zk/load-buffers)))
        (dolist (buf buffers)
          (with-current-buffer buf
            (while (re-search-forward regexp nil t)
              (replace-match new-text)))))))

  (progn
    ;; file name migration 2020-02-06
    (lexical-let ((old-note_XID-re
                   (let ((year-re    "\\([0-9][0-9][0-9][0-9]\\)")
                         (month-re   "\\([0-9][0-9]\\)")
                         (day-re     "\\([0-9][0-9]\\)")
                         (hour-re    "\\([0-9][0-9]\\)")
                         (minute-re  "\\([0-9][0-9]\\)")
                         (second-re  "\\([0-9][0-9]\\)")
                         (msecond-re "\\([0-9][0-9][0-9]\\)"))
                     (format "%s\\.%s\\.%s_%s:%s:%s\\.%s_UTC--\\(.*?\\)\\.org\\(\\.gpg\\)?"
                             year-re month-re day-re hour-re minute-re second-re msecond-re)))
                  (old-day_XID-re
                   (let ((year-re  "\\([0-9][0-9][0-9][0-9]\\)")
                         (month-re "\\([0-9][0-9]\\)")
                         (day-re   "\\([0-9][0-9]\\)"))
                     (format "%s\\.%s\\.%s\\.org\\.gpg" year-re month-re day-re))))
      (defalias 'my/zk/rename--2020-02-06
        (lambda (path)
          (when-let ((info (my/zk/parse-path path))
                     (dir-sym (car info))
                     (XID     (cdr info)))
            (cond
             ((eq dir-sym 'note)
              (cond
               ((string-match old-note_XID-re XID)
                (rename-file path
                             (my/zk/note:path
                              (format "%s-%s-%s_%s.%s.%s.%s_UTC--%s.org%s"
                                      (match-string 1 XID)
                                      (match-string 2 XID)
                                      (match-string 3 XID)
                                      (match-string 4 XID)
                                      (match-string 5 XID)
                                      (match-string 6 XID)
                                      (match-string 7 XID)
                                      (match-string 8 XID)
                                      (or (match-string 9 XID) "")))))
               ((string-match old-day_XID-re XID)
                (rename-file path
                             (my/zk/note:path
                              (format "%s-%s-%s.org.gpg"
                                      (match-string 1 XID)
                                      (match-string 2 XID)
                                      (match-string 3 XID)))))
               (t (message "did not rename '%s'" path))))
             ((eq dir-sym 'store)
              (if (string-match old-note_XID-re XID)
                  (progn
                    (let ((old-dir path)
                          (new-dir (f-expand
                                    (format "%s-%s-%s_%s.%s.%s.%s_UTC--%s.org%s"
                                            (match-string 1 XID)
                                            (match-string 2 XID)
                                            (match-string 3 XID)
                                            (match-string 4 XID)
                                            (match-string 5 XID)
                                            (match-string 6 XID)
                                            (match-string 7 XID)
                                            (match-string 8 XID)
                                            (or (match-string 9 XID) ""))
                                    my/zk/dir:store)))
                      (message "'%s' ⇝ '%s'" old-dir new-dir)
                      (rename-file old-dir new-dir)))
                (message "did not rename '%s'" path)))))))

      (defalias 'my/zk/replace:old_filenames--2020-02-06
        (lambda ()
          (interactive)
          (save-excursion
            (save-match-data
              (goto-char (point-min))
              (while (re-search-forward old-note_XID-re nil t)
                (replace-match (format "%s-%s-%s_%s.%s.%s.%s_UTC--%s.org%s"
                                       (match-string 1)
                                       (match-string 2)
                                       (match-string 3)
                                       (match-string 4)
                                       (match-string 5)
                                       (match-string 6)
                                       (match-string 7)
                                       (match-string 8)
                                       (or (match-string 9) ""))))
              (goto-char (point-min))
              (while (re-search-forward old-day_XID-re nil t)
                (replace-match (format "%s-%s-%s.org.gpg"
                                       (match-string 1)
                                       (match-string 2)
                                       (match-string 3)))))))))

    (my/defun my/zk/rename-all--2020-02-06 ()
      (interactive)
      (let* ((file-list (append (f-files my/zk/dir:note)
                                (f-directories my/zk/dir:store))))
        (mapc 'my/zk/rename--2020-02-06 file-list)))

    (my/defun my/zk/replace-all:old_filenames--2020-02-06 ()
      (interactive)
      (let ((buffers (my/zk/load-buffers)))
        (dolist (buf buffers)
          (with-current-buffer buf
            (my/zk/replace:old_filenames--2020-02-06))))))

  (progn
    ;; my/zk view all notes of a day
    (my/defun my/zk/view:links-to-a-days-notes (year month day)
"NOTE: ignores week notes and includes the day note of the given day"
      (let* ((nl (my/newline))
             (time (encode-time 0 0 0 day month year "UTC"))
             (date-info:short (format-time-string "%Y-%m-%d" time "UTC"))
             (date            (my/time-to-date time))
             (files (f-files my/zk/dir:note
                             (lambda (path)
                               (when-let ((split (my/zk/parse-path path))
                                          (XID (cdr split))
                                          (xdate (my/zk/XID-parse-date XID)))
                                 (and (eq (car xdate) 'day)
                                      (and (= year  (nth 1 xdate))
                                           (= month (nth 2 xdate))
                                           (= day   (nth 3 xdate)))))))))
        (let ((buffer (get-buffer-create
                       (generate-new-buffer
                        (format "*zk/day: %s*" date-info:short)))))
          (with-current-buffer buffer
            (insert "notes created on ")
            (my/zk/insert-link:core 'note (my/zk/day_XID date))
            (insert " & todays day file")
            (insert nl)
            (insert nl)
            (cl-loop for f in files
                     do (progn
                          (message f)
                          (insert (my/zk/simple-link-to-path f))
                          (insert nl)))
            (org-mode)
            (general-define-key
             :keymaps 'local
             [remap quit-window] 'kill-current-buffer))
          (display-buffer buffer))))

    (my/defun my/zk/view:links-to-a-days-notes:today ()
      (interactive)
      (let* ((now (decode-time (current-time) "UTC"))
             (day   (nth 3 now))
             (month (nth 4 now))
             (year  (nth 5 now)))
        (my/zk/view:links-to-a-days-notes year month day)))

    (my/defun my/zk/view:links-to-a-days-notes:interactive ()
      "Pick day for `my/zk/view:links-to-a-days-notes' via `calendar'.
I.e. beware of `calendar-week-start-day'"
      (interactive)
      (if-let ((date (my/zk/date:interactive)))
          (apply #'my/zk/view:links-to-a-days-notes date)
        (user-error "No date selected"))))

  (progn
    ;; interactive date pick functions

    (my/defun my/zk/date:interactive ()
      (interactive)
      (let ((start-date
             (when-let ((XID (my/zk/buffer-XID))
                        ((eq 'day (my/zk/XID-match XID))))
               (cdr (my/zk/XID-parse-date XID)))))
        (my/date:interactive start-date)))

    (my/defun my/zk/week:interactive ()
      (interactive)
      (let ((start-date
             (when-let ((XID (my/zk/buffer-XID)))
               (cond
                ((eq 'day (my/zk/XID-match XID))
                 (cdr (my/zk/XID-parse-date XID)))
                ((eq 'week (my/zk/XID-match XID))
                 (my/week-date-to-date (append (cdr (my/zk/XID-parse-date XID)) '(1))))
                (t nil)))))
        (my/week:interactive start-date))))

  (progn
    ;; my/zk view all notes of a week
    (my/defun my/zk/view:links-to-a-weeks-notes (week)
"NOTE: includes the week note and all the weeks day notes"
      (let* ((nl (my/newline))
             (iso-year (car week))
             (iso-week (cadr week))
             (files (f-files my/zk/dir:note
                             (lambda (path)
                               (when-let ((split (my/zk/parse-path path))
                                          (XID (cdr split))
                                          (xdate (my/zk/XID-parse-date XID)))
                                 (cond
                                  ((eq (car xdate) 'day)
                                   (equal (-take 2 (my/date-to-week-date (cdr xdate))) week))
                                  ((eq (car xdate) 'week)
                                   (equal (cdr xdate) week))))))))
        (let ((buffer (get-buffer-create
                       (generate-new-buffer
                        (format "*zk/week: %s*" (format "%04d-W%02d" iso-year iso-week))))))
          (with-current-buffer buffer
            (insert "notes created during ")
            (my/zk/insert-link:core 'note (my/zk/week_XID week))
            (insert " & current week's week note and day notes")
            (insert nl)
            (insert nl)
            (cl-loop for f in files
                     do (progn
                          (message f)
                          (insert (my/zk/simple-link-to-path f))
                          (insert nl)))
            (org-mode)
            (general-define-key
             :keymaps 'local
             [remap quit-window] 'kill-current-buffer))
          (display-buffer buffer))))

    (my/defun my/zk/view:links-to-a-weeks-notes:today ()
      (interactive)
      (my/zk/view:links-to-a-weeks-notes (my/week:today)))

    (my/defun my/zk/view:links-to-a-weeks-notes:interactive ()
      "Pick day for `my/zk/view:links-to-a-weeks-notes' via `calendar'.
I.e. beware of `calendar-week-start-day'"
      (interactive)
      (if-let ((week (my/week:interactive )))
          (my/zk/view:links-to-a-weeks-notes week)
        (user-error "No date selected"))))

  (progn
    ;; date notes: day note, week notes, file handler

    (progn
      ;; day note 2020-01-30
      ;; NOTE: day note ≠ day file
      (my/defun my/zk/day_XID* (year month day)
        "uses `encode-time' and `format-time-string'
(determines behaviour if year month day do not represent a real date).
NOTE: can also be parsed via `my/zk/timestamp:parse-day' `my/zk/timestamp:parse-month' `my/zk/timestamp:parse-year'"
        (format-time-string "%Y-%m-%d.org.gpg" (encode-time 0 0 0 day month year)))
      (my/defun my/zk/day_XID (date)
        "c.f. `my/zk/day_XID'"
        (apply #'my/zk/day_XID* date))

      (my/defun my/zk/day_XID-to-date (XID)
        "Inverse function of `my/zk/day_XID' (∀ \"valid\" dates; c.f. info in `my/zk/day_XID')
PRECONDITION: XID is a day_XID."
        (list (my/zk/timestamp:parse-year XID)
              (my/zk/timestamp:parse-month XID)
              (my/zk/timestamp:parse-day XID)))

      (my/defun my/zk/day_XID-re ()
        "subexp 1 = year (4 digit number)
subexp 2 = month (2 digit number (range not checked))
subexp 3 = day (2 digit number (range not checked))
"
        (let ((year-re  "\\([0-9][0-9][0-9][0-9]\\)")
              (month-re "\\([0-9][0-9]\\)")
              (day-re   "\\([0-9][0-9]\\)"))
          (format "%s\\-%s\\-%s\\.org\\.gpg" year-re month-re day-re)))

      (my/defun my/zk/day_note:interactive ()
        "Pick a day via `my/zk/date:interactive'.
I.e. beware of `calendar-week-start-day'"
        (interactive)
        (if-let ((date (my/zk/date:interactive)))
            (find-file (my/zk/note:path (my/zk/day_XID date)))
          (user-error "No date selected")))

      (my/defun my/zk/day_note:title (date)
        (cl-destructuring-bind (year month day) date
          (format-time-string
           "%Y-%m-%d %a"
           (encode-time 0 0 0 day month year))))

      (defalias 'my/zk/day_note:today
        (my/cmd (∘ #'find-file #'my/zk/note:path #'my/zk/day_XID #'my/date:today))))

    (progn
      ;; week note 2020-01-30
      (my/defun my/zk/week_XID* (iso-year iso-week)
"\"%04d-W%02d.org.gpg\" ISO-YEAR ISO-WEEK"
        (format "%04d-W%02d.org.gpg" iso-year iso-week))

      (my/defun my/zk/week_XID (date)
        "c.f. `my/zk/week_XID'"
        (apply #'my/zk/week_XID* date))

      (my/defun my/zk/week_XID-re ()
        "subexp 1 = year (4 digit number)
subexp 2 = month (2 digit number (range not checked))
subexp 3 = day (2 digit number (range not checked))
"
        (let ((iso-year-re "\\([0-9][0-9][0-9][0-9]\\)")
              (iso-week-re "\\([0-9][0-9]\\)"))
          (format "%s-W%s\\.org\\.gpg" iso-year-re iso-week-re)))

      (my/defun my/zk/week_XID-to-date (XID)
        "Inverse function of `my/zk/week_XID' (∀ \"valid\" weeks created via `my/zk/week_XID')
PRECONDITION: XID is a week_XID."
        (save-match-data
          (when (string-match (my/zk/week_XID-re) XID)
            (when-let ((y (string-to-number (match-string-no-properties 1)))
                       (w (string-to-number (match-string-no-properties 2))))
              (list y w)))))

      (my/defun my/zk/week_note:interactive ()
        "Pick week via `my/zk/week:interactive'.
I.e. beware of `calendar-week-start-day'"
        (interactive)
        (if-let ((week (my/zk/week:interactive)))
            (find-file (my/zk/note:path (my/zk/week_XID week)))
          (user-error "No date selected")))

      (my/defun my/zk/week_note:title (date)
        (format "%04d-W%02d" (car date) (cadr date)))

      (defalias 'my/zk/week_note:today
        (my/cmd (∘ #'find-file #'my/zk/note:path #'my/zk/week_XID #'my/week:today))))


    (defun my/zk/day_note-insert_body ()
      (insert (my/newline))
      (insert "MONITOR: ")
      (my/zk/insert-link:core 'note my/zk/XID/MONITOR)
      (insert (my/newline))
      (insert (my/newline))
      (insert "* productive (")
      (my/zk/insert-link:core 'note my/zk/XID/tasks_productive)
      (insert ")")
      (insert (my/newline))
      (insert (my/newline))
      (insert "* noon-window (")
      (my/zk/insert-link:core 'note my/zk/XID/tasks_noon_window)
      (insert ")")
      (insert (my/newline))
      (insert (my/newline))
      (insert "* evening-window (")
      (my/zk/insert-link:core 'note my/zk/XID/tasks_evening_window)
      (insert ")")
      (insert (my/newline))
      (insert (my/newline))
      (insert "* DEFERRED:")
      (insert (my/newline))
      (insert (my/newline))
      (insert "* journal")
      (insert (my/newline)))

    (defun my/zk/file-handler (operation &rest args)
      "Adapted from
https://www.gnu.org/software/emacs/manual/html_node/elisp/Magic-File-Names.html [2020-01-30]
Current use case could maybe also just be handled via `find-file-not-found-functions'.
(But problem for functions using `insert-file-contents')"
      (cl-flet ((default-operation ()
                  (let ((inhibit-file-name-handlers
                         (cons 'my/zk/file-handler
                               (and (eq inhibit-file-name-operation operation)
                                    inhibit-file-name-handlers)))
                        (inhibit-file-name-operation operation))
                    (apply operation args))))
        (if-let* (((eq operation 'insert-file-contents))
                  (path (car args))
                  ((my/zk/note:path-p path))
                  (filename (f-filename path))
                  (XID-type (cond
                              ((string-match (format "^%s$" (my/zk/day_XID-re)) filename)
                               'day_note)
                              ((string-match (format "^%s$" (my/zk/week_XID-re)) filename)
                               'week_note)
                              (t nil))))
            (cond
             ((eq 'day_note XID-type)
              (let ((year  (string-to-number (match-string 1 filename)))
                    (month (string-to-number (match-string 2 filename)))
                    (day   (string-to-number (match-string 3 filename))))
                (if (f-exists? path)
                    (progn
                      (message "(my/zk/file-handler %S %S): update '%s' for date [%04d-%02d-%02d]" operation args path year month day)
                      (default-operation)
                      (save-excursion
                        (my/zk/note:goto-beginning-of-first-content-line)
                        (my/replace-region (line-beginning-position) (line-end-position) (my/zk/day_note:title (list year month day)))))
                  (progn
                    (barf-if-buffer-read-only)
                    (message "(my/zk/file-handler %S %S): create '%s' for date [%04d-%02d-%02d]" operation args path year month day)
                    ;; first create file via sth that is not find-file
                    ;; NOTE: relies on `save-buffer' not using `insert-file-contents'
                    (with-temp-buffer
                      (my/org/gpgify-buffer)
                      (goto-char (point-max))
                      (insert (my/zk/day_note:title (list year month day)))
                      (insert (my/newline))
                      (let ((wdate (my/date-to-week-date (list year month day))))
                        (my/zk/insert-link:core 'note (my/zk/week_XID (my/week-date-to-week wdate)))
                        (insert (format  " (%04d-W%02d-%d)" (car wdate) (cadr wdate) (caddr wdate))))
                      (insert (my/newline))
                      (set-visited-file-name path 'no-query)
                      (my/zk/insert-link:core 'meta_is my/zk/XID/day_note)
                      (insert (my/newline))
                      (insert (my/newline))
                      (my/zk/day_note-insert_body)
                      (save-buffer)
                      (my/zk/note:after-save-hook))
                    (if (f-exists? path)
                        ;; "recurse" (file exists now and will be handled differently)
                        (apply #'insert-file-contents args)
                      (error "could not create day_note '%s'" path))))))
             ((eq 'week_note XID-type)
              (let ((iso-year    (string-to-number (match-string 1 filename)))
                    (iso-week    (string-to-number (match-string 2 filename))))
                (if (f-exists? path)
                    (progn
                      (message "(my/zk/file-handler %S %S): create '%s' for week [%04d-W%02d]"
                               operation args path iso-year iso-week)
                      (default-operation)
                      (save-excursion
                        (my/zk/note:goto-beginning-of-first-content-line)
                        (my/replace-region (line-beginning-position) (line-end-position)
                                           (my/zk/week_note:title (list iso-year iso-week)))))
                    (progn
                      (barf-if-buffer-read-only)
                      (message "(my/zk/file-handler %S %S): create '%s' for week [%04d-W%02d]"
                               operation args path iso-year iso-week)
                      ;; first create file via sth that is not find-file
                      ;; NOTE: relies on `save-buffer' not using `insert-file-contents'
                      (with-temp-buffer
                        (my/org/gpgify-buffer)
                        (goto-char (point-max))
                        (insert (my/zk/week_note:title (list iso-year iso-week)))
                        (insert (my/newline))
                        (set-visited-file-name path 'no-query)
                        (my/zk/insert-link:core 'meta_is my/zk/XID/week_note)
                        (insert (my/newline))
                        (insert (my/newline))
                        (insert "* days")
                        (insert (my/newline))
                        (dolist (iso-weekday '(1 2 3 4 5 6 7))
                          (my/zk/insert-link:core 'note (my/zk/day_XID (my/week-date-to-date (list iso-year iso-week iso-weekday))))
                          (insert (my/newline)))
                        (insert (my/newline))
                        (insert "* productive (")
                        (my/zk/insert-link:core 'note my/zk/XID/tasks_productive)
                        (insert ")")
                        (insert (my/newline))
                        (insert (my/newline))
                        (insert "* to schedule")
                        (insert (my/newline))
                        (save-buffer)
                        (my/zk/note:after-save-hook))
                      (if (f-exists? path)
                          ;; "recurse" (file exists now and will be handled differently)
                          (apply #'insert-file-contents args)
                        (error "could not create week_note '%s'" path))))))
             (t (error "programming error in my/zk/file-handler")))
          (default-operation))))

    (defconst my/zk/file-handler:alist-entry
      (cons "gpg" 'my/zk/file-handler)
      "shorter string: problem with some .elc stuff (TODO:DEFERRED:)
longer string (.org.gpg): lower prio than `epa-file-handler'")

    (defun my/zk/file-handler:enable ()
      "adapted from `epa-file-enable'
NOTE: TEST via `find-file-name-handler'"
      (interactive)
      (if (memq my/zk/file-handler:alist-entry file-name-handler-alist)
          (message "`my/zk/file-handler' already enabled")
        (setq file-name-handler-alist
              (cons my/zk/file-handler:alist-entry file-name-handler-alist))
        (message "`my/zk/file-handler' enabled")))

    (defun my/zk/file-handler:disable ()
      "adapted from `epa-file-disable'"
      (interactive)
      (if (memq my/zk/file-handler:alist-entry file-name-handler-alist)
          (progn
            (setq file-name-handler-alist
                  (delq my/zk/file-handler:alist-entry file-name-handler-alist))
            (message "`my/zk/file-handler' disabled"))
        (message "`my/zk/file-handler' already disabled")))

    (defun my/zk/test/file-handler ()
      (eq (find-file-name-handler (f-expand "9999-99-99.org.gpg" my/zk/dir:note) 'insert-file-contents)
          #'my/zk/file-handler))

    (my/zk/file-handler:enable))

  (defun my/zk/XID-match (XID)
"c.f. `my/zk/XID-parse'
NOTE: modifies match-data"
    (cond
     ((string-match (format "^%s$" (my/zk/note_XID-re)) XID)
      'note)
     ((string-match (format "^%s$" (my/zk/day_XID-re)) XID)
      'day)
     ((string-match (format "^%s$" (my/zk/week_XID-re)) XID)
      'week)
     (t nil)))

  (lexical-let ((enc-re (rx ".gpg")))
    (defun my/zk/XID-encrypted-note-p (XID)
      " NOTE: does not check for valid XID
returns nil ⇔ XID does not indicate encrypted note"
      (string-match-p enc-re XID)))


  (defun my/zk/XID-parse-date (XID)
    "c.f. `my/zk/XID-match'"
    (save-match-data
      (cond
       ((string-match (format "^%s$" (my/zk/note_XID-re)) XID)
        (list 'day
              (string-to-number (match-string 1 XID))
              (string-to-number (match-string 2 XID))
              (string-to-number (match-string 3 XID))))
       ((string-match (format "^%s$" (my/zk/day_XID-re)) XID)
        (list 'day
              (string-to-number (match-string 1 XID))
              (string-to-number (match-string 2 XID))
              (string-to-number (match-string 3 XID))))
       ((string-match (format "^%s$" (my/zk/week_XID-re)) XID)
        (list 'week
              (string-to-number (match-string 1 XID))
              (string-to-number (match-string 2 XID))))
       (t nil))))

  (defun my/zk/XID-parse (XID)
    "c.f. `my/zk/XID-match'"
    (save-match-data
      (cond
       ((string-match (format "^%s$" (my/zk/note_XID-re)) XID)
        (list (if (match-beginning 9)
                  'note:encrypted
                'note:plain)
              (string-to-number (match-string 1 XID))
              (string-to-number (match-string 2 XID))
              (string-to-number (match-string 3 XID))
              (string-to-number (match-string 4 XID))
              (string-to-number (match-string 5 XID))
              (string-to-number (match-string 6 XID))
              (string-to-number (match-string 7 XID))))
       ((string-match (format "^%s$" (my/zk/day_XID-re)) XID)
        (list 'day
              (string-to-number (match-string 1 XID))
              (string-to-number (match-string 2 XID))
              (string-to-number (match-string 3 XID))))
       ((string-match (format "^%s$" (my/zk/week_XID-re)) XID)
        (list 'week
              (string-to-number (match-string 1 XID))
              (string-to-number (match-string 2 XID))))
       (t nil))))

  (defun my/zk/parsed-note-alist:ivy (path section)
"Returns alist (description XID)"
    (with-current-buffer (find-file-noselect path)
      (mapcar (lambda (item) (cons (caddr item) (cadr item)))
              (my/zk/delimited-section:parsed-note-list section))))

  (defun my/zk/ivy-select:note-alist (alist)
    "Returns cons (XID description) of selected element.
Preselects current-buffer if in alist."
    (let ((result nil))
      (ivy-read "" alist
                :require-match t
                :preselect (or (when-let ((hit (rassoc (my/zk/buffer-XID) alist)))
                                 (car hit))
                               0)
                :action (lambda (ret) (setq result (cons (cdr ret) (car ret)))))
      result))

  (defun my/zk/ivy-select:from-section (path section &optional &key special-nil-candidate)
    "If element selected: Returns cons (XID description) of selected element"
    (when-let ((alist (my/zk/parsed-note-alist:ivy path section)))
      (let ((result nil))
        (ivy-read ""
                  (if special-nil-candidate
                      (cons (cons nil nil) alist)
                    alist)
                  :require-match t
                  :preselect nil
                  :action (if special-nil-candidate
                              (lambda (ret) (when
                                                (car ret)
                                              (setq result (cons (cdr ret) (car ret)))))
                            (lambda (ret) (setq result (cons (cdr ret) (car ret))))))
        result)))

  (defun my/zk/thread-select:interactive ()
    "Returns cons (XID description) of selected element
TODO: REVISE via `my/zk/ivy-select:from-section'"
    (when-let ((thread-alist (my/zk/parsed-note-alist:ivy (my/zk/note:path my/zk/XID/thread) "instances\n")))
      (my/zk/ivy-select:note-alist thread-alist)))

  (defalias 'my/zk/thread-select:XID:interactive
    (∘ (my/skip-nil #'car) #'my/zk/thread-select:interactive)
    "Like `my/zk/thread-select:interactive' but returns only XID of selected element")

  (defalias 'my/zk/thread_note:interactive
    (my/cmd (∘ (my/skip-nil (∘ #'find-file #'my/zk/note:path)) #'my/zk/thread-select:XID:interactive )))

  (defun my/zk/active_task-select:hierarchical:interactive ()
    "Returns cons (XID description) of selected element.
Hierarchical version of `my/zk/active_task-select:interactive'
(1. thread -> 2. task)
TODO: recurse into deeper levels."
    (when-let ((thread (my/zk/thread-select:interactive))
               (thread-file (my/zk/note:path (car thread)))
               (task-alist (cons (cons (cdr thread) (car thread))
                                 (my/zk/parsed-note-alist:ivy thread-file "parts\n"))))
      (my/zk/ivy-select:note-alist task-alist)))

  (defun my/zk/active_task-alist ()
    (cl-labels ((subtask-alist
                 (task-cons)
                 (if-let ((al (my/zk/parsed-note-alist:ivy (my/zk/note:path (cdr task-cons)) "parts\n")))
                     (append al (-flatten-n 1 (mapcar #'subtask-alist al)))
                   al)))
      (when-let* ((thread-alist (my/zk/parsed-note-alist:ivy
                                 (my/zk/note:path my/zk/XID/thread) "instances\n")))
        (append
         thread-alist
         (-flatten-n 1 (mapcar #'subtask-alist thread-alist))))))

  (defalias 'my/zk/active_task-select:interactive
    (∘ #'my/zk/ivy-select:note-alist #'my/zk/active_task-alist)
    "Returns cons (XID description) of selected element.
\"Flat\" version of `my/zk/active_task-select:hierarchical:interactive'
(1. thread -> 2. task)")

  (defalias 'my/zk/active_task-select:XID:interactive
    (∘ (my/skip-nil #'car) #'my/zk/active_task-select:interactive)
    "Like `my/zk/active_task-select:interactive' but returns only XID of selected element")

  (defalias 'my/zk/active_task_note:interactive
    (my/cmd (∘ (my/skip-nil (∘ #'find-file #'my/zk/note:path)) #'my/zk/active_task-select:XID:interactive )))

  ;; TODO: refactor
  (defun my/zk/find-link (link:sym &rest link:core-args)
    (interactive)
    ;; TODO: performance [DEFERRED:]
    (save-excursion
      (goto-char (point-min))
      (let ((still_searching t)
            (result nil)
            (end (my/zk/search-forward-link)))
        (while (and still_searching end)
          (when (eq link:sym (intern (match-string 1)))
            (let ((parse-result (my/zk/link-parse:from-prefix-parse
                                 (list link:sym
                                       (substring-no-properties (match-string 2))
                                       (substring-no-properties (match-string 3))))))
              (when (equal (my/zk/take-core-args parse-result)
                           link:core-args)
                (setq still_searching nil
                      result (list end parse-result)))))
          (when still_searching
            (setq end (my/zk/search-forward-link))))
        result)))

  (defun my/zk/ensure-link (ensured-link:sym &rest ensured-link:core-args)
    (unless (apply #'my/zk/find-link ensured-link:sym ensured-link:core-args)
      (my/zk/note:goto-beginning-of-first-content-line)
      (beginning-of-line 2)
      (funcall (my/zk/insert-link-fn:core ensured-link:sym) ensured-link:core-args)
      (insert (my/newline))))

  (defalias 'my/zk/ensure-part_of-thread:interactive 
     (my/cmd (∘ (ap #'my/zk/ensure-link 'part_of) #'my/zk/thread-select:XID:interactive)))

  (defalias 'my/zk/ensure-part_of-active_task:interactive 
     (my/cmd (∘ (ap #'my/zk/ensure-link 'part_of) #'my/zk/active_task-select:XID:interactive)))

  (defun my/zk/find-new-task_note (thread-XID &optional title)
    (if (my/zk/XID-encrypted-note-p thread-XID)
        (my/zk/note:find_new:encrypted)
      (my/zk/note:find_new:plain))
    (my/zk/note:goto-beginning-of-first-content-line)
    (insert (or title "TODO: "))
    (when title
      (my/zk/note:rename-buffer))
    (save-excursion
      (insert (my/newline))
      (my/zk/insert-link:core 'part_of thread-XID))
    (set-buffer-modified-p nil))

  (defalias 'my/zk/find-new-task_note:interactive
    (my/cmd (∘ (my/skip-nil #'my/zk/find-new-task_note) #'my/zk/thread-select:XID:interactive)))

  (defalias 'my/zk/find-new-subtask_note:interactive
    (my/cmd (∘ (my/skip-nil (my/apply-fn #'my/zk/find-new-task_note))
               (°a #'my/zk/active_task-select:XID:interactive
                                (lambda () (read-string "title: " "TODO: ")))
               (my/const nil))))

  (defun my/zk/log-task_note:current-buffer ()
    "Find first task note T s.t. note XID is part_of:T.
When ∃ T:
    Replace part_of:T link with log:T link.
    When note XIDs title starts with 'TODO:' or 'NEXT:' or 'WIP:' replace it with 'DONE:'"
    (interactive)
    (let ((task-XID-list (mapcar #'cdr (my/zk/active_task-alist))))
      ;; TODO: performance [DEFERRED:]
      (save-excursion
        (goto-char (point-min))
        (let ((still_searching t)
              (thread-XID nil)
              (end (my/zk/search-forward-link)))
          (while (and still_searching end)
            (when (eq 'part_of (intern (match-string 1)))
              (let* ((parse-result (my/zk/link-parse:from-prefix-parse
                                    (list 'part_of
                                          (substring-no-properties (match-string 2))
                                          (substring-no-properties (match-string 3)))))
                     (link:XID (cadr parse-result)))
                (message "parse-result = %S" parse-result)
                (when (member link:XID task-XID-list)
                  (setq still_searching nil
                        thread-XID link:XID))))
            (when still_searching
              (setq end (my/zk/search-forward-link))))
          (unless still_searching
            (goto-char (match-beginning 0))
            (message "thread=%s %S %d %S %c" thread-XID (match-beginning 0) end (point) (char-after))
            (my/zk/delete-link-at-point-remove-side-effects)
            (my/zk/insert-link:core 'log thread-XID)
            (my/zk/note:goto-beginning-of-first-content-line)
            (save-match-data
              (when (looking-at "\\(TODO\\|NEXT\\|WIP\\):")
                (my/replace-region (match-beginning 1) (match-end 1) "DONE")
                (set-buffer-modified-p nil))))))))

  (defun my/zk/find-new-log_note-for-XID (XID)
    (my/zk/note:find_new:log_note)
    (my/zk/note:goto-beginning-of-first-content-line)
    (end-of-line)
    (insert " ")
    (my/zk/insert-link:core 'log XID)
    (set-buffer-modified-p nil))

  (defalias 'my/zk/find-new-log_note-for-active_task:interactive 
    (my/cmd (∘ (my/skip-nil #'my/zk/find-new-log_note-for-XID) #'my/zk/active_task-select:XID:interactive)))

  (defun my/zk/find-new-log_note-for-current-buffer (&optional buffer)
    (interactive)
    (let ((buffer (or buffer (current-buffer))))
      (when-let ((XID (my/zk/buffer-XID buffer)))
        (my/zk/find-new-log_note-for-XID XID))))

  (defun my/zk/store-dir:terminal:external (&optional XID)
    (interactive)
    (if-let ((XID (or XID (my/zk/buffer-XID)))
             (store-dir (my/dir:ensure (my/zk/store:path XID))))
        (my/terminal:external store-dir)
      (user-error "current-buffer is not visitng a my/zk file")))

  (defun my/zk/store-dir:kill-new (&optional XID)
    "basically `kill-new' called on path to store-dir of XID"
    (interactive)
    (if-let ((XID (or XID (my/zk/buffer-XID)))
             (store-dir (my/dir:ensure (my/zk/store:path XID))))
        (kill-new store-dir)
      (user-error "current-buffer is not visitng a my/zk file")))

  (defalias 'my/zk/find-time_budget-note
    (my/cmd (∘ #'find-file #'my/zk/note:path (my/const my/zk/XID/time_budget)))
    "Open `my/zk/XID/time_budget'")

  (progn
    ;; zk/store-lns

    (my/defvar my/zk/dir:store-lns
               (my/zk/expand-path "store-lns/")
               "Directory where temporary symlinks are be stored")

    ;; TODO: check existence of dir

    (defun my/zk/normalize-file-name (file-name)
      "Transforms `file-name' s.t. only chars we like in a filename remain.
 '&'  ⇝ 'and'
 Delete '[^a-zA-Z0-9.:+_ -]'
 ' '+ ⇝ '_'
 "
      (replace-regexp-in-string
       " +" "_"
       ;; NOTE: '-' needs to be last char in brackets in a regexp
       ;;       to count as char and not range operator
       (replace-regexp-in-string
        "[^a-zA-Z0-9.:+_ -]" ""
        (replace-regexp-in-string
         ":" "-"
         (replace-regexp-in-string
          "&" "and" file-name)))))

    (defun my/zk/clean-store-ln-dir ()
      "Deletes _all_ symlinks in `my/zk/dir:store-lns' and then creates the file '.keep' in it"
      (interactive)
      (if (f-directory-p my/zk/dir:store-lns)
          (dolist (file (f-entries my/zk/dir:store-lns #'f-symlink-p))
              (f-delete file))
        (user-error "store-lns dir does not exist")))

    (defun my/zk/create-store-ln (XID)
      (if (f-directory-p my/zk/dir:store-lns)
          (let* ((file-name-normalized (my/zk/normalize-file-name (my/zk/note:derive-description:XID XID)))
                 (file-name (string-join (mapcar (lambda (string)
                                                   (string-trim string "_" "_"))
                                                 (split-string file-name-normalized "--"))
                                         "--"))
                 (ln-path (f-expand file-name my/zk/dir:store-lns)))
            (if (f-exists-p ln-path)
                (user-error "store-ln '%s' exists already" file-name)
              (f-symlink (my/dir:ensure (my/zk/store:path XID)) ln-path)))
        (user-error "store-lns dir does not exist")))

    (defun my/zk/create-store-ln:buffer (&optional buffer)
      "c.f. `my/zk/create-store-ln'"
      (interactive)
      (let ((buffer (or buffer (current-buffer))))
        (if-let ((XID (my/zk/buffer-XID buffer)))
            (my/zk/create-store-ln XID)
          (user-error "not in my/zk note buffer")))))

  (defun my/zk/archive-current-buffer ()
    (interactive)
    (when (or (not (buffer-modified-p))
              (y-or-n-p (format "current buffer (modified) might be changed and file '%s' will be overwritten. okay?" (buffer-file-name))))
      (save-excursion
        ;; delete all links to `my/zk/XID/temporary' or `my/zk/XID/to_review'
        ;; and check whether file is linking to `my/zk/XID/archived'
        (let ((archived nil))
          (goto-char (point-min))
          (let ((end (my/zk/search-forward-link)))
            (while end
              (when-let ((start (match-beginning 0))
                         (parse-args (list (intern (match-string 1)) (substring-no-properties (match-string 2)) (substring-no-properties (match-string 3))))
                         (parse-result (my/zk/link-parse:from-prefix-parse parse-args))) 
                (cl-destructuring-bind (prefix-sym XID &rest args-rest) parse-result
                  (message "link-candidate %S [parse-result=%S]" (substring-no-properties (match-string 0)) parse-result)
                  (when (eq prefix-sym 'meta_is)
                    (cond
                       ((and (or (string= XID my/zk/XID/temporary)
                                 (string= XID my/zk/XID/to_review)))
                        (save-excursion
                          (goto-char start)
                          (my/zk/delete-link-at-point-remove-side-effects)))
                       ((string= XID my/zk/XID/archived)
                        (setq archived t))
                       (t nil)))))
              (setq end (my/zk/search-forward-link))))
          (unless archived
            (my/zk/note:goto-beginning-of-first-content-line)
            (beginning-of-line 2)
            (my/zk/insert-link:core 'meta_is my/zk/XID/archived)
            (insert (my/newline)))))
      (my/zk/save-buffer)))

  ;; (defun my/zk/insert-title-after (note-creation-fn)
  ;;   (when-let ((title (read-string "title:")))
  ;;     (note-creation-fn)
  ;;     (insert title)))

  (defun my/zk/cite-new-note:plain ()
    (interactive)
    (let* ((XID (my/zk/note_XID:plain))
           (title (read-string "title: "))
           (buffer (funcall (∘ #'find-file-noselect #'my/zk/note:path)
                            XID)))
      (with-current-buffer buffer
        (my/zk/note:goto-beginning-of-first-content-line)
        (insert title)
        (insert (my/newline)))
      (my/zk/insert-link 'cite XID (my/zk/note:derive-description-from-string title))
      (display-buffer buffer)))

  (defun my/zk/note:find_new:plain+child ()
    (interactive)
    (let* ((XID (my/zk/note_XID:plain))
           (parent-desc (my/zk/note:derive-description:short))
           (title (save-excursion
                    (read-string "title: " (format "%s :: " parent-desc))))
           (buffer (funcall (∘ #'find-file-noselect #'my/zk/note:path)
                            XID)))
      (with-current-buffer buffer
        (my/zk/note:goto-beginning-of-first-content-line)
        (insert title)
        (insert (my/newline))
        (save-buffer))
      (display-buffer buffer)))

  (defun my/zk/cite-new-note:plain+transcluded ()
    (interactive)
    (let* ((XID (my/zk/note_XID:plain))
           (parent-XID (my/zk/buffer-XID))
           (parent-desc (my/zk/note:derive-description:short))
           (title (save-excursion
                    (read-string "title: " (format "%s :: " parent-desc))))
           (buffer (funcall (∘ #'find-file-noselect #'my/zk/note:path)
                            XID)))
      (with-current-buffer buffer
        (my/zk/note:goto-beginning-of-first-content-line)
        (insert title)
        (insert (my/newline))
        (my/zk/insert-link 'context parent-XID parent-desc)
        (insert (my/newline)))
      (my/zk/insert-link 'cite XID (my/zk/note:derive-description-from-string title))
      (display-buffer buffer)))

  (defun my/zk/buffer-note:make_consumable_medium ()
    (interactive)
    (let*
        ((lang (my/zk/ivy-select:from-section
                (my/zk/note:path "2020-06-06_19.19.18.978_UTC--mirs@wrucon.org")
                "meta-instances\n"
                :special-nil-candidate t))
         (is (my/zk/ivy-select:from-section
              (my/zk/note:path "2020-10-24_16.00.44.239_UTC--mirs@wrucon.org")
              "instances\n"
              :special-nil-candidate t))
         (series-index-string
          (when
              (or
               (string= "2020-03-07_18.29.47.893_UTC--mirs@wrucon.org" (car is))  ;; tv series
               )
            (read-string "series index string (e.g. 'season 1'): " "season 1")))
         (via (my/zk/ivy-select:from-section
               (my/zk/note:path "2020-09-29_14.06.48.782_UTC--mirs@wrucon.org.gpg")
               "meta-instances\n"
               :special-nil-candidate t))
         (enter (my/zk/ivy-select:from-section
                 (my/zk/note:path "2020-03-07_05.55.11.406_UTC--mirs@wrucon.org.gpg")
                 "subsets\n"
                 :special-nil-candidate t)))
      (let ((speed-string
             (when (or
                    (string= "2020-03-14_19.22.03.293_UTC--mirs@wrucon.org" (car is))  ;; movie
                    (string= "2020-03-07_18.29.47.893_UTC--mirs@wrucon.org" (car is))  ;; tv series
                    )
               (if (and
                    via
                    (string= "2020-04-05_11.31.00.355_UTC--mirs@wrucon.org.gpg" (car via)) ;; netflix
                    )
                   "ep01ff: speed = 1.0 & sub duration = 2.0"
                 "ep01ff: speed = 1.0 & sub duration = 2.0"))))
        (save-buffer)
        (save-excursion
          (my/zk/note:goto-beginning-of-first-content-line)
          (beginning-of-line 2)
          (when is
            (my/zk/insert-link 'is (car is) (cdr is)))
          (insert (my/newline))
          (when lang
            (my/zk/insert-link 'is (car lang) (cdr lang)))
          (insert (my/newline))
          (save-buffer)
          (cond
           ((and is (string= "2020-03-07_18.29.47.893_UTC--mirs@wrucon.org"
                             (car is)))
            ;; tv series
            (let* ((child-XID (my/zk/note_XID:plain))
                   (parent-XID (my/zk/buffer-XID))
                   (parent-desc (my/zk/note:derive-description:short))
                   (buffer (funcall (∘ #'find-file-noselect #'my/zk/note:path)
                                    child-XID))
                   )
              (with-current-buffer buffer
                (my/zk/note:goto-beginning-of-first-content-line)
                (my/zk/insert-link 'note parent-XID parent-desc)
                (insert (format " :: %s" series-index-string))
                (insert (my/newline))
                (save-buffer)
                (my/zk/insert-link 'part_of parent-XID parent-desc)
                (insert (my/newline))
                (insert (my/newline))
                (insert (my/newline))
                (insert (my/newline))
                (insert "* watch history")
                (insert (my/newline))
                (insert (my/newline))
                (when via
                  (my/zk/insert-link 'part_of (car via) (cdr via))
                  (insert (my/newline)))
                (when speed-string
                  (insert speed-string)
                  (insert (my/newline)))
                (when enter
                  (my/zk/insert-link 'is (car enter) (cdr enter))
                  (insert (my/newline)))
                (insert (my/newline))
                (insert "* glossary")
                (insert (my/newline))
                (insert (my/newline))
                (insert "* notes")
                (insert (my/newline))
                (my/zk/note:goto-beginning-of-first-content-line)
                (beginning-of-line 4)
                (save-buffer))))
           (t
            ;; no new child node
            (when via
                  (my/zk/insert-link 'part_of (car via) (cdr via))
                  (insert (my/newline)))
            (when speed-string
              (insert speed-string)
              (insert (my/newline)))
            (insert (my/newline))
            (when enter
              (my/zk/insert-link 'is (car enter) (cdr enter))
              (insert (my/newline)))
            (insert (my/newline))
            (save-buffer)))))))

  (defun my/zk/buffer-note:create_and_store_screenshot_and_insert_link_at_point ()
    (interactive)
    (let ((pic_file_basename_default "picture.png") ;; hardcoded
          (path_to_import_tool "import")) ;; NOTE: hardcoded; alternative: 'flameshot'
      (if (not (executable-find path_to_import_tool))
          (user-error "necesarry tool 'import' could not be found at path '%s'" path_to_import_tool)
        (if-let ((XID (my/zk/buffer-XID))
                 (store-dir (my/dir:ensure (my/zk/store:path XID)))
                 (default-directory store-dir))
            (let ((pic_file_basename
                   (save-excursion
                     (read-string "file name: "
                                  (format "%s" pic_file_basename_default)))))
              (progn
                (start-process (format "%s %s" path_to_import_tool pic_file_basename) nil path_to_import_tool pic_file_basename)
                (save-excursion
                  (my/zk/insert-link 'store pic_file_basename)
                  (save-buffer))))
          (user-error "current-buffer is not visitng a my/zk file")))))

  (defun my/zk/buffer-note:ace-link_youtube-dl_and_insert_link_at_point ()
    (interactive)
    (let ((file_basename_default "video") ;; hardcoded
          (path_to_tool "youtube-dl")) ;; NOTE: hardcoded
      (if (not (executable-find path_to_tool))
          (user-error "necesarry tool could not be found at path '%s'" path_to_tool)
        (progn
          (if-let ((XID (my/zk/buffer-XID))
                   (store-dir (my/dir:ensure (my/zk/store:path XID)))
                   (default-directory store-dir))
              (if-let* ((path-info (my/zk/ace-link:path))
                        (url (nth 2 path-info)))
                  (let ((file_basename
                         (save-excursion
                           (read-string "file name (without extension): "
                                        (format "%s" file_basename_default)))))
                    (progn
                      (message "%s %s" url (format "%s.%%(ext)s" file_basename))
                      (start-process (format "youtube-dl %s" file_basename) nil path_to_tool url (format "%s.%%(ext)s" file_basename))
                      (save-excursion
                        (my/zk/insert-link 'store file_basename)
                        (save-buffer))))
                (user-error "no or invalid link selected"))
            (user-error "current-buffer is not visitng a my/zk file"))))))

  (defun my/zk/add-symbol-for-current-note ()
"notes during this process:
  * current buffer
  * ${(description-of (current-buffer))} :: symbol
    * called 'parent' in the following
    * called 'note-symbol' in the following
  * ${symbol-string}
    * asked for interactively
    * called 'symbol' in the follwoing
"
    (interactive)
    (let ((parent-XID (my/zk/buffer-XID))
          (parent-desc (my/zk/note:derive-description:short)))
      (let* ((note-desc-XID-alist (my/zk/cache/note-descriptions:alist))
             (symbol-string (save-excursion (read-string "symbol: ")))
             (symbol-cache-info (assoc symbol-string note-desc-XID-alist))
             (symbol-XID (if symbol-cache-info (cdr symbol-cache-info) (my/zk/note_XID:plain))))
        (let* ((note-symbol-title (with-temp-buffer
                                     ;; NOTE: use link s.t. name will be updated automatically
                                     (my/zk/insert-link 'note parent-XID parent-desc)
                                     (insert " :: symbol")
                                     (buffer-string)))
               ;; NOTE: remove link to use as desription
               (note-symbol-description (my/zk/note:derive-description-from-string
                                         note-symbol-title))
               (note-symbol-cache-info (assoc note-symbol-description note-desc-XID-alist))
               (note-symbol-XID (if note-symbol-cache-info (cdr note-symbol-cache-info) (my/zk/note_XID:plain)))
               (buffer (funcall (∘ #'find-file-noselect #'my/zk/note:path)
                                note-symbol-XID)))
          (with-current-buffer buffer
            (unless note-symbol-cache-info
              ;; new note note
              (my/zk/note:goto-beginning-of-first-content-line)
              (insert note-symbol-title)
              (insert (my/newline))
              (my/zk/insert-link:core 'is my/zk/XID/my_symbol)
              (insert (my/newline))
              (my/zk/insert-link 'context parent-XID parent-desc)
              (insert (my/newline))
              (save-buffer))
            (let* ((buffer (funcall (∘ #'find-file-noselect #'my/zk/note:path)
                                    symbol-XID)))
              (with-current-buffer buffer
                (if symbol-cache-info
                    (progn
                      ;; pre-existing note
                      (my/zk/note:goto-beginning-of-first-content-line)
                      (beginning-of-line 2)
                      (my/zk/insert-link      'is note-symbol-XID note-symbol-description)
                      (insert (my/newline))
                      (save-buffer))
                  (progn
                    ;; new-note
                    (my/zk/note:goto-beginning-of-first-content-line)
                    (insert symbol-string)
                    (insert (my/newline))
                    (my/zk/insert-link:core 'is my/zk/XID/my_symbol)
                    (insert (my/newline))
                    ;; BUG: duplicate links possible
                    (my/zk/insert-link      'is note-symbol-XID note-symbol-description)
                    (insert (my/newline))
                    (save-buffer))))))))))

  (defun my/zk/store-dir/find-note ()
    "when in a buffer of a file in the zk-store:
  `find-file' corresponding note"
    (interactive)
    (when-let ((cell (my/zk/parse-path (or (buffer-file-name) default-directory))))
      (when (eq (car cell) 'store)
        (cl-destructuring-bind
            (XID . rel-path)
            (my/split-string-once (cdr cell) (f-path-separator))
          (funcall (∘ #'find-file #'my/zk/note:path) XID)))))

  (defun my/zk/store-dir/yank-buffer-file-link:global ()
    "when in a buffer of a file in the zk-store:
  copy \"global link\" ⦓qualified with XID; type \"'store_zk\"⦔ to that file to clipboard."
    (interactive)
    (when-let ((cell (my/zk/parse-path (or (buffer-file-name) default-directory))))
      (when (eq (car cell) 'store)
        (cl-destructuring-bind
            (XID . rel-path)
            (my/split-string-once (cdr cell) (f-path-separator))
          (kill-new (my/zk/link:core 'store_zk
                                     XID
                                     (if (string-empty-p rel-path)
                                         "./"
                                       rel-path)))))))

  (defun my/zk/store-dir/yank-buffer-file-link:local ()
    "when in a buffer of a file in the zk-store:
  copy \"local link\" ⦓XID removed; type \"'store\"⦔ to that file to clipboard."
    (interactive)
    (when-let ((cell (my/zk/parse-path (or (buffer-file-name) default-directory))))
      (when (eq (car cell) 'store)
        (cl-destructuring-bind
            (XID . rel-path)
            (my/split-string-once (cdr cell) (f-path-separator))
          (kill-new (my/zk/link:core 'store
                                     (if (string-empty-p rel-path)
                                         "./"
                                       rel-path)))))))


  (if (not (my/zk/bootstrapped-p))
      (progn
        (message "my/zk: need to boostrap my/zk"))
    (progn
      ;; BUG: cannot use the following for daemon since ".gpg" files;
      ;;      require user interaction to decrypt
      ;; (when (or (daemonp) (y-or-n-p "zk: add notes without entry to cache file?"))
      ;;   (my/zk/cache/add-notes-without-entry-in-cache-file))
      (my/zk/clean-store-ln-dir)
      (my/zk/cache/ht:build-from-note)
      (my/customize 'kill-emacs-query-functions
                    (lambda ()
                      (my/zk/cache/ht:save-in-note)
                      t)
              :comment "save zk ht state when closing emacs. NOTE: only called for `save-buffers-kill-emacs' not `kill-emacs'"))))

(provide 'zk)
