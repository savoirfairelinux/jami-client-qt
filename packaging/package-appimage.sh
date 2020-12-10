#!/usr/bin/env bash

# execute in jami-project/client-qt/

set -e
packager="linuxdeployqt-5-x86_64.AppImage"
download_path="/tmp"
full_path="$download_path/$packager"
appname="jami"
desktop_path="packaging"
qml_dir="src/"

if [ ! -f "$full_path" ]; then
    wget https://github.com/probonopd/linuxdeployqt/releases/download/5/$packager -P $download_path
    chmod +x $full_path
fi

#TODO improve
cp images/jami.png build-local/ -f
LD_LIBRARY_PATH=/usr/lib/:/usr/lib64/:/usr/lib64/pulseaudio:$(pwd)/../install/daemon/lib:$(pwd)/../install/lrc/lib $full_path \
    $desktop_path/$appname.desktop \
    -appimage \
    -bundle-non-qt-libs \
    -qmldir=$qml_dir
