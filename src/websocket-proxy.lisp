(defpackage sn.lisp-daemon.websocket-proxy
  (:use :cl :sn.lisp-daemon.websocket :sn.lisp-daemon.httpd :sn.lisp-daemon.swank-proxy))

(in-package :sn.lisp-daemon.websocket-proxy)

(defclass stream-usocket-websocket-swank-incomming
    (stream-usocket-websocket stream-usocket-swank-incomming)
  ((mode :accessor mode)))

(defparameter *j2s* (make-hash-table :test 'equalp))

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
(defparameter *json-converter-functions* '())
(export (defmacro defs2j (name params list &body body)
	  `(progn
	     (setq *json-converter-functions* (remove ',name *json-converter-functions* :key #'first))
	     (push `(,',name ,',list ,(lambda ,params ,@body)) *json-converter-functions*)
	     ',name)))

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
                       (loop :with done :for (symbol cmds handler) :in *json-converter-functions*
			  :when (find cmd cmds :test 'equal)
			  :do (unless done (funcall handler cmd body o) (setq done t))
			  :finally (unless done (yason:encode (list "raw" body) o))))))))))

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
