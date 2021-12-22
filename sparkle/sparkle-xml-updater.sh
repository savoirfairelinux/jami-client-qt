#!/bin/bash

# Take the package to add as argument ./sparkle-xml-updater.sh ring.dmg

REPO_FOLDER=$1
SPARKLE_FILE=$2
REPO_URL=$3
PACKAGE=$4
DSA_KEY=$5

if [ ! -f ${PACKAGE} -o ! -f ${DSA_KEY} ]; then
    echo "Can't find package or dsa key, aborting..."
    exit 1
fi

if [ -f ${REPO_FOLDER}/${SPARKLE_FILE} ]; then
    ITEMS=$(sed -n "/<item>/,/<\/item>/p" ${REPO_FOLDER}/${SPARKLE_FILE})
fi

if [[ `uname` == 'Darwin' ]]; then
    PACKAGE_SIZE=`stat -f%z ${PACKAGE}`
    DATE_RFC2822=`date "+%a, %d %b %Y %T %z"`
else
    PACKAGE_SIZE=`stat -c %s ${PACKAGE}`
    DATE_RFC2822=`date -R`
fi

cat << EOFILE > ${REPO_FOLDER}/${SPARKLE_FILE}
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Ring - nightly</title>
        <link>${REPO_URL}/${SPARKLE_FILE}</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        <item>
            <title>Ring nightly $(date "+%Y/%m/%d %H:%M")</title>
            <pubDate>$DATE_RFC2822</pubDate>
            <enclosure url="${REPO_URL}/$(basename ${PACKAGE})" sparkle:version="$(date +%Y%m%d%H)" sparkle:shortVersionString="nightly-$(date "+%Y%m%d")" length="$PACKAGE_SIZE" type="application/octet-stream" sparkle:dsaSignature="$(./sign_update.sh ${PACKAGE} ${DSA_KEY})" />
            <sparkle:minimumSystemVersion>10.13</sparkle:minimumSystemVersion>
        </item>
$(echo -e "${ITEMS}")
    </channel>
</rss>
EOFILE

