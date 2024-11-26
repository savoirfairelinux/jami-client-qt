#!/usr/bin/env bash
set -e

# Usage:
# ./build_qrencode.sh -a <architecture>
# Accepted architectures: arm64, x86_64, unified
# If no architecture is specified, the script builds for the host architecture.

# Initialize variables
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
BUILDDIR="${TOP}/build-libqrencode"
LIBDIR="${QRENCODEDIR}/lib"
INCLUDEDIR="${QRENCODEDIR}/include"

# Clean up build directory
echo "Preparing clean build directory..."
rm -rf "$BUILDDIR"
mkdir -p "$BUILDDIR"

# Clean output directories
rm -rf "$LIBDIR" "$INCLUDEDIR"
mkdir -p "$LIBDIR"
mkdir -p "$INCLUDEDIR"

# Convert architectures to semicolon-separated format for cmake
ARCHS_SEMICOLON_SEPARATED=$(IFS=";"; echo "${ARCHS[*]}")

echo "Configuring CMake for architectures: ${ARCHS[*]}..."
cd "$BUILDDIR"
cmake "$QRENCODEDIR" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCHS_SEMICOLON_SEPARATED" \
  -DCMAKE_INSTALL_PREFIX="$QRENCODEDIR" \
  -DWITHOUT_PNG=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -G "Xcode"

echo "Building libqrencode for architectures: ${ARCHS[*]}..."
cmake --build "$BUILDDIR" --config Release

echo "Installing libqrencode to $LIBDIR and $INCLUDEDIR..."
cmake --install "$BUILDDIR" --config Release

echo "Build and installation completed successfully, with outputs in $LIBDIR and $INCLUDEDIR."
