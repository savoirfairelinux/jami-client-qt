;;; To use with the GNU Guix package manager.
;;; Available from https://guix.gnu.org/.
;;;
;;; Commentary:
;;;
;;; A more minimal development environment that can be used to build
;;; the whole project, making use of as many contribs as possible.
;;;
;;; The build.py script makes use of it to build Jami in a Linux
;;; container with the dependencies below when Guix is detected or
;;; when explicitly specified, e.g.:
;;;
;;; $ ./build.py --distribution=guix --install
;;;
;;; It can also be invoked directly to spawn a development
;;; environment, like so:
;;;
;;; $ guix shell --pure --manifest=extras/packaging/gnu-linux/guix/client+daemon-minimal-manifest.scm
;;;
(define %manifests-directory
  (dirname (canonicalize-path (current-filename))))

(concatenate-manifests
 (list
  (load-in-vicinity %manifests-directory "daemon-minimal-manifest.scm")
  (load-in-vicinity %manifests-directory "client-manifest.scm")))
