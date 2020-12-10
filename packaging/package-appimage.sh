#!/usr/bin/env bash

# execute in jami-project/client-qt/

set -e
packager="linuxdeployqt-5-x86_64.AppImage"
download_path="/tmp"
full_path="$download_path/$packager"
appname="jami"
desktop_path="packaging"
qml_dir="src/"
subversion=""

if [ ! -f "$full_path" ]; then
    wget https://github.com/probonopd/linuxdeployqt/releases/download/5/$packager -P $download_path
    chmod +x $full_path
fi

if [ ! -z "$1" ]; then
    subversion="$1"
fi

$full_path --appimage-extract

# Cleanup
find $PWD/build-* \( -name "moc_*" -or -name "*.o" -or -name "qrc_*" -or -name "Makefile*" -or -name "*.a" \) -exec rm {} \; || true
rm -rf /isr/;ob/x86_64-linux-gnu/libfribidi.so.0* || true

#TODO improve
cp images/jami.png build-local/ -f
LD_LIBRARY_PATH=/usr/lib/:/usr/lib64/:/usr/lib64/pulseaudio:/usr/lib/x86_64-linux-gnu/:/opt/Qt/5.15.0/gcc_64/plugins/sqldrivers/:/usr/lib64/qt5/libexec:/usr/lib/qt/plugins/platforms/:$(pwd)/../install/daemon/lib:$(pwd)/../install/lrc/lib \
    squashfs-root/AppRun \
    $desktop_path/$appname.desktop \
    -appimage -extra-plugins=xcb \
    -bundle-non-qt-libs \
    -qmldir=$qml_dir

rm -rf squashfs-root/ || true
./Jami-x86_64.AppImage --appimage-extract || true
find ./squashfs-root -type f -name '*fribidi*' -delete || true
wget https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage || true
chmod +x appimagetool-x86_64.AppImage || true
rm -rf ./Jami-x86_64.AppImage
./appimagetool-x86_64.AppImage squashfs-root/ || true
if [ "$subversion" != "" ]; then
    mv ./Jami-x86_64.AppImage ./Jami-${subversion}-x86_64.AppImage || true
fi