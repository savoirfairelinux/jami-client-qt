(specifications->manifest
   (list
    ;; For the Qt client.
    "dconf"                             ;required to check theme preference
    "glib"
    "gsettings-desktop-schemas"         ;required by Qt at runtime
    "gtk+"                              ;for extra schemas
    "hunspell"
    "libnotify"
    "libxcb"
    "libxkbcommon"
    "md4c"
    "network-manager"                    ;libnm
    "qtbase"
    "qt5compat"
    "qtdeclarative"
    "qtmultimedia"
    "qtnetworkauth"
    "qtpositioning"
    "qtsvg"
    "qwindowkit"
    "qttools"
    "qtwayland"
    "qtwebchannel"
    "qtwebengine"
    "qwindowkit"
    "tidy-html"
    "vulkan-loader"
    "zxing-cpp"

    ;; For tests and debugging.
    "file"
    "gdb"
    "googletest"
    "ltrace"
    "strace"))
