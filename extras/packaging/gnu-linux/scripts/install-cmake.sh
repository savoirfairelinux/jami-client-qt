#!/usr/bin/env bash

set -e

if command -v apt-get &> /dev/null
then
    apt-get remove cmake cmake-data -y
fi

wget https://github.com/Kitware/CMake/releases/download/v3.22.5/cmake-3.22.5-Linux-x86_64.sh \
      -q -O /tmp/cmake-install.sh
echo "5860b0d9c5610dc63a60ed8bf53fe56d4d93ea7d1bd13327edcce08eab5fb5fc  /tmp/cmake-install.sh" | sha256sum --check
chmod u+x /tmp/cmake-install.sh
/tmp/cmake-install.sh --skip-license --prefix=/usr/local/
rm /tmp/cmake-install.sh