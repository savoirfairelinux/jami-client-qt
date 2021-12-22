#!/bin/bash

# Take the package to add as argument ./sparkle-xml-updater.sh jami.dmg

REPO_FOLDER=$1
SPARKLE_FILE=$2
REPO_URL=$3
PACKAGE=$4
DSA_KEY=$5
CHANNEL_NAME=$6
VERSION=$7
BUILD=$8

if [ ! -f ${PACKAGE} -o ! -f ${DSA_KEY} ]; then
    echo "Can't find package or dsa key, aborting..."
    exit 1
fi

if [ -f ${REPO_FOLDER}/${SPARKLE_FILE} ]; then
    ITEMS=$(sed -n "/<item>/,/<\/item>/p" ${REPO_FOLDER}/${SPARKLE_FILE})
fi

PACKAGE_SIZE=`stat -f%z ${PACKAGE}`
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
            <sparkle:minimumSystemVersion>10.13</sparkle:minimumSystemVersion>
            <enclosure url="${REPO_URL}/$(basename ${PACKAGE})" length="$PACKAGE_SIZE" type="application/octet-stream" sparkle:dsaSignature="$(./sign_update.sh ${PACKAGE} ${DSA_KEY})" />
        </item>
$(echo -e "${ITEMS}")
    </channel>
</rss>
EOFILE

