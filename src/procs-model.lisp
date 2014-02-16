(defpackage sn.lisp-daemon.procs-model
  (:use :cl :sn.lisp-daemon.httpd)
  (:export :make-process :list-processes :kill-process :takecare-processes
           :quit-all :*default-function* :*log-function* :*process-list* :log-
           :make-swank-process))

(in-package :sn.lisp-daemon.procs-model)

;; it should be exec something
(defvar *default-function* #'(lambda () (loop :while t :do (sleep 1))))
(defvar *log-function* #'(lambda (id pid) (declare (ignore id pid))))
(defvar *process-list* '())

(defun log- (logid pid)
  (funcall *log-function* logid pid)
  t)

(defun make-process (name &optional (function *default-function*) &rest rest)
  (declare (ignorable name))
  (unless (find name *process-list* :key 'second :test 'equal)
    (let ((pid (progn 
                 #-windows(iolib.syscalls:fork))))
      (if (zerop pid)
          (unwind-protect
               (progn
                 (mapc #'usocket:socket-close sn.lisp-daemon.httpd:*sockets*)
                 (if (or (functionp function) (symbolp function)) 
                     (apply function rest)
                     '(:exec rest)))
            (swank:quit-lisp))
          (progn
            (log- 100 pid)
            (push (list pid name) *process-list*)))
      pid)))

(defun start-swank ()
  (let ((style (if (find swank:*communication-style* '(:sigio :fd-handler))
                   nil
                   swank:*communication-style*)))
    (swank::setup-server
     0 (lambda (port)
         (drakma:http-request (format nil "http://~A:~A/api/1.0/swank/info?port=~A&pid=~A"
                                      (first *host*) (rest *host*) port (iolib.syscalls:getpid)) :method :post))
     style t nil)
    (loop :while t :do (sleep 1))))

(defun make-swank-process (name)
  (make-process (format nil "SWANK.~A.~A" (lisp-implementation-type) name) 'start-swank))

(defun list-processes ()
  (mapcar #'rest *process-list*))

(defun kill-process (name)
  (log- 101 name)
  (let ((pid (find name *process-list* :key 'second :test 'equal)))
    (when pid
      (prog1 (progn 
               #-windows(iolib.syscalls:kill (first pid) iolib.syscalls:sigkill))
        (takecare-processes)))))

(defun quit-all ()
  (log- 102 0)
  (loop :while *process-list*
     :do (loop :for elt :in *process-list*
            :for r := (ignore-errors (kill-process (second elt))))
     (takecare-processes))
  (swank:quit-lisp))

(defun takecare-processes ()
  (setf *process-list*
        (loop :for elt :in *process-list*
           :for (pid . rest) := elt
           :for r := (unless (progn
                               #-windows(zerop (iolib.syscalls:waitpid pid iolib.syscalls:wnohang)))
                       (log- 101 pid))
           :unless r
           :collect elt))
  t)

(pushnew 'takecare-processes sn.lisp-daemon.httpd:*routined-duties*)

;;separate
(defun reload-all ()
  (ignore-errors (asdf:load-system :sn.lisp-daemon :force t)))
