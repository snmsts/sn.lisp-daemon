(defpackage sn.lisp-daemon.websocket-proxy
  (:use :cl :sn.lisp-daemon.websocket :sn.lisp-daemon.httpd :sn.lisp-daemon.swank-proxy))

(in-package :sn.lisp-daemon.websocket-proxy)

(defclass stream-usocket-websocket-swank-incomming
    (stream-usocket-websocket stream-usocket-swank-incomming)
  ((mode :accessor mode)))

(defparameter *j2s* (make-hash-table :test 'equalp))
(defparameter *s2j* (make-hash-table))

(publish
 (defws get/websocket/swank
   :onmessage (lambda (socket opcode ar)
                (when (= opcode 1)
                  (let ((msg (yason:parse ar)))
                    (ignore-errors (apply (gethash (first msg) *j2s*) socket (rest msg))))))
   :onconnect (lambda (socket uri params)
                (declare (ignore uri params))
                (setf (mode socket) :json)
                (and (sn.lisp-daemon.swank-model:list-swanks)
                     (apply #'connect
                            (append (first (sn.lisp-daemon.swank-model:list-swanks))
                                    (list socket 'stream-usocket-swank-outgoing)))
                     t))
   :onclose (lambda (socket)
              (end (connecting socket)))
   :class stream-usocket-websocket-swank-incomming))

(defvar *tmp* 1)
(defmethod send-body ((socket stream-usocket-websocket-swank-incomming) length body)
  (let ((pos (position #\Space body)))
    (when sn.lisp-daemon.procs-ctrl::*debug*
      (format t "~S/~S~%" #+nil(type-of socket)
                          (mode socket)
                          body #+nil(subseq body 1 pos))
      (force-output))
    (send-frame socket 1
                (with-output-to-string (o)
                  (cond
                    ((equal (mode socket) :raw)
                     (yason:encode (list "raw" body) o))
                    ((equal (mode socket) :json)
                     (let ((cmd (subseq body 1 pos)))
                       (cond
                         ((equal cmd ":return")
                          (let ((match (nth-value
                                        1
                                        (cl-ppcre:scan-to-strings
                                         "\\(:\([^ ]*\)[^(]*\\(:\([^ ]*) (.*)\\) ([0-9]*)\\)$" body))))
			    (yason:encode (list "return"
                                                (list (aref match 1)
                                                      (aref match 2))
                                                (parse-integer(aref match 3)))
                                          o)))
                         ((find ":ping" '(":ping" ":write-string" ":presentation-end" ":presentation-start") :test 'equal)
			  (let* (*read-eval*
				 (*readtable* (copy-readtable))
				 (read (progn
					 (setf (readtable-case *readtable*) :preserve)
					 (mapcar (lambda (x) (if (symbolp x) (format nil "~S" x) x)) (read-from-string body)))))
			    (when sn.lisp-daemon.procs-ctrl::*debug* (format t "~S/~S~%" cmd (setq *tmp* read)))
			    (multiple-value-list
			     (ignore-errors (yason:encode
					     (list (subseq cmd 1) (rest read)) o)))))
                         (t (yason:encode (list "raw" body) o))))))))))

(defmacro defj2s (name params &body body)
  `(progn
     (setf (gethash ,(string-upcase name) *j2s*)
           (alexandria.0.dev:named-lambda
               ,(make-symbol (concatenate 
                              'string (string name) 
                              (string '#:.json->sexp)))
             ,params 
             ,@body))
     ',name))

(defmacro defs2j (key params &body body)
  `(progn
     (setf (gethash ,key *s2j*)
           ,params 
           ,@body)
     ',key))

(defj2s raw (socket msg)
  (send-body (connecting socket)
             (babel:string-size-in-octets msg :encoding :utf-8)
             msg))

(defj2s mode (socket method keywords)
  (when (equalp "set" method)
    (cond ((equalp keywords "json")
           (setf (mode socket) :json))
          ((equalp keywords "raw")
           (setf (mode socket) :raw)))))
