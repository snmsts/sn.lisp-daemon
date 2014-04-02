(defpackage sn.lisp-daemon.websocket
  (:use :cl :sn.lisp-daemon.httpd)
  (:export :stream-usocket-websocket :send-frame :defws))
(in-package :sn.lisp-daemon.websocket)

(defclass stream-usocket-websocket (stream-usocket-with-state) 
  ((onmessage :accessor onmessage)
   (onclose :accessor onclose)))

(sn.lisp-daemon.httpd:response websocket-accept 101 "Switching Protocols" t t)

(defun send-frame (socket opcode payload &optional (fin t))
  (setq payload (labels ((conv (payload)
                           (etypecase payload
                             (list (flexi-streams:with-output-to-sequence (out)
                                     (dolist (e payload)
                                       (write-sequence (conv e) out))))
                             (string (babel:string-to-octets payload :encoding :utf-8))
                             (simple-array payload))))
                  (conv payload)))
  (let ((len (length payload)))
    (write-sequence (flexi-streams:with-output-to-sequence (out)
                      (write-byte (+ (if fin #x80 0) (logand opcode #xf)) out)
                      (if (> 126 len) (write-byte len out)
                          (let ((4byte (<= (ash 1 16) len)))
                            (write-byte (if 4byte 127 126) out)
                            (when 4byte
                              (write-byte (ash len -24) out)
                              (write-byte (logand (ash len -16) #xff) out))
                            (write-byte (logand (ash len -8) #xff) out)
                            (write-byte (logand len #xff) out)))
                      (write-sequence payload out))
                    (usocket:socket-stream socket))
    (force-output (usocket:socket-stream socket))))

(defmethod dispatch ((socket stream-usocket-websocket))
  (handler-case
      (let* ((in (usocket:socket-stream socket))
             fin mask
             (opcode (read-byte in))
             (payloadlen (read-byte in)))
        (setq fin (not (zerop (logand #x80 opcode)))
              opcode (logand #x0f opcode)
              mask (not (zerop (logand #x80 payloadlen)))
              payloadlen (logand #x7f payloadlen)
              payloadlen (if (<= 126 payloadlen)
                             (+ (if (= payloadlen 127)
                                    (+ (ash (read-byte in) 24)
                                       (ash (read-byte in) 16)) 0)
                                (ash (read-byte in) 8)
                                (read-byte in))
                             payloadlen))
        (when mask 
          (setq mask (make-array 4 :element-type '(unsigned-byte 8) :initial-contents
                                 (loop :repeat 4 :collect (read-byte in)))))
        (let ((ar (make-array payloadlen :element-type '(unsigned-byte 8))))
          (read-sequence ar (usocket:socket-stream socket))
          (when mask
            (loop :for i :from 0 :for v :across ar
                  :do (setf (aref ar i) (logxor v (aref mask (mod i 4))))))
          (when (= 1 opcode) (setf ar (babel:octets-to-string ar :encoding :utf-8)))
          (case opcode
            ((#x1 #x2 #xA) (ignore-errors (funcall (onmessage socket) socket opcode ar)))
            ((#x8) (send-frame socket #x8 ar)
             (ignore-errors (funcall (onclose socket) socket)) (end socket))
            ((#x9) (send-frame socket #xA ar)))
          (when sn.lisp-daemon.procs-ctrl::*debug* (format t ":opcode ~S :msg ~S ~%" opcode ar))))
    (end-of-file ()
      (ignore-errors (funcall (onclose socket) socket))
      (end socket))))

(defmacro defws (name &key onconnect onmessage onclose class)
  (alexandria.0.dev:with-gensyms (uri socket result accept str pos i)
    `(defun ,name (,uri ,socket)
       (let (,result ,accept)
         (loop :for ,i :in (buffer ,socket)
               :do (let* ((,str (remove #\Return ,i))
                          (,pos (position #\: ,str)))
                     (when ,pos
                       (push (cons (subseq ,str 0 ,pos)
                                   (string-trim " " (subseq ,str (1+ ,pos))))
                             ,result))))
         (change-class ,socket ',(or class 'stream-usocket-websocket))
         (if (ignore-errors (funcall (or ,onconnect (lambda (&rest ,i)(declare (ignore ,i))t))
                                     ,socket ,uri ,result))
             (progn 
               (setf ,accept (let ((k (cdr (assoc "Sec-WebSocket-Key" ,result :test 'equal)))
                                   (o7-guid "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
                               (cl-base64:usb8-array-to-base64-string
                                (ironclad:digest-sequence
                                 :sha1 (map '(vector (unsigned-byte 8)) #'char-code
                                            (concatenate 'string k o7-guid)))))) ;; borrowed from clws
               (websocket-accept ,socket nil ""(list "Upgrade: websocket" "Connection: Upgrade"
                                                     (format nil "Sec-WebSocket-Accept: ~A" ,accept)))
               (setf (onmessage ,socket) ,onmessage
                     (onclose ,socket) ,onclose))
             (badrequest ,socket "text/plain" "No"))))))
