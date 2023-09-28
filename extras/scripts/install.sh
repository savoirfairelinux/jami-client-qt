#!/usr/bin/env bash
# install.sh --- build and install Jami daemon and client

# Copyright (C) 2016-2023 Savoir-faire Linux Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.

# Build and install to a local prefix under this repository.
export OSTYPE

# Flags:

  # -g: install globally instead for all users
  # -s: link everything statically, no D-Bus communication. More likely to work!
  # -p: number of processors to use
  # -u: disable use of privileges (sudo) during install
  # -W: disable libwrap and shared library
  # -w: do not use Qt WebEngine
  # -a: arch to build

set -ex

# Qt_MIN_VER required for client-qt
QT_MIN_VER="6.4"

debug=
global=false
static=''
qtpath=''
proc='1'
priv_install=true
enable_libwrap=true
enable_webengine=true
arch=''

while getopts gsc:dQ:P:p:uWwa: OPT; do
  case "$OPT" in
    g)
      global='true'
    ;;
    s)
      static='-DENABLE_STATIC=true'
    ;;
    d)
      debug=true
    ;;
    Q)
      qtpath="${OPTARG}"
    ;;
    P)
      prefix="${OPTARG}"
    ;;
    p)
      proc="${OPTARG}"
    ;;
    u)
      priv_install='false'
    ;;
    W)
      enable_libwrap='false'
    ;;
    w)
      enable_webengine='false'
    ;;
    a)
      arch="${OPTARG}"
    ;;
    \?)
      exit 1
    ;;
  esac
done

# $1: global-install?
# $2: private-install?
make_install() {
  if [ "$1" = "true" ] && [ "$2" != "false" ]; then
    sudo make install
    # Or else the next non-sudo install will fail, because this generates some
    # root owned files like install_manifest.txt under the build directory.
    sudo chown -R "$USER" .
  else
    make install
  fi
}

TOP="$(pwd)"
INSTALL_DIR="${TOP}/install"    # local install directory

if [ "${global}" = "true" ]; then
    BUILD_DIR="build-global"
else
    BUILD_DIR="build"
fi

# jamid
DAEMON="${TOP}/daemon"
if [[ "$OSTYPE" == "darwin"* ]]; then
    sh "${TOP}"/extras/scripts/build_daemon_macos.sh -a "$arch" -d "$debug"
else
    cd "$DAEMON"

    # Build the contribs.
    mkdir -p contrib/native
    (
        cd contrib/native
        ../bootstrap ${prefix:+"--prefix=$prefix"}
        make -j"${proc}"
    )

    if [[ "${enable_libwrap}" != "true" ]]; then
      # Disable shared if requested
      if [[ "$OSTYPE" != "darwin"* ]]; then
        CONFIGURE_FLAGS+=" --disable-shared"
      fi
    else
        CONFIGURE_FLAGS+=" --without-dbus"
    fi

    BUILD_TYPE="Release"
    if [ "${debug}" = "true" ]; then
      BUILD_TYPE="Debug"
      CONFIGURE_FLAGS+=" --enable-debug"
    fi

    # Build the daemon itself.
    test -f configure || ./autogen.sh

    if [ "${global}" = "true" ]; then
        ./configure ${CONFIGURE_FLAGS} ${prefix:+"--prefix=$prefix"}
    else
        ./configure ${CONFIGURE_FLAGS} --prefix="${INSTALL_DIR}"
    fi
    make -j"${proc}" V=1
    make_install "${global}" "${priv_install}"

    # Verify system's version if no path provided.
    if [ -z "$qtpath" ]; then
        sys_qtver=""
        if command -v qmake6 &> /dev/null; then
            sys_qtver=$(qmake6 -v)
        elif command -v qmake-qt6 &> /dev/null; then
            sys_qtver=$(qmake-qt6 -v) # Fedora
        elif command -v qmake &> /dev/null; then
            sys_qtver=$(qmake -v)
        else
            echo "No valid Qt found"; exit 1;
        fi

        sys_qtver=${sys_qtver#*Qt version}
        sys_qtver=${sys_qtver%\ in\ *}

        installed_qtver=$(echo "$sys_qtver" | cut -d'.' -f 2)
        required_qtver=$(echo $QT_MIN_VER | cut -d'.' -f 2)

        if [[ $installed_qtver -ge $required_qtver ]] ; then
            # Set qtpath to empty in order to use system's Qt.
            qtpath=""
        else
            echo "No valid Qt found"; exit 1;
        fi
    fi
fi

# client
cd "${TOP}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

client_cmake_flags=(-DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
                    -DCMAKE_PREFIX_PATH="${qtpath}"
                    -DENABLE_LIBWRAP="${enable_libwrap}"
                    -DWITH_WEBENGINE="${enable_webengine}")
if [[ "$OSTYPE" == "darwin"* ]]; then
    #detect arch for macos
    CMAKE_OSX_ARCHITECTURES="arm64"
    if [[ "$arch" == 'unified' ]]; then
        CMAKE_OSX_ARCHITECTURES="x86_64;arm64"
    elif [[ "$arch" != '' ]]; then
        CMAKE_OSX_ARCHITECTURES="$arch"
    fi
    client_cmake_flags+=(-DCMAKE_OSX_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES}")
    # build qrencode
    (
        cd ${TOP}
        ./extras/scripts/build_qrencode.sh -a "$arch"
    )
fi

if [ "${global}" = "true" ]; then
    client_cmake_flags+=(${prefix:+"-DCMAKE_INSTALL_PREFIX=$prefix"}
                         $static)
else
    client_cmake_flags+=(-DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
                         -DWITH_DAEMON_SUBMODULE=true)
fi

echo "info: Configuring $client client with flags: ${client_cmake_flags[*]}"
cmake .. "${client_cmake_flags[@]}"
make -j"${proc}" V=1
make_install "${global}" "${priv_install}"
