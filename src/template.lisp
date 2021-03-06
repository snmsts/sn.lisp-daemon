(defpackage sn.lisp-daemon.template
  (:use :cl :sn.lisp-daemon.httpd)
  (:export :raw))

(in-package :sn.lisp-daemon.template)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *template-path* (merge-pathnames "templates/" (asdf:component-pathname (asdf:find-system :sn.lisp-daemon))))
  (defun raw (file)
    (let ((path (merge-pathnames file *template-path*)))
      (with-open-file (in path)
        (with-output-to-string (out)
          (loop :for line := (read-line in nil nil)
             :while line
             :do (format out "~A~%" line)))))))

(publish
 (defun get/js/jquery.js (uri socket)
   (declare (ignore uri))
   (ok socket "application/x-javascript; charset=utf-8"
       (load-time-value
        (or
         (ignore-errors (raw "jquery-2.1.0.min.js"))
         (progn 
           ;; consider implement restart to check proxy setting and notify put jquery-2.1.0.min.js on templates directory.
           (print "[drakma jquery]")
           (let ((result (drakma:http-request "http://code.jquery.com/jquery-2.1.0.min.js" :force-binary t)))
             (with-open-file (out (merge-pathnames "jquery-2.1.0.min.js" *template-path*) 
                                  :element-type '(unsigned-byte 8)
                                  :direction :output)
               (write-sequence result out))
             (babel:octets-to-string result :encoding :utf-8))))))))

(publish ;; TODO: improve some.
 (defun get/ (uri socket)
   (declare (ignore uri))
   (ok socket "text/html"
       (with-output-to-string (out)
         (loop :for x :in *uri-assoc*
            :for y := (first (first x))
            :when (cl-ppcre:scan "index.html" y)
            :do (format out "<a href='~A'>~A</a><br>" y y))))))

(defmacro publish-templates (prefix &optional (directory *template-path*))
  (alexandria.0.dev:with-gensyms (uri socket)
    (let ((files (let ((len (length (pathname-directory directory)))
                       result)
                   (cl-fad:walk-directory
                    *template-path*
                    #'(lambda (x)
                        (let ((file (format nil "~{~A~^/~}"
                                            (append (subseq (pathname-directory x) len)
                                                    (list (file-namestring x))))))
                          (push `(publish
                                  (defun ,(make-symbol (format nil "get/~A~A" prefix file))
                                      (,uri ,socket)
                                    (declare (ignore ,uri))
                                    (ok ,socket ,(if (equal (subseq (reverse file) 0 2) "sj")
                                                     "application/x-javascript; charset=utf-8"
                                                     "text/html")
                                        ,(raw file))))
                                  result)))
                    :test (complement #'cl-fad:directory-pathname-p))
                   result)))
      `(progn ,@files))))

(eval-when (:load-toplevel :execute)
  (publish-templates "") )
