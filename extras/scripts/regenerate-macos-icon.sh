#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES="${SCRIPT_DIR}/../../resources/images"

if [[ -z "${MACOSX_DEPLOYMENT_TARGET:-}" ]]; then
    echo "error: MACOSX_DEPLOYMENT_TARGET must be set (e.g. export MACOSX_DEPLOYMENT_TARGET)" >&2
    exit 1
fi
MIN_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}"

PARTIAL_PLIST="$(mktemp "${TMPDIR:-/tmp}/jami-partial-XXXXXX")"
trap 'rm -f "${PARTIAL_PLIST}"' EXIT

cd "${IMAGES}"
xcrun actool AppIcon.icon --compile . --app-icon AppIcon \
  --include-all-app-icons --enable-on-demand-resources NO \
  --target-device mac --platform macosx \
  --minimum-deployment-target "${MIN_DEPLOYMENT_TARGET}" \
  --output-partial-info-plist "${PARTIAL_PLIST}"
rm -f AppIcon.icns
