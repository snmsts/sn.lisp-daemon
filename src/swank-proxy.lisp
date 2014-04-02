(defpackage sn.lisp-daemon.swank-proxy
  (:use :cl :sn.lisp-daemon.httpd)
  (:export :stream-usocket-swank-incomming
   :stream-usocket-swank-outgoing :connect :connecting :send-body))

(in-package :sn.lisp-daemon.swank-proxy)

(defclass stream-usocket-determin (stream-usocket-with-state) ())

(defclass stream-usocket-swank-incomming (stream-usocket-with-state) 
  ((coding :accessor coding)
   (connecting :accessor connecting)))

(defclass stream-usocket-swank-outgoing (stream-usocket-swank-incomming)
  ())

(setf *accept-class* 'stream-usocket-determin)

(defun connect (port pid host incoming &optional (accept-class *accept-class*))
  (let ((socket (usocket:socket-connect (if pid "localhost" host) port :element-type '(unsigned-byte 8))))
    (change-class socket accept-class)
    (setf (coding socket) nil
          (connecting socket) incoming
          (connecting incoming) socket)
    (push socket *sockets*)
    t))

(defmethod read-body ((socket stream-usocket-swank-incomming) length)
  (cond ((null (ignore-errors (coding socket)))
         (trivial-utf-8:read-utf-8-string (usocket:socket-stream socket) :byte-length length))))

(defmethod send-body ((socket stream-usocket-swank-incomming) length body)
  (when sn.lisp-daemon.procs-ctrl::*debug*
    (format t "~S:~S~%" (type-of socket) body)
    (force-output))
  (write-sequence (babel:string-to-octets (format nil "~6,'0x" length)) (usocket:socket-stream socket))
  (write-sequence (babel:string-to-octets body :encoding :utf-8) (usocket:socket-stream socket))
  (force-output (usocket:socket-stream socket)))

(defmethod dispatch ((socket stream-usocket-determin))
  (handler-case
      (let* ((swank t)
             (in (usocket:socket-stream socket))
             (buff (loop :repeat 6
                      :for c := (read-byte in)
                      :do (setq swank (and swank (digit-char-p (code-char c) 16)))
                      :collect c)))
        (change-class socket (if swank 'stream-usocket-swank-incomming
                                 'sn.lisp-daemon.httpd:stream-usocket-with-state))
        (if swank
            (let* ((length (parse-integer (coerce (mapcar #'code-char buff) 'string) :radix 16))
                   (body (read-body socket length)))
              (if (and (sn.lisp-daemon.swank-model:list-swanks)
                       (ignore-errors 
                        (apply #'connect 
                               (append (first (sn.lisp-daemon.swank-model:list-swanks))
                                       (list socket 'stream-usocket-swank-outgoing)))))
                  (send-body (connecting socket) length body)
                  (end socket)))
            (push (coerce (append (mapcar #'code-char buff) 
                                  (loop :for c := (read-byte in)
                                     :while (/= c #.(char-code #\Newline))
                                     :collect (code-char c)))'string)
                  (sn.lisp-daemon.httpd::buffer socket))))
    (end-of-file ()
      (end (connecting socket))
      (end socket))))

(defmethod dispatch ((socket stream-usocket-swank-incomming))
  (handler-case
      (let* ((length (parse-integer (coerce (loop :with in := (usocket:socket-stream socket)
                                               :repeat 6
                                               :for c := (read-byte in)
                                               :collect (code-char c)) 'string) :radix 16))
             (body (read-body socket length)))
        (send-body (connecting socket) length body))
    (end-of-file ()
      (end (connecting socket))
      (end socket))))
