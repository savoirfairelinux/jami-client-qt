;;; To use with the GNU Guix package manager.
;;; Available from https://guix.gnu.org/.
;;;
;;; Commentary:
;;;
;;; A full-blown development environment that can be used to build the
;;; whole project.  The sensitive (i.e., patched) dependencies are
;;; consciously omitted from this list so that the bundled libraries
;;; are the ones used, which is usually what is desired for
;;; development purposes.
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
;;; $ guix shell --pure
;;;
;;; An alternative manifest where nearly every daemon contrib
;;; dependencies are omitted from the manifest (so that the contribs
;;; from Jami are maximally used) can be used with:
;;;
;;; $ guix shell --pure --manifest=extras/packaging/gnu-linux/guix/client+daemon-minimal-manifest.scm
;;;
(define %manifests-directory
  (dirname (canonicalize-path (current-filename))))

(concatenate-manifests
 (list
  (load-in-vicinity %manifests-directory "daemon-manifest.scm")
  (load-in-vicinity %manifests-directory "client-manifest.scm")))
