#!/bin/sh
#
# Copyright (C) 2024 Savoir-faire Linux Inc.
#
# Author: Amin Bandali <amin.bandali@savoirfairelinux.com>
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
# This script is used in the packaging containers to build a snap
# package on an ubuntu base distro.

if [ $# -gt 1 ]; then
    echo "Usage: $0 {stable,beta,nightly}"
    exit 1
fi

# default to stable if no release type given
release_type=${1:-stable}

last_commit_date=$(git log -1 --format=%cd --date=format:'%Y%m%d')
same_day_releases=$(git tag -l "${release_type}/${last_commit_date}*" | wc -l)
release_counter=${same_day_releases:-0}
release_version=${last_commit_date}.${release_counter}
printf "${release_version}"
