#!/usr/bin/env bash

# Flags:

TOP="$(pwd)"
HUNSPELLDIR="${TOP}/3rdparty/hunspell"

cd "$HUNSPELLDIR" || exit 1
autoreconf -vfi
./configure
make -j
