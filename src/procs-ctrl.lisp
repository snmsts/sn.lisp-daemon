(defpackage sn.lisp-daemon.procs-ctrl
  (:use :cl :sn.lisp-daemon.httpd)
  (:export))

(in-package sn.lisp-daemon.procs-ctrl)

(publish
 (defun post/api/1.0/process/list (uri socket)
   (declare (ignore uri))
   (ok socket "application/json" 
       (with-output-to-string (*standard-output*)
         (yason:encode (sn.lisp-daemon.procs-model:list-processes))))))
#+nil
(babel:octets-to-string (drakma:http-request "http://localhost:4005/api/1.0/process/list" :method :post) :encoding :utf-8)

(publish
 (defun post/api/1.0/process/swank (uri socket)
   (paramlet (name) uri
     (when (stringp name)
       (ok socket "application/json"
           (if (sn.lisp-daemon.procs-model:make-swank-process name) "true" "false"))))))

(publish
 (defun post/api/1.0/process/kill (uri socket)
   (paramlet (name) uri
     (when (stringp name)
       (ok socket "application/json"
           (with-output-to-string (*standard-output*)
             (yason:encode (sn.lisp-daemon.procs-model:kill-process name))))))))

#+nil
(babel:octets-to-string (drakma:http-request "http://localhost:4005/api/1.0/process/kill?123" :method :post) :encoding :utf-8)

(publish
 (defun post/api/1.0/process/quit (uri socket)
   (declare (ignore uri))
   (ok socket "application/json" "OK")
   (sn.lisp-daemon.procs-model:quit-all)))

#+nil
(babel:octets-to-string (drakma:http-request "http://localhost:4005/api/1.0/process/quit" :method :post) :encoding :utf-8)

;; TODO move somewhere else
(defvar *debug* nil)

(publish
 (defun post/api/1.0/debug/p (uri socket)
   (declare (ignore uri))
   (when *debug*
     (print (list :procs (sn.lisp-daemon.procs-model:list-processes)
                  :swanks (funcall (read-from-string "sn.lisp-daemon.swank-model:list-swanks"))
                  :sockets sn.lisp-daemon.procs-model::*sockets*))
     (force-output))
   (ok socket "application/json" (if *debug* "true" "false"))))

(publish
 (defun post/api/1.0/debug/reload (uri socket)
   (declare (ignore uri))
   (ok socket "application/json" "OK")
   (when *debug*
     (sn.lisp-daemon.procs-model::reload-all))))
