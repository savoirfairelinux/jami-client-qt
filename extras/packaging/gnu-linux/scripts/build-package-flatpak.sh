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
# stable version through a pull request. We do not publish nightly/beta 
# releases to Flathub for the time being.
#
# ARGUMENTS:
# $1 - RELEASE NAME. (should be formatted as stable/YYYYMMDD.#)

set -e

# Functions that print the script name before output with colour 
# (for legibility purposes)
log()
{
    echo -e "\033[34m$0:\033[0m $1"
}

log_err()
{
    echo -e "\033[31m$0:\033[0m $1"
}

log_success()
{
    echo -e "\033[32m$0:\033[0m $1"
}

# Represents the new stable release
RELEASE_NAME=$1

# Install/update the flatpak package
log "Installing flatpak package"
sudo apt-get -y install flatpak

if [[ $? == 0 ]]; then
    log_success "Successfully installed/updated flatpak package"
else
    log_err "Error installing flatpak package!" >&2
    exit 1
fi

# Add the flathub repository 
# Install/update the flatpak-builder FROM flathub
log "Installing flatpak-builder"
flatpak install -y flathub org.flatpak.Builder --user

# This is the name of the Jami repository for Flathub
# It is always the rDNS of the application ID and should NOT be changed
# See https://docs.flathub.org/docs/for-app-authors/requirements#application-id
readonly FLATHUB_REPO_DIR="net.jami.Jami"

# Checkout whether or not repository already exists
if [ ! -d "$FLATHUB_REPO_DIR" ]; then
    log "Cloning Flathub repository..."
    git clone https://github.com/flathub/net.jami.Jami.git $FLATHUB_REPO_DIR
    # Navigate to the cloned repository
    cd "$(pwd)/$FLATHUB_REPO_DIR/"
else
    # Repository already exists, update it
    log "Updating Flathub repository..."
    cd "$FLATHUB_REPO_DIR"
    git pull origin master
fi

# .. needed since were in the repository right now
# Arguments WILL propogate to this script
source ../update-flatpak-dep-versions.sh

# =========================

# # Configure git to use GitHub CLI for authentication
# gh auth setup-git

# # Navigate to origin/master
# git pull origin master
# git checkout master

# # Create new branch for new stable version
# git checkout -b $VERSION

# # Modify stable tag to match newest release
# sed -i "s|stable\/.*|$VERSION|" net.jami.Jami.yml

# # Add the modified file and commit changes
# git add net.jami.Jami.yml
# git commit -m "Update Jami to $VERSION"

# # Push the branch to origin
# echo "Pushing branch $VERSION to origin..."
# git push --set-upstream origin $VERSION

# # Create pull request
# echo "Creating pull request..."
# gh pr create --base master --head $VERSION --title "Update Jami to $VERSION" --body "Automated update to version $VERSION"

# echo ""
# echo "Changes made:"
# git show --name-only HEAD
# echo ""
# echo "File changes:"
# git diff HEAD~1 HEAD

