(defpackage sn.lisp-daemon.httpd
  (:use :cl)
  (:export  :start :publish :stream-usocket-with-state :accessor :*accept-class*
   :*routined-duties* :*uri-assoc* :*host* :*sockets* :dispatch :stream-usocket-with-state :buffer :end
   :paramlet :integer! :response :ok :badrequest)) ;; web.lisp
(in-package :sn.lisp-daemon.httpd)

(defvar *sockets* '())
(defvar *routined-duties* '())
(defvar *uri-assoc* '())
(defvar *host* '())
(defvar *accept-class* 'stream-usocket-with-state)

(defclass stream-usocket-with-state (usocket:stream-usocket)
  ((buffer :accessor buffer)
   (acceptted :accessor acceptted)))

(defmethod update-instance-for-different-class :before ((old usocket:stream-usocket) (new stream-usocket-with-state) &key)
  (setf (slot-value new 'buffer) '()
        (slot-value new 'acceptted) (get-universal-time)))

(defun add-listener (&optional (host "127.0.0.1") (port 4005)
                      &rest #1=|\"reffer USOCKET:SOCKET-LISTEN\"|)
   (push (apply #'usocket:socket-listen host port :reuse-address t #1#) *sockets*)
   (setf *host* (cons host port)))

(defmethod dispatch ((socket usocket:stream-server-usocket))
  (let ((i (usocket:socket-accept socket :element-type '(unsigned-byte 8))))
    (change-class i *accept-class*)
    (push i *sockets*)))

(defmethod dispatch ((socket stream-usocket-with-state))
  (let ((line (coerce (loop :with in := (usocket:socket-stream socket) 
                            :for c := (read-byte in)
                            :while (/= c #.(char-code #\Newline)) 
                            :collect (code-char c)) 'string)))
    (push line (buffer socket))
    (when (equal line #.(string #\Return))
      (setf (buffer socket) (nreverse (buffer socket)))
      (process-header socket))))

(defun dispatch-socket-events ()
  (dolist (socket (usocket:wait-for-input *sockets* :timeout 1 :ready-only t))
    (ignore-errors (dispatch socket))))

(defun start (&key (host "127.0.0.1") (port 4005))
  (unless *sockets*
    (add-listener host port))
  (loop
     :with last-time := (get-universal-time)
     :do (dispatch-socket-events)
     (let ((now (get-universal-time)))
       (when (> now (1+ last-time))
         (loop :for duty :in *routined-duties*
            :do (ignore-errors (funcall duty)))
         (setf last-time now)))))

(defun method-keyword (method)
  (or (cdr (assoc method '(("POST" . :POST) ("GET" . :GET)) :test 'equal)) :*))

(defun publish (symbol)
  (let* ((str (string symbol))
         (uri (string-downcase (subseq str (position #\/ str))))
         (method (method-keyword (string-upcase (subseq str 0 (position #\/ str))))))
    (setf *uri-assoc* (acons (cons uri method) (symbol-function symbol)
                             (remove (cons uri method) *uri-assoc* :key #'first :test 'equalp)))
    symbol))

(defun end (socket)
  (usocket:socket-close socket)
  (setq *sockets* (remove socket *sockets*)))

(defun process-header (socket)
  "I want make it simple enough,so just dispatch by URI"
  (destructuring-bind (method uri &optional version) (cl-ppcre:split " " (first (buffer socket)))
    (declare (ignore version))
    (setq method (method-keyword method))
    (let* ((uri (cl-ppcre:split "\\?" uri))
           (fun (cdr (assoc (cons (first uri) method) *uri-assoc* :test 'equalp)))
           (result (if fun
                       (nth-value 1 (ignore-errors (values (funcall fun uri socket))))
                       "no!")))
      (when result
        (badrequest socket "text/plain" (format nil "~A" result))))))
