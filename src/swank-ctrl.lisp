(defpackage sn.lisp-daemon.swank-ctrl
  (:use :cl :sn.lisp-daemon.httpd)
  (:export))

(in-package sn.lisp-daemon.swank-ctrl)

(publish
 (defun post/api/1.0/swank/list (uri socket)
   (declare (ignore uri))
   (ok socket "application/json" 
       (with-output-to-string (*standard-output*)
         (yason:encode (sn.lisp-daemon.swank-model:list-swanks))))))

(publish
 (defun post/api/1.0/swank/info (uri socket)
   (paramlet (port pid host) uri
     (integer! port pid)
     (when (and port (or pid host))
       (sn.lisp-daemon.swank-model:register-swank-port port pid host) 
       (ok socket "application/json"
           "true")))))

(publish
 (defun post/api/1.0/swank/totop (uri socket)
   (paramlet (port pid host) uri
     (integer! port pid)
     (when (and port (or pid host))
       (sn.lisp-daemon.swank-model:totop port pid (yason:parse (or host "[]")))
       (ok socket "application/json"
           "true")))))

(publish
 (defun post/api/1.0/swank/delete (uri socket)
   (paramlet (port pid host) uri
     (integer! port pid)
     (when (and port (or pid host))
       (sn.lisp-daemon.swank-model:delete-swank-port port pid (yason:parse (or host "[]")))
       (ok socket "application/json"
           "true")))))

#+nil
(babel:octets-to-string (drakma:http-request "http://localhost:4005/api/1.0/process/swank-info?port=30&pid=16794" :method :post) :encoding :utf-8)

(publish
 (defun get/swank/index.html (uri socket)
   (declare (ignore uri))
   (ok socket "text/html; charset=UTF-8"
       #.(sn.lisp-daemon.template:raw "swank.raw.html"))))

(publish
 (defun get/swank/index.js (uri socket)
   (declare (ignore uri))
   (ok socket "application/javascript; charset=UTF-8"
       #.(sn.lisp-daemon.template:raw "swank.raw.js"))))
