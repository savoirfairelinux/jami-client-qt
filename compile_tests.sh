#!/bin/bash
# Build lrc, client-qt and pass tests

RING_GERRIT_URL="review.jami.net"
GERRIT_REFSPEC_CLIENT="refs/changes/23/16223/6" # test patch not yet merged

# Get number of CPU available
cpuCount=$(nproc || echo -n 4)

# Project directories
topDir=$(pwd)/..
echo "Project root dir: "${topDir}
ls $(pwd)

installDir=$topDir/install
daemonDir=$topDir/daemon
lrcDir=$topDir/lrc
clientDir=$topDir/client-qt

# Build lrc (sources should be already fetched)
cd ${lrcDir}
mkdir -p build
cd build
echo "Building lrc in "$PWD
cmake .. -DCMAKE_INSTALL_PREFIX=$installDir/install/lrc \
      -DRING_INCLUDE_DIR=$daemonDir/src/dring \
      -DRING_XML_INTERFACES_DIR=$daemonDir/bin/dbus
make
make install

# TODO: fetch should be done outside cqfd
cd $clientDir
git fetch "ssh://ababi@review.jami.net:29420/jami-client-qt" refs/changes/23/16223/7 && git checkout FETCH_HEAD

git fetch "https://${RING_GERRIT_URL}/jami-client-qt" ${GERRIT_REFSPEC_CLIENT}
git checkout FETCH_HEAD

# Build client and tests
cd $clientDir
mkdir -p build
cd build
echo "Building client in "$PWD
pandoc -f markdown -t html5 -o ../changelog.html ../changelog.md
cmake ..
make -j${cpuCount}

# Pass Tests
cd tests
./unittests
./qml_tests -input $clientDir/tests/qml
