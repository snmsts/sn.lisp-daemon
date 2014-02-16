(defpackage sn.lisp-daemon.swank-model
  (:use :cl :sn.lisp-daemon.procs-model :sn.lisp-daemon.httpd)
  (:export :register-swank-port :delete-swank-port :list-swanks :totop))

(in-package sn.lisp-daemon.swank-model)

(defvar *swank-list* '())

(defun register-swank-port (port pid host)
  (let ((assoc (assoc pid *process-list*)))
    (when assoc
      (setf (cddr assoc) (acons "swank" (list port) (remove "swank" (cddr assoc) :key #'first :test #'equal)))))
  (pushnew (list port pid host) *swank-list* :test #'equalp))

(defun totop (port pid host)
  (let ((e (list port pid host)))
    (when (find e *swank-list* :test #'equalp)
      (setf *swank-list*
            (cons e (remove e *swank-list* :test #'equalp))))))

(defun delete-swank-port (port pid host)
  (setf *swank-list* (remove (list port pid host) *swank-list* :test #'equalp)))

(defun list-swanks ()
  *swank-list*)
