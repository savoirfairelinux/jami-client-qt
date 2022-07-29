#!/bin/bash

echo ""
cd build-local
xcrun notarytool submit Jami.app.zip --apple-id ${APPLE_ACCOUNT} --password ${APPLE_PASSWORD} --output-format plist --team-id ${TEAM_ID} --wait > UploadInfo.plist

STATUS=$(xmllint --xpath "/plist/dict/key[.='status']/following-sibling::string[1]/node()" UploadInfo.plist)
if [ "$STATUS" == "Accepted" ];
then
echo  "notarization success"
break
else
echo "notarization failed"
break
exit 1
fi
