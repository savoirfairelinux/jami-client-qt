#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES="${SCRIPT_DIR}/../../resources/images"

# Default matches CMAKE_OSX_DEPLOYMENT_TARGET in CMakeLists.txt.
MIN_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-${CMAKE_OSX_DEPLOYMENT_TARGET:-13.0}}"

PARTIAL_PLIST="$(mktemp "${TMPDIR:-/tmp}/jami-partial-XXXXXX")"
trap 'rm -f "${PARTIAL_PLIST}"' EXIT

cd "${IMAGES}"
xcrun actool AppIcon.icon --compile . --app-icon AppIcon \
  --include-all-app-icons --enable-on-demand-resources NO \
  --target-device mac --platform macosx \
  --minimum-deployment-target "${MIN_DEPLOYMENT_TARGET}" \
  --output-partial-info-plist "${PARTIAL_PLIST}"
rm -f AppIcon.icns
