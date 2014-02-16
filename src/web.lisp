(in-package :sn.lisp-daemon.httpd)

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
