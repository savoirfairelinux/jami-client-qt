#!/usr/bin/env bash
#
# Copyright (C) 2025 Savoir-faire Linux Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This script is used to fetch the flatpak version from the official
# Flathub repo, updates it to the appropriate branch and publish a new
# version through a pull request

set -e

VERSION=$1 # (should be formatted as stable/YYYYMMDD.#)

# Clone or update the Flathub repository
FLATHUB_REPO_DIR="net.jami.Jami"

#mkdir $FLATHUB_REPO_DIR

if [ ! -d "$FLATHUB_REPO_DIR" ]; then
    echo "Cloning Flathub repository..."
    git clone https://github.com/flathub/net.jami.Jami.git "$FLATHUB_REPO_DIR"
else
    echo "Updating Flathub repository..."
    cd "$FLATHUB_REPO_DIR"
    git pull origin master
fi

cd "$FLATHUB_REPO_DIR"

# Configure git to use GitHub CLI for authentication
gh auth setup-git

# Navigate to origin/master
git pull origin master
git checkout master

# Create new branch for new stable version
git checkout -b $VERSION

# Modify stable tag to match newest release
sed -i "s|stable\/.*|$VERSION|" net.jami.Jami.yml

# Add the modified file and commit changes
git add net.jami.Jami.yml
git commit -m "Update Jami to $VERSION"

# Push the branch to origin
echo "Pushing branch $VERSION to origin..."
git push --set-upstream origin $VERSION

# Create pull request
echo "Creating pull request..."
gh pr create --base master --head $VERSION --title "Update Jami to $VERSION" --body "Automated update to version $VERSION"

echo ""
echo "Changes made:"
git show --name-only HEAD
echo ""
echo "File changes:"
git diff HEAD~1 HEAD

