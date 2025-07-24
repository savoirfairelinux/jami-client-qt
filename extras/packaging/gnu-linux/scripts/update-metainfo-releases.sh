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

set -e

# Path to metainfo.xml
METAINFO_LOCATION=$1

echo "METAINFO BEFORE"
cat $METAINFO_LOCATION

echo "Checking validity of metainfo path..."
if [[ ! -f "$METAINFO_LOCATION" ]]; then 
    echo "ERR: Metainfo file at $METAINFO_LOCATION not found!" >&2
    exit 1
fi

# Maximum number of releases to keep (avoid bloating)
MAX_RELEASES=10

# Get MAX_RELEASE most recent releases
echo "Getting latest stable tags from git..."
STABLE_TAGS=$(git tag --sort=-creatordate | grep "^stable/" -m $MAX_RELEASES)

# Verify that stable tags were found 
echo "Checking that stable tags were found..."
if [[ -z "$STABLE_TAGS" ]]; then
    echo "No tags with pattern stable/ found in repo"
    exit 0
else
    printf "Stable tags found:\n$STABLE_TAGS\n"
fi

# Get current line number of <release> tag
# (We need this to know where to start from)
echo "Clearing current release tags..."
RELEASE_TAG_START=$(grep -n "<releases>" $METAINFO_LOCATION | cut -d: -f1)

# Remove the current list of releases
sed -i ':a;N;$!ba;s#  <releases>\n.*</releases>#  <releases>\n  </releases>#g' "$METAINFO_LOCATION"

# Iterate through MAX_RELEASES number of tags and update the release list
echo "Updating metainfo release information..."
for TAG in $STABLE_TAGS; do
    echo "Adding release $TAG"

    # Get version (YYYYMMDD.PATCH_VER)
    VERSION="${TAG:7:10}"

    # Get full date (YYYYMMDD)
    DATE="${TAG:7:8}"

    # Extract year, month and day
    RELEASE_YEAR="${DATE:0:4}"
    RELEASE_MONTH="${DATE:4:2}"
    RELEASE_DATE="${DATE:6:2}"

    # Create changelog URL 
    CHANGELOG_URL="https://git.jami.net/savoirfairelinux/jami-client-qt/-/wikis/Changelog#nightlystable-$DATE"

    ((RELEASE_TAG_START++))
    sed -i "${RELEASE_TAG_START}i\    <release version=\"$VERSION\" date=\"$DATE\">" $METAINFO_LOCATION
    ((RELEASE_TAG_START++))
    sed -i "${RELEASE_TAG_START}i\      <url type=\"details\">$CHANGELOG_URL</url>" $METAINFO_LOCATION
    ((RELEASE_TAG_START++))
    sed -i "${RELEASE_TAG_START}i\    </release>" $METAINFO_LOCATION
done


echo "METAINFO AFTER"
cat $METAINFO_LOCATION