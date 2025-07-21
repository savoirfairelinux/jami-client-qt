;;; To use with the GNU Guix package manager.
;;; Available from https://guix.gnu.org/.
;;;
;;; Commentary:
;;;
;;; This Guix manifest can be used to create an environment that
;;; minimally satisfies the requirements of libjami,
;;; maximizing the use of contrib dependencies. This can be useful to
;;; test building the contribs or compare the behavior of jami built
;;; with contribs. To satisfy the File-Hierarchy-Standard expectations
;;; of the contrib, it should be used in a FHS container like:
;;;
;;; guix shell -CFN -m daemon-minimal-manifest
;;;

(define %manifests-directory
  (dirname (canonicalize-path (current-filename))))

(concatenate-manifests
 (list
  (load-in-vicinity %manifests-directory "minimal-manifest.scm")
  (specifications->manifest
   (list
    ;; For the daemon and its contribs when not using system libraries
    ;; for the contribs.
    "alsa-lib"
    "autoconf"
    "automake"
    "bash"
    "bzip2"
    "cmake"
    "diffutils"
    "doxygen"
    "elogind"                           ;for building sdbus-c++
    "eudev"                             ;udev library
    "expat"
    "findutils"
    "gawk"
    "gettext"
    "libtool"
    "libva"                             ;vaapi
    "libvdpau"
    "nasm"
    "patch"
    "pcre"
    "perl"
    "pipewire"
    "pulseaudio"
    "which"
    "yasm"

    ;; For tests.
    "cppunit"
    "qthttpserver"))))
