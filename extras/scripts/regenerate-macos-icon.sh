#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES="${SCRIPT_DIR}/../../resources/images"

cd "${IMAGES}"
xcrun actool AppIcon.icon --compile . --app-icon AppIcon \
  --include-all-app-icons --enable-on-demand-resources NO \
  --target-device mac --platform macosx \
  --minimum-deployment-target 13.0 \
  --output-partial-info-plist /tmp/jami-partial.plist
rm -f AppIcon.icns
