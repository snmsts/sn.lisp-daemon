#+quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(load (make-pathname :name "sn.lisp-daemon":type "asd":defaults *load-pathname*))
(ql:quickload '(:swank :sn.lisp-daemon))
(setq sn.lisp-daemon.procs-ctrl::*debug* t)
(swank:create-server :port 4006 :dont-close t)
(sn.lisp-daemon.swank-model:register-swank-port 4006 nil "localhost")
(sn.lisp-daemon:start #|:host "0.0.0.0"|#)

