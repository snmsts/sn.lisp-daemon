(in-package :cl-user)
(defpackage sn.lisp-daemon-asd
  (:use :cl :asdf))
(in-package :sn.lisp-daemon-asd)

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (load-system :trivial-features))

(defsystem sn.lisp-daemon
  :version "0.2.1"
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
               #-windows :osicat
               :ironclad
               :cl-fad)
  :components ((:module "src"
                :components
                ((:file "httpd")
                 (:file "web" :depends-on ("httpd"))
                 (:file "template")
                 (:file "procs-model")
                 (:file "procs-ctrl" :depends-on ("web" "procs-model" "template"))
                 (:file "swank-model" :depends-on ("procs-model"))
                 (:file "swank-ctrl" :depends-on ("web" "swank-model" "template"))
                 (:file "swank-proxy" :depends-on ("httpd"))
                 (:file "websocket" :depends-on ("web"))
                 (:file "websocket-proxy" :depends-on ("websocket"))
                 (:file "websocket-proxy-ctrl" :depends-on ("websocket-proxy"))
		 (:file "websocket-proxy-sexp2js" :depends-on ("websocket-proxy"))
		 (:file "swank-json")
                 (:file "dump")
                 (:file "core"))))
  :description "Common Lisp as a service.")
