(defpackage sn.lisp-daemon.dump
  (:use :cl)
  (:export :dump))

(in-package :sn.lisp-daemon.dump)

;; I don't have idea yet
(defun dump (filename &key debug (host "127.0.0.1") (port 4005) daemonize)
  (setf sn.lisp-daemon.procs-ctrl::*debug* debug)
  (trivial-dump-core:save-executable 
   filename
   #'(lambda ()
       (unwind-protect
            (sn.lisp-daemon.httpd:start :host host :port port)
         (swank:quit-lisp)))))
