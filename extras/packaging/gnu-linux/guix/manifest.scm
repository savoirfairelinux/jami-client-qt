;;; To use with the GNU Guix package manager.
;;; Available at https://guix.gnu.org/.
;;;
;;; Commentary:
;;;
;;; A full-blown development environment that can be used to build the
;;; whole project.  The sensitive (i.e., patched) dependencies are
;;; consciously omitted from this list so that the bundled libraries
;;; are the ones used, which is usually what is desired for
;;; development purposes.

;;; The build.py script makes use of it to build Jami in a Linux
;;; container with the dependencies below when Guix is detected (and
;;; no /etc/os-release file exists) or when explicitly specified,
;;; e.g.:
;;;
;;; $ ./build.py --distribution=guix --install
;;;
;;; It can also be invoked directly to spawn a development environment, like so:
;;;
;;; $ guix shell --pure --manifest=guix/manifest.scm

(specifications->manifest
 (list
  ;; Minimal requirements of the daemon contrib build system.
  "coreutils"
  ;; When using GCC 15, Jami fails to link with errors like:
  ;; ld: CMakeFiles/jami.dir/src/app/main.cpp.o:(.rodata+0x0):
  ;; multiple definition of `QtPrivate::IsFloatType_v<_Float16>'
  "gcc-toolchain@14"
  "git-minimal"
  "grep"
  "gzip"
  "make"
  "nss-certs"
  "pkg-config"
  "python"
  "sed"
  "tar"
  "util-linux"
  "wget"
  "xz"

  ;; For the daemon and its contribs.
  "alsa-lib"
  "autoconf"
  "automake"
  "asio"
  "bash"
  "bzip2"
  "cmake"
  "dbus"
  ;;"dhtnet"                            ;bundled because tightly coupled
  "diffutils"
  "doxygen"
  "eudev"                               ;udev library
  "expat"
  "findutils"
  "gawk"
  "gettext"
  "gnutls"
  ;;"ffmpeg"                            ;bundled because patched
  "gmp"
  "gsm"
  "gtk-doc"
  "http-parser"
  "jack@0"
  "jsoncpp"
  "libarchive"
  "libgit2"
  "libnatpmp"
  "libupnp"
  "libsecp256k1"
  "libtool"
  "libva"                               ;vaapi
  "libvdpau"
  "libx264"
  "nasm"
  "nettle"
  "openssl"
  "opus"
  "patch"
  "pcre"
  "perl"
  "pipewire"
  ;;"pjproject"                         ;bundled because patched
  "pulseaudio"
  "sdbus-c++@1"
  "speex"
  "speexdsp"
  "webrtc-audio-processing@0"
  "which"
  "yaml-cpp"
  "yasm"

  ;; For the Qt client.
  "glib"
  "hunspell"
  "libnotify"
  "libxcb"
  "libxkbcommon"
  "md4c"
  "network-manager"                     ;libnm
  "qrencode"
  "qtbase"
  "qt5compat"
  "qtdeclarative"
  "qtmultimedia"
  "qtnetworkauth"
  "qtpositioning"
  "qtsvg"
  "qwindowkit"
  "qttools"
  "qtwebchannel"
  "qtwebengine"
  "tidy-html"
  "vulkan-headers"
  "zxing-cpp"

  ;; For tests and debugging.
  "file"
  "gdb"
  "googletest"
  "ltrace"
  "strace"))
