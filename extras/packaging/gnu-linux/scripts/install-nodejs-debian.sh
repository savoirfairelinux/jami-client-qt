#!/usr/bin/env bash
#
# Install Node.js from the NodeSource repository on Debian-based
# distributions whose own nodejs package is too old for QtWebEngine
# (Qt 6.12 requires Node.js >= 20).

set -e

VERSION=$1
if [[ ! "${VERSION}" =~ ^[0-9]+$ ]]; then
    echo "usage: $0 <nodejs-major-version>" >&2
    exit 1
fi

# https://github.com/nodesource/distributions#debian-and-ubuntu-based-distributions
KEY_URL=https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key
KEY_FINGERPRINT=6F71F525282841EEDAF851B42F59B5F99B1BE0B4

apt-get update
apt-get install -y -o Acquire::Retries=10 ca-certificates curl gnupg

key=$(mktemp)
curl -fsSL "${KEY_URL}" -o "${key}"
if ! gpg --show-keys --with-colons "${key}" | grep -q "^fpr:*${KEY_FINGERPRINT// /}:"; then
    echo "error: unexpected NodeSource key fingerprint" >&2
    exit 1
fi
install -d -m 0755 /etc/apt/keyrings
gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg "${key}"
rm -f "${key}"

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${VERSION}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y -o Acquire::Retries=10 nodejs
