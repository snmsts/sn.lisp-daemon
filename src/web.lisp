(in-package :sn.lisp-daemon.httpd)

(defmacro response (function code expression &optional ommit no-close)
  (let ((socket (gensym "SOCKET")) (content-type (gensym "CT")) (body (gensym "BODY")) (optional-headers (gensym "HEADERS")))
    `(defun ,function (,socket ,content-type ,body &optional ,optional-headers)
       (write-sequence (babel:string-to-octets 
                        (format nil #.(format nil "~{~A~}" '("~{~A~^" #\Return "~%~}"))
                                `(,',(format nil "HTTP/1.1 ~A ~A" code expression)
                                  ,,@(unless ommit `((format nil "Content-Type: ~A" ,content-type)))
                                  ,,@(unless ommit '("Cache-Control: private, max-age=0"))
                                  ,@(when ,optional-headers ,optional-headers)
                                  ,',"" ,,body)):encoding :utf-8) (usocket:socket-stream ,socket))
       ,@(if no-close `((force-output (usocket:socket-stream ,socket))) `((end ,socket))))))

(response badrequest 400 "Bad Request")
(response ok 200 "OK")

(defmacro paramlet ((&rest symbols) uri &body body)
  (let ((params (gensym)))
    `(let* ((,params (mapcar (lambda (kv) (mapcar #'do-urlencode:urldecode (cl-ppcre:split "=" kv)))
                              (cl-ppcre:split "&" (second ,uri))))
            ,@(loop :for elm :in symbols
                 :collect `(,elm (second (assoc ,(string-downcase elm) ,params :test 'equal)))))
       ,@body)))

(defmacro integer! (&rest params)
  (let ((g (loop :for i :in params :collect (gensym))) (j (gensym)))
    `(let (,@(loop :for i :in params :for p :in g :collect `(,p ,i)))
       (setf ,@(loop :for i :in params :for p :in g :collect i 
                  :collect `(when (and ,p (loop :for ,j :across (string ,p) :always (digit-char-p ,j)))
                              (parse-integer (string ,p))))))))
