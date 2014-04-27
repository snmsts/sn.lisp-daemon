(defpackage swank-json
  (:use :cl))

(in-package :swank-json)

(defun keyword->str (x)
  (loop :for i :in x :collect (cond ((symbolp i) (format nil "~S" i))
				    ((listp i) (keyword->str i))
				    (t i))))
(defun plist->hash (x)
  (loop :with h := (make-hash-table :test 'equal)
     :for (i j . nil) :on x :by #'cddr
     :do (setf (gethash i h) j)
     :finally (return h)))

(export
 (defun connection-info () 
   (with-output-to-string (o) 
     (let ((h (plist->hash (keyword->str (swank:connection-info)))))
       (setf (gethash ":PACKAGE" h) (plist->hash (gethash ":PACKAGE" h)))
       (yason:encode h o)))))


