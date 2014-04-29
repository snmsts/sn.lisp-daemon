(defpackage sn.lisp-daemon.websocket-proxy-sexp2js
  (:use :cl :sn.lisp-daemon.websocket-proxy))

(in-package :sn.lisp-daemon.websocket-proxy-sexp2js)

(defs2j :return (cmd body o) 
    (":return")
  (declare (ignore cmd))
  (let ((match (nth-value
		1
		(cl-ppcre:scan-to-strings
		 "\\(:\([^ ]*\)[^(]*\\(:\([^ ]*) (.*)\\) ([0-9]*)\\)$" body))))
    (yason:encode (list "return"
			(list (aref match 1)
			      (aref match 2))
			(parse-integer(aref match 3)))
		  o)))
(defvar *tmp* nil)

(defs2j :read (cmd body o)
    (":ping" ":write-string" ":presentation-end" ":presentation-start")
  (let* (*read-eval*
	 (*readtable* (copy-readtable))
	 (read (progn
		 (setf (readtable-case *readtable*) :preserve)
		 (mapcar (lambda (x) (if (symbolp x) (format nil "~S" x) x)) (read-from-string body)))))
    (when sn.lisp-daemon.procs-ctrl::*debug* (format t "~S/~S~%" cmd (setq *tmp* read)))
    (multiple-value-list
     (ignore-errors (yason:encode
		     (list (subseq cmd 1) (rest read)) o)))))

(defs2j :debug (cmd body o)
    (":debug" ":debug-activate")
  (let* (*read-eval*
	 (*readtable* (copy-readtable))
	 (read (progn
		 (mapcar (lambda (x) (if (symbolp x) (format nil "~S" x) x)) (read-from-string body)))))
    (yason:encode (list (subseq cmd 1) (cdr read)) o)))


