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
# This script is used to publish a new version of Jami to Flathub.
# It will replace the tag to build and create a pull request on the
# official GitHub repository. The script will wait for the test build
# to complete and succeed on Flathub's infrastructure and will merge it
# onto the master branch to trigger an official build and publish to the
# store.
#
# The script assumes an existing installation of the GitHub CLI package
# (gh) that is authenticated via a token generated from a GitHub user with
# collaborator permissions.
#
# Arguments:
# $1 - Version to update to (should be formatted as stable/YYYYMMDD.#)
# $2 - Location of net.jami.Jami repository

set -e

VERSION=$1

# Clone or update the Flathub repository
FLATHUB_REPO_DIR=$2

#mkdir $FLATHUB_REPO_DIR
if [ -d "$FLATHUB_REPO_DIR" ]; then
    echo "net.jami.Jami repo found!"
    cd "$FLATHUB_REPO_DIR"
else
    echo "Missing net.jami.Jami repo! Directory not found."
    exit 1
fi

# Navigate to origin/master
git pull origin master
git checkout origin/master

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
gh pr create --base master --head $VERSION --title "Update Jami to $VERSION" --body "Automated update to version $VERSION" --label "Jenkins"

# Sleep for 30 seconds to allow the PR to be created
# and for Flathub Vorarbeiter build to get triggered
sleep 30s

# Watch PR checks
echo "Watching PR checks..."
if gh pr checks --watch; then
    echo "Vorarbeiter build succeeded!"
else
    echo "===FLATHUB BUILD FAILED!==="
    echo "Steps to take:
          1. Verify that the correct version tag was given to the script
          2. Check the build logs from the Flathub CI
          3. Check that the Flatpak builds locally on a clean build
          4. Put the manifest through the flathub linter"
    exit 1
fi

if gh pr merge --merge --body "Automated merge from script"; then
    echo "Pull request merged successfully!
          Official build has now been triggered on Flathub.
          Make sure to confirm its existence and success!"
else
    echo "Failed to merge pull request. Check for conflicts!"
fi