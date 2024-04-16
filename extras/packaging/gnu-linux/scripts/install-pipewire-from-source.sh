#!/usr/bin/env bash

set -e
cd /tmp

# Install PipeWire build dependencies
apt-get install --yes gcc git libasound2-dev libdbus-1-dev libglib2.0-dev ninja-build pkg-config

# Get a version of Meson that's recent enough to build PipeWire 1.0.5 (the one available via apt is too old)
wget -q https://github.com/mesonbuild/meson/releases/download/0.61.1/meson-0.61.1.tar.gz
echo "feb2cefb325b437dbf36146df7c6b87688ddff0b0205caa31dc64055c6da410c  meson-0.61.1.tar.gz" | sha256sum --check
tar xzf meson-0.61.1.tar.gz

# Build and install PipeWire 1.0.5
wget -q https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/1.0.5/pipewire-1.0.5.tar.gz
echo "c5a5de26d684a1a84060ad7b6131654fb2835e03fccad85059be92f8e3ffe993  pipewire-1.0.5.tar.gz" | sha256sum --check
tar xzf pipewire-1.0.5.tar.gz
cd pipewire-1.0.5
python3 ../meson-0.61.1/meson.py setup builddir -Dsession-managers=media-session -Dalsa=disabled -Dprefix=/usr
python3 ../meson-0.61.1/meson.py compile -C builddir
python3 ../meson-0.61.1/meson.py install -C builddir

# Cleanup
rm -rf meson-0.61.1  meson-0.61.1.tar.gz  pipewire-1.0.5  pipewire-1.0.5.tar.gz