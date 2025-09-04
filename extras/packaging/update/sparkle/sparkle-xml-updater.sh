#!/bin/bash

# Take the package to add as argument ./sparkle-xml-updater.sh jami.dmg

REPO_FOLDER=$1
SPARKLE_FILE=$2
REPO_URL=$3
PACKAGE=$4
CHANNEL_NAME=$5
VERSION=$6
BUILD=$7

if [ ! -f ${PACKAGE} ]; then
    echo "Can't find package, aborting..."
    exit 1
fi

if [ -f ${REPO_FOLDER}/${SPARKLE_FILE} ]; then
    ITEMS=$(sed -n "/<item>/,/<\/item>/p" ${REPO_FOLDER}/${SPARKLE_FILE})
fi

DATE_RFC2822=`date "+%a, %d %b %Y %T %z"`

cat << EOFILE > ${REPO_FOLDER}/${SPARKLE_FILE}
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>${CHANNEL_NAME}</title>
        <link>${REPO_URL}/${SPARKLE_FILE}</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        <item>
            <title>"${CHANNEL_NAME}-${BUILD}"</title>
            <pubDate>$DATE_RFC2822</pubDate>
            <sparkle:version>${BUILD}</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>12.0</sparkle:minimumSystemVersion>
            <enclosure url="${REPO_URL}/$(basename ${PACKAGE})" type="application/octet-stream" $(./sign_update ${PACKAGE}) />
        </item>
$(echo -e "${ITEMS}")
    </channel>
</rss>
EOFILE

