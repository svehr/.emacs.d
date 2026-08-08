;; my/trie:
;;  * destructive insert operations

(defmacro my/trie/char-table (node)
  `(car ,node))

(defmacro my/trie/string (node)
  `(cadr ,node))

(defmacro my/trie/char (node)
  `(caddr ,node))

(defmacro my/trie/value (node)
  `(cdddr ,node))

(defun my/trie/node (char &optional string value children-list)
  "children-list is a list of nodes created via `my/trie/node'"
  (let ((table (make-char-table nil nil)))
    (dolist (child children-list)
       (set-char-table-range table (my/trie/char child) child))
    (cons table (cons string (cons char value)))))

(defun my/trie/find-char (char node)
  "children-list is a list of nodes created via `my/trie/node'"
  (char-table-range (my/trie/char-table node) char))

(defun my/trie/node:root-p (node)
  "is `node' a root node?
PRECONDITION: `node' was created via `my/trie/node'"
  (null (my/trie/char node)))

;; TODO: tail recursive variant
(defun my/trie/internal-path:make (value string pos)
  "PRECONDITIONS: 
                  * (not (`null' `string'))
                  * `pos' = index in `string'; start of remaining substring
                  * `pos' < (`length' `string')"
  (let ((c (aref string pos))
        (next (+ 1 pos)))
    (if (>= next (length string))
        (my/trie/node c string value nil)
      (my/trie/node c nil nil (list (my/trie/internal-path:make value string next))))))

(defun my/trie/init-with-first-string (value string)
  "PRECONDITIONS: * (not (null `string'))"
  (if (string-empty-p string)
      (my/trie/node nil "" value nil)
    (my/trie/node nil nil nil (list (my/trie/internal-path:make value string 0)))))

(defmacro my/trie/insert (root-node value string)
  " = (`my/trie/insert:suffix' `root-node' `string' 0)
PRECONDITIONS:  * see `my/trie/insert:suffix'
NOTE: destructive"
  `(my/trie/insert:suffix ,root-node ,value ,string 0))

(defun my/trie/insert:suffix (node value string pos)
  "PRECONDITIONS: 
               * `node' is created via `my/trie/node'
                  i.e. not null
               * (not (null `string'))
               * `pos' = index in `string'; start of remaining substring
               * `pos' < (`length' `string')
(`substring' `string' `pos') may be empty
NOTE: destructive"
  (if (>= pos (length string))
      (progn
        (setf (my/trie/value node) value)
        (setf (my/trie/string node) string))
    (let* ((c (aref string pos))
           (next (+ 1 pos))
           (cnode (my/trie/find-char c node)))
      (if cnode
          (my/trie/insert:suffix cnode value string next)
        (let ((cnode (if (>= next (length string))
                         (my/trie/node c string value nil)
                       (my/trie/internal-path:make value string pos))))
          (set-char-table-range (my/trie/char-table node) c cnode)))))
  node)

(defmacro my/trie/search (root-node string)
  " = (`my/trie/search:suffix' `root-node' `string' 0)
PRECONDITIONS: see `my/trie/search:suffix'
NOTE: destructive"
  `(my/trie/search:suffix ,root-node ,string 0))

(defun my/trie/search:suffix (node string pos)
  "PRECONDITIONS: 
               * `node' is created via `my/trie/node'
                  i.e. not null
               * (not (null `string'))

               * `pos' < (`length' `string')
(`substring' `string' `pos') may be empty
IF   `string' is found in trie starting at `node' then return (`my/trie/value' `node').
ELSE return nil.
NOTE: destructive"
  (if (>= pos (length string))
      (when (my/trie/string node)
        (my/trie/value node))
    (let* ((c (aref string pos))
           (next (+ 1 pos))
           (cnode (my/trie/find-char c node)))
      (when cnode
        (my/trie/search:suffix cnode string next)))))

(defun my/trie/search-nearest-ancestor:suffix (node string pos)
  "PRECONDITIONS:
               * `node' is created via `my/trie/node'
                  i.e. not null
               * (not (null `string'))
               * (not (`string-empty-p' `string'))
                 * empty string is in root node; if it is there
               * `pos' < (`length' `string')
(`substring' `string' `pos') may be empty
Search for nearest ancestor of `string' in `node' and return it.
Since trie is non-empty and `string' is non-empty we always return
a node (and never nil).
TODO: use in `my/trie/search:suffix'
TODO: use in `my/trie/insert:suffix'
NOTE: destructive"
  (let* ((c (aref string pos))
         (next (+ 1 pos))
         (cnode (my/trie/find-char c node)))
    (if cnode
        (my/trie/search:nearest-ancestor cnode string next)
      node)))


(defun my/trie/listify-char-table (char-table)
  ;; adapted from https://www.gnu.org/software/emacs/manual/html_node/elisp/Char_002dTables.html
  (when char-table
    (let (accumulator)
      (map-char-table
       #'(lambda (key value)
           (setq accumulator
                 (cons (list
                        (when key (char-to-string key))
                        (my/trie/listify value))
                       accumulator)))
       char-table)
      accumulator)))

(defun my/trie/listify (node)
  (when node
    (list :char       (let ((c (my/trie/char node)))
                        (when c (char-to-string c)))
          :string     (my/trie/string node)
          :value      (my/trie/value node)
          :char-table (my/trie/listify-char-table (my/trie/char-table node)))))

(defun my/trie/test ()
  (progn
    (cl-assert
     (equal
      (my/trie/listify (my/trie/internal-path:make "A" "a" 0))
      '(:char "a" :string "a" :value "A" :char-table nil)))
    (cl-assert
     (equal
      (my/trie/listify (my/trie/internal-path:make "ABC" "abc" 0))
      '(:char "a" :string nil :value nil :char-table
              (("b"
                (:char "b" :string nil :value nil :char-table
                       (("c"
                         (:char "c" :string "abc" :value "ABC" :char-table
                                nil)))))))))
    (cl-assert
     (equal
      (my/trie/listify (my/trie/init-with-first-string nil ""))
      '(:char nil :string "" :value nil :char-table nil)))
    (cl-assert
     (equal
      (my/trie/listify (my/trie/init-with-first-string "ABC" "abc"))
      '(:char nil :string nil :value nil :char-table
              (("a"
                (:char "a" :string nil :value nil :char-table
                       (("b"
                         (:char "b" :string nil :value nil :char-table
                                (("c"
                                  (:char "c" :string "abc" :value "ABC"
                                         :char-table nil))))))))))))))

(defun my/trie/test2 ()
  (let ((root (my/trie/init-with-first-string "ABC" "abc")))
    (progn
      (cl-assert
       (equal (my/trie/listify (my/trie/insert root "D" "d" ))
              '(:char nil :string nil :value nil
                      :char-table
                      (("d" (:char "d" :string "d" :value "D" :char-table nil))
                       ("a"
                        (:char "a" :string nil :value nil :char-table
                               (("b"
                                 (:char "b" :string nil :value nil :char-table
                                        (("c"
                                          (:char "c" :string "abc" :value "ABC"
                                                 :char-table nil))))))))))))
      (cl-assert
       (equal (my/trie/listify (my/trie/insert root "ABCDEFG" "abcdefg"))
              '(:char nil :string nil :value nil
                      :char-table
                      (("d" (:char "d" :string "d" :value "D" :char-table nil))
                       ("a"
                        (:char "a" :string nil :value nil :char-table
                               (("b"
                                 (:char "b" :string nil :value nil :char-table
                                        (("c"
                                          (:char "c" :string "abc" :value "ABC"
                                                 :char-table
                                                 (("d"
                                                   (:char "d" :string nil :value nil
                                                          :char-table
                                                          (("e"
                                                            (:char "e" :string nil :value
                                                                   nil :char-table
                                                                   (("f"
                                                                     (:char "f" :string
                                                                            nil :value
                                                                            nil
                                                                            :char-table
                                                                            (("g"
                                                                              (:char "g"
                                                                                     :string
                                                                                     "abcdefg"
                                                                                     :value
                                                                                     "ABCDEFG"
                                                                                     :char-table
                                                                                     nil))))))))))))))))))))))))
      (cl-assert
       (equal (my/trie/listify (my/trie/insert root "AB" "ab"))
              '(:char nil :string nil :value nil
                      :char-table
                      (("d" (:char "d" :string "d" :value "D" :char-table nil))
                       ("a"
                        (:char "a" :string nil :value nil :char-table
                               (("b"
                                 (:char "b" :string "ab" :value "AB" :char-table
                                        (("c"
                                          (:char "c" :string "abc" :value "ABC"
                                                 :char-table
                                                 (("d"
                                                   (:char "d" :string nil :value nil
                                                          :char-table
                                                          (("e"
                                                            (:char "e" :string nil :value
                                                                   nil :char-table
                                                                   (("f"
                                                                     (:char "f" :string
                                                                            nil :value
                                                                            nil
                                                                            :char-table
                                                                            (("g"
                                                                              (:char "g"
                                                                                     :string
                                                                                     "abcdefg"
                                                                                     :value
                                                                                     "ABCDEFG"
                                                                                     :char-table
                                                                                     nil))))))))))))))))))))))))
      (cl-assert (string-equal (my/trie/search root "d") "D"))
      (cl-assert (string-equal (my/trie/search root "d") "D"))
      (cl-assert (string-equal (my/trie/search root "abcdefg") "ABCDEFG"))
      (cl-assert (string-equal (my/trie/search root "abc") "ABC")))))

(provide 'my--trie)
