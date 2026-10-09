#!/usr/bin/env bash
#
# Install Node.js from the NodeSource repository on Debian-based
# distributions whose own nodejs package is too old for QtWebEngine
# (Qt 6.12 requires Node.js >= 20).

set -e

VERSION=$1

apt-get install -y -o Acquire::Retries=10 ca-certificates curl gnupg
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${VERSION}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y -o Acquire::Retries=10 nodejs
