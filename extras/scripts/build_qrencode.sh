#!/usr/bin/env bash
set -e  # Exit immediately if a command exits with a non-zero status

# Usage:
# ./build_qrencode.sh -a <architecture>
# Accepted architectures: arm64, x86_64, unified

arch=''
while getopts "a:" OPT; do
  case "$OPT" in
    a)
      arch="${OPTARG}"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "Usage: $0 [-a architecture]"
      echo "Accepted architectures: arm64, x86_64, unified"
      exit 1
      ;;
  esac
done

# Determine architectures to build
if [[ "$arch" == 'unified' ]]; then
  ARCHS=("arm64" "x86_64")
elif [[ "$arch" == '' ]]; then
  # Detect host architecture
  HOST_ARCH=$(uname -m)
  case "$HOST_ARCH" in
    x86_64|arm64)
      ARCHS=("$HOST_ARCH")
      ;;
    *)
      echo "Unsupported host architecture: $HOST_ARCH"
      echo "Supported architectures are: arm64, x86_64, unified"
      exit 1
      ;;
  esac
else
  # Validate specified architecture
  case "$arch" in
    x86_64|arm64)
      ARCHS=("$arch")
      ;;
    *)
      echo "Invalid architecture specified: $arch"
      echo "Accepted architectures are: arm64, x86_64, unified"
      exit 1
      ;;
  esac
fi

TOP="$(pwd)"
QRENCODEDIR="${TOP}/3rdparty/libqrencode"

cd "$QRENCODEDIR" || { echo "Failed to navigate to $QRENCODEDIR"; exit 1; }

echo "Running autogen.sh..."
./autogen.sh

# Iterate over each architecture
for ARCH in "${ARCHS[@]}"; do
  echo "--------------------------------------------"
  echo "Building libqrencode for architecture: $ARCH"
  echo "--------------------------------------------"

  BUILDDIR="${ARCH}-libqrencode"
  mkdir -p "$BUILDDIR"
  cd "$BUILDDIR" || { echo "Failed to navigate to $BUILDDIR"; exit 1; }

  # Clean previous builds within the build directory
  if [ -f "Makefile" ]; then
    echo "Cleaning previous build in $BUILDDIR..."
    make clean || true
  fi

  # Configure the build for the specific architecture
  echo "Configuring for architecture: $ARCH..."
  ../configure \
    --host="$ARCH" \
    --without-png \
    --prefix="$(pwd)" \
    CFLAGS="-arch $ARCH $CFLAGS"

  # Compile using single-threaded make to avoid race conditions
  echo "Compiling for architecture: $ARCH..."
  make -j1

  # Install the compiled binaries
  echo "Installing for architecture: $ARCH..."
  make install

  # Navigate back to the main source directory
  cd "$QRENCODEDIR" || { echo "Failed to navigate back to $QRENCODEDIR"; exit 1; }
done

# Prepare directories for libraries and includes
mkdir -p "$QRENCODEDIR/lib"
mkdir -p "$QRENCODEDIR/include"

# Combine libraries if building for multiple architectures
if ((${#ARCHS[@]} == 2)); then
  echo "Creating fat libraries for architectures: ${ARCHS[0]} and ${ARCHS[1]}"
  LIBFILES="$QRENCODEDIR/${ARCHS[0]}-libqrencode/lib/*.a"
  for f in $LIBFILES; do
    libFile=${f##*/}
    echo "Creating fat library for $libFile"
    lipo -create \
      "$QRENCODEDIR/${ARCHS[0]}-libqrencode/lib/$libFile" \
      "$QRENCODEDIR/${ARCHS[1]}-libqrencode/lib/$libFile" \
      -output "${QRENCODEDIR}/lib/$libFile"
  done
else
  echo "No need to create fat libraries. Copying static libraries."
  rsync -ar --delete "$QRENCODEDIR/${ARCHS[0]}-libqrencode/lib/"*.a "${QRENCODEDIR}/lib/"
fi

# Sync include files
rsync -ar --delete "$QRENCODEDIR/${ARCHS[0]}-libqrencode/include/"* "${QRENCODEDIR}/include/"

echo "Build process completed successfully."
