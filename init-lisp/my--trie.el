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
  ;; (message "my/trie/find-char %S %S" (char-to-string char)
  ;;          (my/trie/listify node))
  (char-table-range (my/trie/char-table node) char))
(defun my/trie/node:root-p (node)
  "is `node' a root node?
ECONDITION: `node' was created via `my/trie/node'"
  (null (my/trie/char node)))

;; TODO: tail recursive variant
(defun my/trie/internal-path:make (value string pos)
  "PRECONDITIONS: 
                  * (not (`null' `string'))
                  * `pos' = index in `string'; start of remaining substring
                  * `pos' < (`length' `string')"
  ;; (message "my/trie/internal-path:make %S %S %S" value string pos)
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
ECONDITIONS:  * see `my/trie/insert:suffix' 
TE: destructive"
  `(my/trie/insert:suffix ,root-node ,value ,string 0))

(defun my/trie/insert:suffix (node value string pos)
  "PRECONDITIONS: 
               * `node' is created via `my/trie/node'
                  i.e. not null
               * (not (null `string'))
               * `pos' = index in `string'; start of remaining substring
               * `pos' < (`length' `string')
substring' `string' `pos') may be empty
TE: destructive"
  ;; (message "my/trie/insert:suffix %S %S %S %S"
  ;;          (my/trie/listify node) value string pos)
  (if (>= pos (length string))
      (progn
        (setf (my/trie/value node) value)
        (setf (my/trie/string node) string))
    (let* ((c (aref string pos))
           (next (+ 1 pos))
           (cnode (my/trie/find-char c node)))
      ;; (message "my/trie/insert:suffix c    =%S" (char-to-string c))
      ;; (message "my/trie/insert:suffix cnode=%S" (my/trie/listify cnode))
      (if cnode
          (my/trie/insert:suffix cnode value string next)
        (let ((cnode (if (>= next (length string))
                         (my/trie/node c string value nil)
                       (my/trie/internal-path:make value string pos))))
          ;; (message "my/trie/insert:suffix cnode←%S" (my/trie/listify cnode))
          (set-char-table-range (my/trie/char-table node) c cnode)))))
  node)

(defmacro my/trie/search (root-node string)
  " = (`my/trie/search:suffix' `root-node' `string' 0)
ECONDITIONS: see `my/trie/search:suffix'
TE: destructive"
  `(my/trie/search:suffix ,root-node ,string 0))

(defun my/trie/search:suffix (node string pos)
  "PRECONDITIONS: 
               * `node' is created via `my/trie/node'
                  i.e. not null
               * (not (null `string'))

               * `pos' < (`length' `string')
substring' `string' `pos') may be empty
   `string' is found in trie starting at `node' then return (`my/trie/value' `node').
SE return nil.
TE: destructive"
  ;; (message "my/trie/search:suffix %S %S %S"
  ;;          (my/trie/listify node) string pos)
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
substring' `string' `pos') may be empty
arch for nearest ancestor of `string' in `node' and return it.
nce trie is non-empty and `string' is non-empty we always return
node (and never nil).
DO: use in `my/trie/search:suffix'
DO: use in `my/trie/insert:suffix'
TE: destructive"
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
  (list
   (cons
    (message "my/trie/test path '%s'" "a")
    (my/trie/listify (my/trie/internal-path:make "A" "a" 0)))
   (cons
    (message "my/trie/test path '%s'" "abc")
    (my/trie/listify (my/trie/internal-path:make "ABC" "abc" 0)))
   (cons
    (message "my/trie/test init '%s'" "")
    (my/trie/listify (my/trie/init-with-first-string nil "")))
   (cons
    (message "my/trie/test init '%s'" "abc")
    (my/trie/listify (my/trie/init-with-first-string "ABC" "abc")))))

(defun my/trie/test2 ()
  (list
    (format "my/trie/test init '%s'" "abc")
    (let ((root (my/trie/init-with-first-string "ABC" "abc")))
      (list
            (message "root = %S" (my/trie/listify root))
            (cons
             (message "my/trie/test insert-at-root '%s'" "d")
             (my/trie/listify (my/trie/insert root "D" "d" )))
            (cons
             (message "my/trie/test insert-at-root '%s'" "abcdefg")
             (my/trie/listify (my/trie/insert root "ABCDEFG" "abcdefg")))
            (cons
             (message "my/trie/test insert-at-root '%s'" "ab")
             (my/trie/listify (my/trie/insert root "AB" "ab")))
            (cons
             (message "my/trie/search root '%s'" "d")
             (my/trie/search root "d"))
            (cons
             (message "my/trie/search root '%s'" "abcdefg")
             (my/trie/search root "abcdefg"))
            (cons
             (message "my/trie/search root '%s'" "FAIL")
             (my/trie/search root "FAIL"))
            ))))

(provide 'my--trie)
