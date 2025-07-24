#!/usr/bin/env bash
#
# Copyright (C) 2025 Savoir-faire Linux Inc.
#
# This script updates the release version and date in the metainfo file.
# Maintaining the list of releases on Flathub is mandatory.
# 
# Usage:
#   ./update-metainfo.sh                    # Add all stable/* releases
#   MAX_RELEASES=10 ./update-metainfo.sh    # Limit to 10 most recent stable releases
#
# The script:
# 1. Searches for all stable/* git tags in the repository
# 2. Converts version strings (YYYYMMDD.X) to proper date format (YYYY-MM-DD) 
# 3. Generates changelog URLs pointing to the wiki
# 4. Adds new releases to the metainfo.xml file (skips existing ones)
# 5. Optionally limits to MAX_RELEASES most recent releases
#

set -e

# Path to the metainfo file
METAINFO_FILE="extras/data/net.jami.Jami.metainfo.xml"

# Maximum number of releases to keep (optional, set to 0 for unlimited)
MAX_RELEASES=${MAX_RELEASES:-0}

# Function to convert version string to date format (YYYYMMDD.X -> YYYY-MM-DD)
version_to_date() {
    local version="$1"
    # Extract the date part (before any dot)
    local date_part="${version%%.*}"
    
    # Validate date format (should be YYYYMMDD)
    if [[ ! "$date_part" =~ ^[0-9]{8}$ ]]; then
        echo "Warning: Invalid date format in version $version" >&2
        return 1
    fi
    
    # Format as YYYY-MM-DD
    echo "${date_part:0:4}-${date_part:4:2}-${date_part:6:2}"
}

# Function to generate changelog URL for a version
generate_changelog_url() {
    local version="$1"
    echo "https://git.jami.net/savoirfairelinux/jami-client-qt/-/wikis/Changelog#nightlystable-${version}"
}

# Function to check if a release already exists in metainfo
release_exists() {
    local version="$1"
    grep -q "release version=\"${version}\"" "$METAINFO_FILE"
}

# Function to add a new release entry (adds after <releases> tag)
add_release() {
    local version="$1"
    local date="$2"
    local url="$3"
    
    # Create the release entry with proper indentation
    local release_entry="    <release version=\"${version}\" date=\"${date}\">\n      <url type=\"details\">${url}</url>\n    </release>"
    
    # Find the line with <releases> and add after it
    sed -i "/<releases>/a\\
${release_entry}" "$METAINFO_FILE"
}

echo "Updating metainfo.xml with new stable releases..."

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

# Check if metainfo file exists
if [[ ! -f "$METAINFO_FILE" ]]; then
    echo "Error: Metainfo file not found: $METAINFO_FILE" >&2
    exit 1
fi

# Get all stable/* tags from git, sorted by version (newest first)
stable_tags=$(git tag | grep "^stable/" | sort -Vr)

if [[ -z "$stable_tags" ]]; then
    echo "No stable/* tags found in repository"
    exit 0
fi

# Counter for new releases added
new_releases=0
processed_releases=0

# Process each stable tag (newest first)
for tag in $stable_tags; do
    # If MAX_RELEASES is set and we've processed enough releases, stop
    if [[ $MAX_RELEASES -gt 0 && $processed_releases -ge $MAX_RELEASES ]]; then
        echo "Reached maximum of $MAX_RELEASES releases, stopping..."
        break
    fi
    
    # Extract version from tag (remove "stable/" prefix)
    version="${tag#stable/}"
    
    # Check if this release already exists in metainfo
    if release_exists "$version"; then
        echo "Release $version already exists, skipping..."
        processed_releases=$((processed_releases + 1))
        continue
    fi
    
    # Convert version to date format
    if ! date=$(version_to_date "$version"); then
        echo "Skipping $version due to invalid date format"
        continue
    fi
    
    # Generate changelog URL
    url=$(generate_changelog_url "$version")
    
    echo "Adding new release: $version (date: $date)"
    add_release "$version" "$date" "$url"
    new_releases=$((new_releases + 1))
    processed_releases=$((processed_releases + 1))
done

echo "Added $new_releases new releases to metainfo.xml"
echo "Metainfo update complete!"

# Show the updated releases section
echo ""
echo "Current releases section:"
sed -n '/<releases>/,/<\/releases>/p' "$METAINFO_FILE"

