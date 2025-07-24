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
#
# Arguments:
# $1 - Version to update to (should be formatted as stable/YYYYMMDD.#)

set -e

VERSION=$1 

# Clone or update the Flathub repository
FLATHUB_REPO_DIR="net.jami.Jami"

#mkdir $FLATHUB_REPO_DIR
if [ ! -d "$FLATHUB_REPO_DIR" ]; then
    echo "Cloning Flathub repository..."
    git clone https://github.com/flathub/net.jami.Jami.git "$FLATHUB_REPO_DIR"
else
    echo "Updating Flathub repository..."
    cd "$FLATHUB_REPO_DIR/"
    git pull origin master
fi

# Configure git to use GitHub CLI for authentication
#gh auth setup-git

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

# Sleep for 30 seconds to allow the PR to be created 
# and for Flathub Vorarbeiter build to get triggered
sleep 30s

# Watch PR checks
echo "Watching PR checks..."
if gh pr checks --watch; then
    echo "Vorarbeiter build succeeded!"
else
    echo "===FLATHUB BUILD FAILED!==="
    echo "Steps to take:\n
          1. Verify that the correct version tag was given to the script\n
          2. Check the build logs from the Flathub CI\n
          3. Check that the Flatpak builds locally on a clean build\n
          4. Put the manifest through the flathub linter"
fi

if gh pr merge --merge --body "Automated merge from script"; then
    echo "Pull request merged successfully!\n
          Official build has now been triggered on Flathub.\n
          Make sure to confirm its existence and success!"
else
    echo "Failed to merge pull request. Check for conflicts!"
fi