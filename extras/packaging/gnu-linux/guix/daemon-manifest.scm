;;; To use with the GNU Guix package manager.
;;; Available from https://guix.gnu.org/.
;;;
;;; Commentary:
;;;
;;; This Guix manifest can be used to create an environment that
;;; satisfies the requirements of the jami-daemon, using as much
;;; system dependencies as it makes sense to.

(define %manifests-directory
  (dirname (canonicalize-path (current-filename))))

(concatenate-manifests
 (list
  (load-in-vicinity %manifests-directory "daemon-minimal-manifest.scm")
  (specifications->manifest
   (list
    ;; Added system dependencies that avoid building the matching
    ;; contribs, speeding up the build.
    "asio"
    ;;"dhtnet"                            ;bundled because tightly coupled
    "gnutls"
    ;;"ffmpeg"                            ;bundled because patched
    "gmp"
    "gsm"
    "http-parser"
    "jack@0"
    "jsoncpp"
    "libarchive"
    "libgit2"
    "libnatpmp"
    "libupnp"
    "libsecp256k1"
    "libx264"
    "nettle"
    "openssl"
    "opus"
    ;;"pjproject"                         ;bundled because patched
    "sdbus-c++"
    "speex"
    "speexdsp"
    "webrtc-audio-processing@0"
    "yaml-cpp"))))
