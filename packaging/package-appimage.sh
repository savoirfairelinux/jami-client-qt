#!/usr/bin/env bash

# execute in jami-project/client-qt/

cp images/jami.png build-local/ -f #TODO improve
wget https://github.com/probonopd/linuxdeployqt/releases/download/5/linuxdeployqt-5-x86_64.AppImage -o /tmp/linuxdeployqt-5-x86_64.AppImage
chmod +x /tmp/linuxdeployqt-5-x86_64.AppImage
LD_LIBRARY_PATH=/usr/lib/:/usr/lib64/:/usr/lib64/pulseaudio:$(pwd)/../install/daemon/lib:$(pwd)/../install/lrc/lib /tmp/linuxdeployqt-5-x86_64.AppImage packaging/jami.desktop -appimage -bundle-non-qt-libs -qmldir=src/
rm -f /tmp/linuxdeployqt-5-x86_64.AppImage