#!/bin/bash
export LD_LIBRARY_PATH=$PWD/build/daemon:$PWD/build/src/libclient/qtwrapper:$PWD/build/src/libclient
./build/src/modern/jami-modern
