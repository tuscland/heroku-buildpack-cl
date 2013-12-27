(in-package "CL-USER")

(defvar *build-dir* (pathname (concatenate 'string (getenv "BUILD_DIR") "/")))
(defvar *cache-dir* (pathname (concatenate 'string (getenv "CACHE_DIR") "/")))
(defvar *buildpack-dir* (pathname (concatenate 'string (getenv "BUILDPACK_DIR") "/")))

;(ccl:setenv "XDG_CACHE_HOME" (concatenate 'string (getenv "BUILD_DIR") "/.cache/"))

(defmacro fncall (funname &rest args)
  `(funcall (read-from-string ,funname) ,@args))

(defun require-quicklisp (&key version)
  "VERSION if specified must be in format YYYY-MM-DD"
  (let ((ql-setup (merge-pathnames "quicklisp/setup.lisp" *build-dir*)))
    (if (probe-file ql-setup)
        (load ql-setup)
        (progn
          (load (merge-pathnames "bin/quicklisp.lisp" *buildpack-dir*))
          (fncall "quicklisp-quickstart:install"
                   :path (make-pathname :directory (pathname-directory ql-setup)))))
    (when version
      (fncall "ql-dist:install-dist"
              (format nil "http://beta.quicklisp.org/dist/quicklisp/~A/distinfo.txt"
                      version)
              :replace t :prompt nil))))

;;; stacktrace printing, copy/pasted from the ql-test by Fare:
;;; ssh://common-lisp.net/home/frideau/git/ql-test.git
(defun print-backtrace (out)
  "Print a backtrace (implementation-defined)"
  (declare (ignorable out))
  #+clozure (let ((*debug-io* out))
         (ccl:print-call-history :count 100 :start-frame-number 1)
         (finish-output out))
  #+sbcl
  (sb-debug:backtrace most-positive-fixnum out))

(defun call-with-ql-test-context (thunk)
  (block nil
    (handler-bind (((or error serious-condition)
                     (lambda (c)
                       (format *error-output* "~%~A~%" c)
                       (print-backtrace *error-output*)
                       (format *error-output* "~%~A~%" c)
                       (quit -1)
                       (return nil))))
      (funcall thunk))))

(defmacro with-ql-test-context (() &body body)
  `(call-with-ql-test-context #'(lambda () ,@body)))

;;; Load the application compile script
(with-ql-test-context ()
  (load (merge-pathnames "heroku-compile.lisp" *build-dir*)))

;;; Successful exit
(quit 0)
