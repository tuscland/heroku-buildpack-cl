(in-package "CL-USER")

(defvar *saved-executable-name* "cl-app")
(defvar *build-dir* (pathname-directory (pathname (concatenate 'string (getenv "BUILD_DIR") "/"))))
(defvar *cache-dir* (pathname-directory (pathname (concatenate 'string (getenv "CACHE_DIR") "/"))))
(defvar *buildpack-dir* (pathname-directory (pathname (concatenate 'string (getenv "BUILDPACK_DIR") "/"))))

;;; Tell ASDF to store binaries in the cache dir
(ccl:setenv "XDG_CACHE_HOME" (concatenate 'string (getenv "CACHE_DIR") "/.asdf/"))

(require :asdf)

(let ((ql-setup (make-pathname :directory (append *cache-dir* '("quicklisp")) :defaults "setup.lisp")))
  (if (probe-file ql-setup)
      (load ql-setup)
      (progn
	(load (make-pathname :directory (append *buildpack-dir* '("lib")) :defaults "quicklisp.lisp"))
	(funcall (symbol-function (find-symbol "INSTALL" (find-package "QUICKLISP-QUICKSTART")))
		 :path (make-pathname :directory (pathname-directory ql-setup))))))

;;; Default toplevel, app must redefine.
(defun heroku-toplevel ()
  (loop (sleep 60)))

;;; Load the application from sources
(load (make-pathname :directory *build-dir* :defaults "heroku-setup.lisp"))

;;; Save the application as an image
(let ((app-file (format nil "~A/~A" (getenv "BUILD_DIR") *saved-executable-name*))) ;must match path specified in bin/release
  (format t "Saving to ~A~%" app-file)
  (save-application app-file
		    :prepend-kernel t
		    :toplevel-function #'heroku-toplevel
		    ))
