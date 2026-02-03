{
  description = "Dev shell for Jami Qt client dependencies (Qt 6.10; no daemon/dhtnet/opendht/pjsip builds)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      rmNull = xs: builtins.filter (x: x != null) xs;
      forEachSystem = f: lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          # Prefer the Qt 6.10 package set; fall back to the default qt6Packages if unavailable.
          qt = pkgs.qt6_10 or pkgs.qt6_10Packages or pkgs.qt6Packages;
          # Swig 4.2 and Node 22 are required by the daemon toolchain; fall back to defaults if missing.
          swig = pkgs.swig4_2 or pkgs.swig;
          nodejs = pkgs.nodejs_22 or pkgs.nodejs_latest or pkgs.nodejs;
          nodeGyp = pkgs.nodePackages_latest.node-gyp or pkgs.nodePackages.node-gyp;
          pnpm = (pkgs.nodePackages_latest.pnpm or pkgs.nodePackages.pnpm or pkgs.pnpm or null);
          withWebengine = true;
        in
        f { inherit pkgs lib rmNull qt swig nodejs nodeGyp pnpm withWebengine; }
      );
    in
    {
      devShells = forEachSystem ({ pkgs, lib, rmNull, qt, swig, nodejs, nodeGyp, pnpm, withWebengine }: {
        default = pkgs.mkShell {
          nativeBuildInputs = rmNull [
            pkgs.autoconf
            pkgs.automake
            pkgs.gettext
            pkgs.bison
            pkgs.cmake
            pkgs.curl
            pkgs.gnumake
            pkgs.git
            pkgs.gnum4
            pkgs.libtool
            pkgs.nasm
            pnpm
            pkgs.python3
            pkgs.pkg-config
            pkgs.ninja
            pkgs.yasm
            pkgs.wrapGAppsHook3
            qt.wrapQtAppsHook
            qt.qttools
            swig
            nodejs
            nodeGyp
          ];

          buildInputs = rmNull [
            pkgs.alsa-lib
            pkgs.asio
            pkgs.libglvnd
            pkgs.mesa
            pkgs.mesa
            pkgs.dbus
            pkgs.ffmpeg_6
            pkgs.expat
            pkgs.html-tidy
            pkgs.hunspell
            pkgs.libarchive
            pkgs.libnatpmp
            pkgs.libnotify
            pkgs.msgpack-cxx
            pkgs.md4c
            pkgs.nettle
            pkgs.networkmanager
            pkgs.openssl
            pkgs.pipewire
            pkgs.pulseaudio
            pkgs.sipp
            pkgs.speex
            pkgs.speexdsp
            pkgs.systemd
            pkgs.udisks2 or pkgs.udev
            pkgs.gmp
            pkgs.gnutls
            pkgs.jsoncpp
            pkgs.restinio or null
            pkgs.secp256k1
            pkgs.webrtc-audio-processing
            pkgs.qrencode
            pkgs.libupnp
            pkgs.libva
            pkgs.libvdpau
            pkgs.libvpx
            pkgs.x264
            pkgs.yaml-cpp
            pkgs.http-parser
            pkgs.libopus or pkgs.opus or null
            pkgs.gnupg or null
            pkgs.cppunit
            pkgs.guile_3_0
            pkgs.vulkan-loader
            qt.qtbase
            qt.qt5compat
            qt.qtnetworkauth
            qt.qtdeclarative
            qt.qtmultimedia
            qt.qtpositioning
            qt.qtsvg
            qt.qtwebchannel
          ] ++ pkgs.lib.optionals withWebengine [ qt.qtwebengine ];

          shellHook =
            let
              qmlPaths = lib.makeSearchPath "lib/qt-6/qml" (rmNull ([
                qt.qtdeclarative
                qt.qtmultimedia
                qt.qt5compat
              ] ++ lib.optionals withWebengine [ qt.qtwebengine ]));
              pluginPaths = lib.makeSearchPath "lib/qt-6/plugins" (rmNull ([
                qt.qtbase
                qt.qtmultimedia
                qt.qtsvg
              ] ++ lib.optionals withWebengine [ qt.qtwebengine ]));
              glDrivers = lib.makeSearchPath "lib/dri" [ pkgs.mesa ];
            in
            ''
              export QML2_IMPORT_PATH=${qmlPaths}${lib.optionalString (qmlPaths != "") ":"}$QML2_IMPORT_PATH
              export QML_IMPORT_PATH=$QML2_IMPORT_PATH
              export QT_PLUGIN_PATH=${pluginPaths}${lib.optionalString (pluginPaths != "") ":"}$QT_PLUGIN_PATH
              export LIBGL_DRIVERS_PATH=${glDrivers}${lib.optionalString (glDrivers != "") ":"}$LIBGL_DRIVERS_PATH
              export LD_LIBRARY_PATH=${pkgs.libglvnd}/lib:${pkgs.mesa}/lib${lib.optionalString ("${pkgs.mesa}/lib" != "") ":${pkgs.mesa}/lib"}:$LD_LIBRARY_PATH
              export VK_ICD_FILENAMES=${pkgs.mesa}/share/vulkan/icd.d/intel_icd.x86_64.json:${pkgs.mesa}/share/vulkan/icd.d/radeon_icd.x86_64.json:${pkgs.mesa}/share/vulkan/icd.d/lvp_icd.x86_64.json
            '';
        };
      });
    };
}
