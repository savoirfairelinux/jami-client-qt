#!/usr/bin/env bash

# Flags:

# -a: architecture to build. Accepted values arm64, x86_64, unified
# -d: debug
set -e

arch=''
debug=
while getopts "a:d:" OPT; do
  case "$OPT" in
  a)
    arch="${OPTARG}"
    ;;
  d)
    debug=true
    ;;
  \?)
    exit 1
    ;;
  esac
done

if [[ "$arch" == 'unified' ]]; then
  echo "unified build"
  ARCHS=("arm64" "x86_64")
elif [[ "$arch" == '' ]]; then
  ARCHS=("arm64")
else
  ARCHS=("$arch")
fi

TOP="$(pwd)"
INSTALL="${TOP}/install"
OS_VER=$(uname -r)

DAEMON=${TOP}/daemon
cd "$DAEMON"

FAT_CONTRIB_DIR=$DAEMON/contrib/apple-darwin
mkdir -p "$FAT_CONTRIB_DIR"
# build contrib for every arch
for ARCH in "${ARCHS[@]}"; do
  HOST="${ARCH}-apple-darwin${OS_VER}"
  mkdir -p contrib/native-"${ARCH}"
  (
    cd contrib/native-"${ARCH}"
    ../bootstrap --host="$HOST"

    echo "Building contrib for $ARCH"
    # force to build every contrib
    for dir in "$DAEMON"/contrib/src/*/; do
      PKG=$(basename -- "$dir")
      if [ "$PKG" != "sdbus-cpp" ] && [ "$PKG" != "freetype" ] &&
        [ "$PKG" != "portaudio" ] && [ "$PKG" != "pthreads" ] &&
        [ "$PKG" != "lttng-ust" ] && [ "$PKG" != "openssl" ] &&
        [ "$PKG" != "media-sdk" ] && [ "$PKG" != "jack" ] &&
        [ "$PKG" != "onnx" ] && [ "$PKG" != "opencv" ] &&
        [ "$PKG" != "opencv_contrib" ] && [ "$PKG" != "uuid" ] &&
        [ "$PKG" != "webrtc-audio-processing" ] && [ "$PKG" != "liburcu" ]; then
        make -j"$NPROC" ."$PKG"
      fi
    done
  )
done

# make fat libs for contrib
mkdir -p "$FAT_CONTRIB_DIR"/lib
if ((${#ARCHS[@]} == "2")); then
  echo "Making fat lib for ${ARCHS[0]} and ${ARCHS[1]}"
  LIBFILES="$DAEMON/contrib/${ARCHS[0]}-apple-darwin$OS_VER/lib/*".a
  for f in $LIBFILES; do
    # filter out arch from file name
    arch0=${ARCHS[0]}
    if [ "$arch0" = "arm64" ]; then
      arch0="aarch64"
    fi
    # file name for first arch
    libfile0=${f##*/}
    # file name without arch
    libfile="${libfile0//"-$arch0"/}"
    # replace arch0 with ARCHS[1] to get file name for second arch
    libfile1="${libfile0//$arch0/${ARCHS[1]}}"
    echo "Processing $libfile from $libfile0 and $libfile1 $ lib..."
    lipo -create "$DAEMON/contrib/${ARCHS[0]}-apple-darwin$OS_VER/lib/$libfile0" \
      "$DAEMON/contrib/${ARCHS[1]}-apple-darwin$OS_VER/lib/$libfile1" \
      -output "$FAT_CONTRIB_DIR/lib/$libfile"
  done
else
  echo "No need for fat lib"
  rsync -ar --delete "$DAEMON/contrib/${ARCHS[0]}-apple-darwin$OS_VER/lib/"*.a "$FAT_CONTRIB_DIR/lib"
fi

rsync -ar --delete "$DAEMON/contrib/${ARCHS[0]}-apple-darwin$OS_VER/include"* "$FAT_CONTRIB_DIR/"

# build deamon for every arch
for ARCH in "${ARCHS[@]}"; do
  echo "$ARCH"
  cd "$DAEMON"
  HOST="${ARCH}-apple-darwin"
  SDKROOT=$(xcrun --sdk macosx --show-sdk-path)

  CC="xcrun -sdk macosx clang"
  CXX="xcrun -sdk macosx clang++"
  CFLAGS="-arch $ARCH -isysroot $SDKROOT"
  CXXFLAGS="-std=c++17 $CFLAGS"
  CONFIGURE_FLAGS=" --without-dbus --host=${HOST} -with-contrib=$DAEMON/contrib/${ARCH}-apple-darwin${OS_VER} --prefix=${INSTALL}/daemon/$ARCH"

  if [ "${debug}" = "true" ]; then
    CONFIGURE_FLAGS+=" --enable-debug"
  fi

  echo "$CONFIGURE_FLAGS"
  ./autogen.sh || exit

  # We need to copy this file or else it's just an empty file
  rsync -a "$DAEMON"/src/buildinfo.cpp ./src/buildinfo.cpp
  mkdir -p "build-macos-${ARCH}"
  cd "build-macos-${ARCH}"

  "$DAEMON"/configure $CONFIGURE_FLAGS ARCH="$ARCH" \
    CC="$CC $CFLAGS" \
    CXX="$CXX $CXXFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" || exit 1

  echo "$CONFIGURE_FLAGS"

  rsync -a "$DAEMON"/src/buildinfo.cpp ./src/buildinfo.cpp

  make -j"$NPROC" || exit 1
  make install || exit 1
  cd "$DAEMON"
done

# make fat lib for daemon
FAT_INSTALL_DIR="${INSTALL}"/daemon/
mkdir -p "${FAT_INSTALL_DIR}"

if ((${#ARCHS[@]} == "2")); then
  echo "Creating daemon fat lib"
  mkdir -p "$FAT_INSTALL_DIR"/lib
  lipo -create "${INSTALL}/daemon/${ARCHS[0]}/lib/libjami.a" \
    "${INSTALL}/daemon/${ARCHS[1]}/lib/libjami.a" \
    -output "${FAT_INSTALL_DIR}"/lib/libjami.a
else
  echo "No need for daemon fat lib"
  rsync -ar --delete "${INSTALL}/daemon/${ARCHS[0]}/lib/libjami.a" "${FAT_INSTALL_DIR}"/lib/
fi

rsync -ar --delete "${INSTALL}/daemon/${ARCHS[0]}/include/"* "$FAT_INSTALL_DIR"/include
