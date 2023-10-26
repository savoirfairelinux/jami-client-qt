#!/usr/bin/env bash

set -e

if command -v apt-get &> /dev/null
then
    apt-get remove cmake cmake-data -y
fi

wget https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-3.21.4-linux-x86_64.sh\
      -q -O /tmp/cmake-install.sh
echo "63cb3406f5320edc94504212fe75e8625751ec21e8d5dab76d8ed67ed780066e  /tmp/cmake-install.sh" | sha256sum --check
chmod u+x /tmp/cmake-install.sh
/tmp/cmake-install.sh --skip-license --prefix=/usr/local/
rm /tmp/cmake-install.sh