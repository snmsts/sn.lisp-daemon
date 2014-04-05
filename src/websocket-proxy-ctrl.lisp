(defpackage sn.lisp-daemon.websocket-proxy-ctrl
  (:use :cl :sn.lisp-daemon.httpd))

(in-package :sn.lisp-daemon.websocket-proxy-ctrl)

(publish
 (defun get/websocket/index.html (uri socket)
   (declare (ignore uri))
   (ok socket "text/html; charset=UTF-8"
       #.(sn.lisp-daemon.template:raw "websocket.raw.html"))))

(publish
 (defun get/websocket/index.js (uri socket)
   (declare (ignore uri))
   (ok socket "application/javascript; charset=UTF-8"
       #.(sn.lisp-daemon.template:raw "websocket.raw.js"))))
