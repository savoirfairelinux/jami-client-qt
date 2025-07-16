#!/usr/bin/env bash

# Building Qt Multimedia requires the FFmpeg headers and libraries to be installed:
#     https://doc.qt.io/qt-6.8/qtmultimedia-building-from-source.html
# For Qt 6.8.3, the recommended FFmpeg version is 7.1:
#     https://doc.qt.io/qt-6.8/qtmultimedia-index.html#target-platform-and-backend-notes
# This script is based on the instructions at:
#     https://doc.qt.io/qt-6.8/qtmultimedia-building-ffmpeg-linux.html

set -e

INSTALL_DIR=$1

cd /tmp
git clone --branch n12.2.72.0 https://github.com/FFmpeg/nv-codec-headers.git nv-codec-headers
cd nv-codec-headers
make -j install

cd /tmp
git clone --branch n7.1.1 https://git.ffmpeg.org/ffmpeg.git ffmpeg
cd ffmpeg
mkdir build
cd build
../configure --prefix=${INSTALL_DIR} --disable-doc --enable-network --enable-shared
make -j install

cd /tmp
rm -rf nv-codec-headers ffmpeg