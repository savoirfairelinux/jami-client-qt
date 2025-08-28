#!/usr/bin/env bash

# The purpose of this script is to build PipeWire from source in a snap based on core22 / Ubuntu 22.04
# It must be called in the "override-build" section of the relevant part in snapcraft.yaml

set -e

OLD_WD=$(pwd)
cd /tmp

# Build PipeWire 1.0.5 and install it in the /usr directory of the build environment
wget -q https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/1.0.5/pipewire-1.0.5.tar.gz
echo "c5a5de26d684a1a84060ad7b6131654fb2835e03fccad85059be92f8e3ffe993  pipewire-1.0.5.tar.gz" | sha256sum --check
tar xzf pipewire-1.0.5.tar.gz
cd pipewire-1.0.5
meson setup builddir -Dsession-managers=media-session -Dalsa=disabled -Dprefix=/usr
meson compile -C builddir
meson install -C builddir

# The files installed by the previous command are only for the "Build" step of the snap
# creation process (https://snapcraft.io/docs/how-snapcraft-builds). In order to ensure
# that PipeWire is installed in the final snap archive, we also need to copy all the
# required files under the $CRAFT_PART_INSTALL directory.
meson configure builddir -Dprefix=$CRAFT_PART_INSTALL/usr/
meson install -C builddir

# Cleanup
cd /tmp
rm -rf pipewire-1.0.5  pipewire-1.0.5.tar.gz
cd $OLD_WD