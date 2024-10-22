#!/usr/bin/env bash

# The purpose of this script is to build PipeWire from source in a snap based on core20 / Ubuntu 20.04
# It must be called in the "override-build" section of the relevant part in snapcraft.yaml

set -e

OLD_WD=$(pwd)
cd /tmp

# Get a version of Meson that's recent enough to build PipeWire 1.0.5 (the one available via apt is too old)
wget -q https://github.com/mesonbuild/meson/releases/download/0.61.1/meson-0.61.1.tar.gz
echo "feb2cefb325b437dbf36146df7c6b87688ddff0b0205caa31dc64055c6da410c  meson-0.61.1.tar.gz" | sha256sum --check
tar xzf meson-0.61.1.tar.gz

# Build PipeWire 1.0.5 and install it in the /usr directory of the build environment
wget -q https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/1.0.5/pipewire-1.0.5.tar.gz
echo "c5a5de26d684a1a84060ad7b6131654fb2835e03fccad85059be92f8e3ffe993  pipewire-1.0.5.tar.gz" | sha256sum --check
tar xzf pipewire-1.0.5.tar.gz
cd pipewire-1.0.5
../meson-0.61.1/meson.py setup builddir -Dsession-managers=media-session -Dalsa=disabled -Dprefix=/usr
../meson-0.61.1/meson.py compile -C builddir
../meson-0.61.1/meson.py install -C builddir

# The files installed by the previous command are only for the "Build" step of the snap
# creation process (https://snapcraft.io/docs/how-snapcraft-builds). In order to ensure
# that PipeWire is installed in the final snap archive, we also need to copy all the
# required files under the $SNAPCRAFT_PART_INSTALL directory.
../meson-0.61.1/meson.py configure builddir -Dprefix=$SNAPCRAFT_PART_INSTALL/usr/
../meson-0.61.1/meson.py install -C builddir

# Cleanup
cd /tmp
rm -rf meson-0.61.1  meson-0.61.1.tar.gz  pipewire-1.0.5  pipewire-1.0.5.tar.gz
cd $OLD_WD