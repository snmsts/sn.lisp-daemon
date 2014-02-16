(in-package :cl-user)
(defpackage sn.lisp-daemon-asd
  (:use :cl :asdf))
(in-package :sn.lisp-daemon-asd)

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (load-system :trivial-features))

(defsystem sn.lisp-daemon
  :version "0.1"
  :author "SANO Masatoshi"
  :license "MIT"
  :depends-on (:usocket 
               :cl-ppcre
               :swank
               :yason
               :drakma
               :do-urlencode
               :trivial-dump-core
               :trivial-utf-8
               #-windows :iolib.syscalls)
  :components ((:module "src"
                :components
                ((:file "httpd")
                 (:file "web" :depends-on ("httpd"))
                 (:file "template")
                 (:file "procs-model")
                 (:file "procs-ctrl" :depends-on ("httpd" "procs-model" "template"))
                 (:file "swank-model" :depends-on ("procs-model"))
                 (:file "swank-ctrl" :depends-on ("httpd" "swank-model" "template"))
                 (:file "swank-proxy" :depends-on ("httpd"))
                 (:file "dump")
                 (:file "core"))))
  :description "Common Lisp as a service.")
