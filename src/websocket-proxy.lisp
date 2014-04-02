(defpackage sn.lisp-daemon.websocket-proxy
  (:use :cl :sn.lisp-daemon.websocket :sn.lisp-daemon.httpd :sn.lisp-daemon.swank-proxy))

(in-package :sn.lisp-daemon.websocket-proxy)

(defclass stream-usocket-websocket-swank-incomming
    (stream-usocket-websocket stream-usocket-swank-incomming)
  ())

(publish
 (defws get/websocket/swank 
   :onmessage (lambda (socket opcode ar)
                (when (= opcode 1)
                  (send-body (connecting socket)
                             (babel:string-size-in-octets ar :encoding :utf-8)
                             ar)))
   :onconnect (lambda (socket uri params)
                (declare (ignore uri params))
                (change-class socket 'stream-usocket-websocket-swank-incomming)
                (and (sn.lisp-daemon.swank-model:list-swanks)
                     (apply #'connect
                            (append (first (sn.lisp-daemon.swank-model:list-swanks))
                                    (list socket 'stream-usocket-swank-outgoing)))
                     t))
   :onclose (lambda (socket)
              (end (connecting socket)))))

(defmethod send-body ((socket stream-usocket-websocket-swank-incomming) length body)
  (when sn.lisp-daemon.procs-ctrl::*debug*
    (format t "~S:~S~%" (type-of socket) body)
    (force-output))
  (send-frame socket 1 body))

(defparameter *j2s* (make-hash-table :test 'equalp))
(defparameter *s2j* (make-hash-table))

(defmacro defj2s (name params &body body)
  `(progn
     (setf (gethash ,(string-upcase name) *j2s*)
           (lambda ,params 
             ,@body))
     ',name))

(defmacro defs2j (key params &body body)
  `(progn
     (setf (gethash ,key *s2j*)
           (lambda ,params 
             ,@body))
     ',name))
