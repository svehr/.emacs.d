(require 'ucs-normalize)

(my/defvar my/hangeul/doc-string
           "
# 19 leading consonants
ㄱ 3131 | ᄀ 1100 g  | g
ㄲ 3132 | ᄁ 1101 kk | gg
ㄴ 3134 | ᄂ 1102 n  | n
ㄷ 3137 | ᄃ 1103 d  | d
ㄸ 3138 | ᄄ 1104 tt | dd
ㄹ 3139 | ᄅ 1105 r  | l
ㅁ 3141 | ᄆ 1106 m  | m
ㅂ 3142 | ᄇ 1107 b  | b
ㅃ 3143 | ᄈ 1108 pp | bb
ㅅ 3145 | ᄉ 1109 s  | s
ㅆ 3146 | ᄊ 110a ss | ss
ㅇ 3147 | ᄋ 110b '  | x
ㅈ 3148 | ᄌ 110c j  | j
ㅉ 3149 | ᄍ 110d jj | jj
ㅊ 314a | ᄎ 110e ch | c
ㅋ 314b | ᄏ 110f k  | k
ㅌ 314c | ᄐ 1110 t  | t
ㅍ 314d | ᄑ 1111 p  | p
ㅎ 314e | ᄒ 1112 h  | h

# 21 vowels
ㅑ 3151 | ya   |  ᅣ 1163 ya
ㅒ 3152 | yai  |  ᅤ 1164 yae
ㅕ 3155 | yq   |  ᅧ 1167 yeo
ㅖ 3156 | yqi  |  ᅨ 1168 ye
ㅛ 315b | yo   |  ᅭ 116d yo
ㅠ 3160 | yu   |  ᅲ 1172 yu
ㅣ 3163 | i    |  ᅵ 1175 i
ㅏ 314f | a    |  ᅡ 1161 a
ㅐ 3150 | ai   |  ᅢ 1162 ae
ㅓ 3153 | q    |  ᅥ 1165 eo
ㅔ 3154 | qi   |  ᅦ 1166 e
ㅡ 3161 | v    |  ᅳ 1173 eu
ㅢ 3162 | vi   |  ᅴ 1174 ui
ㅗ 3157 | o    |  ᅩ 1169 o
ㅘ 3158 | oa   |  ᅪ 116a wa
ㅙ 3159 | oai  |  ᅫ 116b wae
ㅚ 315a | oi   |  ᅬ 116c oe
ㅜ 315c | u    |  ᅮ 116e u
ㅝ 315d | uq   |  ᅯ 116f wo
ㅞ 315e | uqi  |  ᅰ 1170 we
ㅟ 315f | ui   |  ᅱ 1171 wi

# 27 trailing consonants
ㄱ 3131 | ᆨ k  11a8 | g
ㄲ 3132 | ᆩ k  11a9 | gg
ㄳ 3133 | ᆪ /  11aa | gs
ㄴ 3134 | ᆫ n  11ab | n
ㄵ 3135 | ᆬ /  11ac | nj
ㄶ 3136 | ᆭ /  11ad | nh
ㄷ 3137 | ᆮ t  11ae | d
ㄹ 3139 | ᆯ l  11af | l
ㄺ 313a | ᆰ /  11b0 | lg
ㄻ 313b | ᆱ /  11b1 | lm
ㄼ 313c | ᆲ /  11b2 | lb
ㄽ 313d | ᆳ /  11b3 | ls
ㄾ 313e | ᆴ /  11b4 | lt
ㄿ 313f | ᆵ /  11b5 | lp
ㅀ 3140 | ᆶ /  11b6 | lh
ㅁ 3141 | ᆷ m  11b7 | m
ㅂ 3142 | ᆸ b  11b8 | b
ㅄ 3144 | ᆹ /  11b9 | bs
ㅅ 3145 | ᆺ t  11ba | s
ㅆ 3146 | ᆻ t  11bb | ss
ㅇ 3147 | ᆼ ng 11bc | x
ㅈ 3148 | ᆽ t  11bd | j
ㅊ 314a | ᆾ t  11be | c
ㅋ 314b | ᆿ k  11bf | k
ㅌ 314c | ᇀ t  11c0 | t
ㅍ 314d | ᇁ p  11c1 | p
ㅎ 314e | ᇂ t  11c2 | h
")

(defmacro my/with-char-parser (string-sym length-sym next-sym &rest forms)
  "TODO: docstring"
  (declare (indent 1))
  `(macrolet
       ;; NOTE: free variables in the following: '_next' , 'l'
       ;;       will be introduced in child-expression 'let'
       ((next-char-lookahead ()
                             '(when (< ,next-sym ,length-sym)
                                (aref ,string-sym ,next-sym)))
        (inc_pos ()
                 '(setq ,next-sym (1+ ,next-sym)))
        (next-char ()
                   '(when (< ,next-sym ,length-sym)
                      (let ((i ,next-sym))
                        (setq ,next-sym (1+ ,next-sym))
                        (aref ,string-sym i))))
        (guarded-if_next_= ;; lookahead to next char (return NIL if it does not exist)
         (char if-out else-out)
         `(when-let ((n (next-char-lookahead)))
            (if (= n ,char)
                (progn
                  (inc_pos)
                  ,if-out)
              ,else-out)))
        (if_next_exists_and_= ;; lookahead to next char (return ELSE-OUT if it does not exist)
         (char if-out else-out)
         `(let ((n (next-char-lookahead)))
            (if (and n (= n ,char))
                (progn
                  (inc_pos)
                  ,if-out)
              ,else-out))))
     (let ((,length-sym (length ,string-sym))
           (,next-sym  0))
       ,@forms)))

(my/defun my/hangeul/latin-syllable-to-hangeul-syllable (latin-syllable)
  "
input: c.f. `my/hangeul/doc-string'
RETURNS (cons RESULT SUCCESS-t-OR-nil)
  SUCCESS-t-OR-nil == t   ⇒ RESULT == hangeul syllable from 'hangul syllables' unicode block
  SUCCESS-t-OR-nil == nil ⇒ RESULT == latin-syllable
NOTE: / TODO: additional chars after valid \"max length latin-syllable\" parsed
              are ignored
c.f. `my/hangeul/doc-string'"
  (my/with-char-parser
      latin-syllable length next
      (let
          ((hangeul-syllable
            (when-let
                ((c (next-char)))
              (when-let
                  ((initial-part
                    (cond
                     ((= c ?g)
                      (guarded-if_next_= ?g #x1101 #x1100))
                     ((= c ?n)
                      #x1102)
                     ((= c ?d)
                      (guarded-if_next_= ?d #x1104 #x1103))
                     ((= c ?l)
                      #x1105)
                     ((= c ?m)
                      #x1106)
                     ((= c ?b)
                      (guarded-if_next_= ?b #x1108 #x1107))
                     ((= c ?s)
                      (guarded-if_next_= ?s #x110a #x1109))
                     ((= c ?x)
                      #x110b)
                     ((= c ?j)
                      (guarded-if_next_= ?j #x110d #x110c))
                     ((= c ?c)
                      #x110e)
                     ((= c ?k)
                      #x110f)
                     ((= c ?t)
                      #x1110)
                     ((= c ?p)
                      #x1111)
                     ((= c ?h)
                      #x1112)
                     (t
                      nil)
                     )))
                ;; (message "init: %S" initial-part)
                (when-let*
                    ((c (next-char))
                     (middle-part
                      (cond
                       ((= c ?y)
                        (when-let ((c (next-char-lookahead)))
                          ;; "y" alone not valid
                          (cond
                           ((= c ?a)
                            (inc_pos)
                            (if_next_exists_and_= ?i #x1164 #x1163))
                           ((= c ?q)
                            (inc_pos)
                            (if_next_exists_and_= ?i #x1168 #x1167))
                           ((= c ?o)
                            (inc_pos)
                            #x116d)
                           ((= c ?u)
                            (inc_pos)
                            #x1172)
                           (t
                            nil))))
                       ((= c ?i)
                        #x1175)
                       ((= c ?a)
                        (if_next_exists_and_= ?i #x1162 #x1161))
                       ((= c ?q)
                        (if_next_exists_and_= ?i #x1166 #x1165))
                       ((= c ?v)
                        (if_next_exists_and_= ?i #x1174 #x1173))
                       ((= c ?o)
                        (if-let ((c (next-char-lookahead)))
                            (cond
                             ((= c ?a)
                              (inc_pos)
                              (if_next_exists_and_= ?i #x116b #x116a))
                             ((= c ?i)
                              (inc_pos)
                              #x116c)
                             (t
                              #x1169))
                          #x1169))
                       ((= c ?u)
                        (if-let ((c (next-char-lookahead)))
                            (cond
                             ((= c ?q)
                              (inc_pos)
                              (if_next_exists_and_= ?i #x1170 #x116f))
                             ((= c ?i)
                              (inc_pos)
                              #x1171)
                             (t
                              #x116e))
                          #x116e))
                       (t
                        nil)
                       )))
                  ;; (message "mid: %S" middle-part)
                  (let*
                      ((c (next-char))
                       (final-part
                        (when c
                          (cond
                           ((= c ?g)
                            (if-let ((c (next-char)))
                                (cond
                                 ((= c ?g)
                                  #x11a9)
                                 ((= c ?s)
                                  #x11aa)
                                 (t
                                  nil))
                              #x11a8))
                           ((= c ?n)
                            (if-let ((c (next-char)))
                                (cond
                                 ((= c ?j)
                                  #x11ac)
                                 ((= c ?h)
                                  #x11ad)
                                 (t
                                  nil))
                              #x11ab))
                           ((= c ?d)
                            (if-let ((c (next-char)))
                                nil
                              #x11ae))
                           ((= c ?l)
                            (if-let ((c (next-char)))
                                (cond
                                 ((= c ?g)
                                  #x11b0)
                                 ((= c ?m)
                                  #x11b1)
                                 ((= c ?b)
                                  #x11b2)
                                 ((= c ?s)
                                  #x11b3)
                                 ((= c ?t)
                                  #x11b4)
                                 ((= c ?p)
                                  #x11b5)
                                 ((= c ?h)
                                  #x11b6)
                                 (t
                                  nil))
                              #x11af))
                           ((= c ?m)
                            (if-let ((c (next-char)))
                                nil
                              #x11b7))
                           ((= c ?b)
                            (if-let ((c (next-char)))
                                (cond
                                 ((= c ?s)
                                  #x11b9)
                                 (t
                                  nil))
                              #x11b8))
                           ((= c ?s)
                            (if-let ((c (next-char)))
                                (cond
                                 ((= c ?s)
                                  #x11bb)
                                 (t
                                  nil))
                              #x11ba))
                           ((= c ?x)
                            (if-let ((c (next-char)))
                                nil
                              #x11bc))
                           ((= c ?j)
                            (if-let ((c (next-char)))
                                nil
                              #x11bd))
                           ((= c ?c)
                            (if-let ((c (next-char)))
                                nil
                              #x11be))
                           ((= c ?k)
                            (if-let ((c (next-char)))
                                nil
                              #x11bf))
                           ((= c ?t)
                            (if-let ((c (next-char)))
                                nil
                              #x11c0))
                           ((= c ?p)
                            (if-let ((c (next-char)))
                                nil
                              #x11c1))
                           ((= c ?h)
                            (if-let ((c (next-char)))
                                nil
                              #x11c2))
                           (t
                            nil)))))
                    (when (or (null c) final-part)
                      ;;   not having final-part is correct
                      ;;   or we successfully parsed a final-part ⦓and thus all parts⦔
                      ;; ⇝ success
                      (ucs-normalize-NFC-string
                       (apply #'string
                              (if final-part
                                  (list initial-part middle-part final-part)
                                (list initial-part middle-part)))))))))))
        (if hangeul-syllable
            (cons hangeul-syllable t)
          (cons latin-syllable nil)))))

(lexical-let ((compatibility-jamo-parse-tree
               '((?g #x3131 (?g #x3132) (?s #x3133))
                 (?n #x3134 (?j #x3135) (?h #x3136))
                 (?d #x3137 (?d #x3138))
                 (?l #x3139 (?g #x313a) (?m #x313b) (?b #x313c) (?s #x313d) (?t #x313e) (?p #x3134) (?h #x3140))
                 (?m #x3141)
                 (?b #x3142 (?b #x3143) (?s #x3144))
                 (?s #x3145 (?s #x3146))
                 (?x #x3147)
                 (?j #x3148 (?j #x3149))
                 (?c #x314a)
                 (?k #x314b)
                 (?t #x314c)
                 (?p #x314d)
                 (?h #x314e)
                 (?y nil    (?a #x3151 (?i #x3152))
                     (?q #x3155 (?i #x3156))
                     (?o #x315b)
                     (?u #x3160))
                 (?i #x3163)
                 (?a #x314f (?i #x3150))
                 (?q #x3153 (?i #x3154))
                 (?v #x3161 (?i #x3162))
                 (?o #x3157 (?a #x3158 (?i #x3159))
                     (?i #x315a))
                 (?u #x315c (?q #x315d (?i #x315e))
                     (?i #x315f)))))
  ;; compatibility-jamo-parse-tree has format LIST where
  ;;   LIST =   (CHAR RESULT) ⧺ LIST
  ;;            ⦗cddr of a LIST can be a LIST⦘
  ;;          | nil
  ;; (CHAR RESULT nil) is NOT a valid LIST
  ;; e.g. the following is a valid LIST:
  ;;   '((?g "g" (?g "gg") (?x "gx"))
  ;;     (?n "n")
  ;;     (?d "d" (?d "dd"))
  ;;     (?x nil (?y nil (?z "xyz))))
  (cl-labels ((expand (input-list)
                ;; NOTE: contains free variables 'string' , 'i' and 'l'
                (when input-list
                  `(if (= i l)
                       nil
                     (progn
                       (lexical-let ((c (aref string i)))
                         (cond
                          ,@(mapcar
                             (lambda (x)
                               `((= c ,(car x))
                                 ;; NOTE: we could also increase i only for "recursion"
                                 ;;       but we want to return index of the first char after
                                 ;;       the part we used
                                 ;; DEFERRED:TODO: ?: avoid this let
                                 (lexical-let ((i (1+ i)))
                                   (or ,(expand (cddr x))
                                       ,(when (cadr x)
                                          `(cons ,(cadr x) i))))))
                             input-list)
                          (t
                           nil))))))))
    (defalias 'my/hangeul/latin-letter-to-hangeul-compatibility-jamo
      `(lambda (string)
         (lexical-let ((l (length string))
                       (i 0))
           ,(expand compatibility-jamo-parse-tree)))
      "input:  latin string (c.f. `my/hangeul/doc-string')
RETURNS: nil | (cons HANGEUL-COMPATIBILITY-JAMO LENGTH-OF-USED-INPUT-STRING)
               where HANGEUL-COMPATIBILITY-JAMO from 'hangul compatibility jamo' unicode block
NOTE: / TODO: additional chars after valid \"max length latin-syllable\" parsed are ignored in output;
              can still be processed further due to length part of result tho
c.f. `my/hangeul/doc-string'
NOTE: outer 'macrolet' definitions")))


(my/defun my/hangeul/input ()
  "NOTE: / TODO:  in case ';' is at end of input and translating
\"latin syllable\" preceding this ';' fails: the ';' will be omitted in the output.
aborts on first error"
  (interactive)
  (let ((read-info (my/read-from-minibuffer "latin-syllables separated by ';'")))
    (when read-info
      (cl-destructuring-bind (input pmin p pmax) read-info
        (let ((continue t)
              (beg 0)
              (output nil)
              (l (length input)))
          (while (and continue (< beg l))
            (let ((end (or (cl-position ?\; input :start beg)
                           l)))
              (if (= ?z (aref input beg))
                  (if-let ((parse-result
                            (my/hangeul/latin-letter-to-hangeul-compatibility-jamo
                             (substring input (1+ beg) end))))
                      (setq output (concat output (char-to-string (car parse-result))))
                    (setq continue nil))
                (let ((trans (my/hangeul/latin-syllable-to-hangeul-syllable (substring input beg end))))
                  (if (cdr trans)
                      (setq output (concat output (car trans)))
                    (setq continue nil))))
              (when continue
                (setq beg (if (= l end)
                              end
                            ;; (= ?\; (aref input end))
                            (1+ end))))))
          (when output
            (insert output))
          (unless continue
            (insert (substring input beg))))))))


(provide 'my--hangeul)
