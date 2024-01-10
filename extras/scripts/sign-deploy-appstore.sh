#!/bin/bash

echo ""
cd build-local
echo "cloning certificates"
git clone $CERTIFICATES_REPOSITORY
echo "prepare keychain"
security create-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_NAME  > /dev/null 2>&1
security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_NAME  > /dev/null 2>&1
security list-keychains -s $KEYCHAIN_NAME  > /dev/null 2>&1
security set-key-partition-list -S apple-tool:,apple:,productbuild: -s -k $KEYCHAIN_PASSWORD $KEYCHAIN_NAME  > /dev/null 2>&1
echo "import certificates"
security import certificates/certificates/distribution/Certificates.p12 -k $KEYCHAIN_PATH -P $CERTIFICATES_PASSWORD -T /usr/bin/codesign -T /usr/bin/productbuild
DELIVER_PASSWORD=$APPLE_PASSWORD fastlane sigh --app_identifier $BUNDLE_ID --username $APPLE_ACCOUNT --readonly true --platform macos --team_id $TEAM_ID
security set-key-partition-list -S apple-tool:,apple:,productbuild: -s -k $KEYCHAIN_PASSWORD $KEYCHAIN_NAME > /dev/null 2>&1
echo "start signing"
$MACDEPLOYQT_PATH ./Jami.app -no-strip -appstore-compliant -codesign="${APP_CERTIFICATE}"
echo "remove web engine"
rm -rf Jami.app/Contents/Frameworks/QtWebEngineQuickDelegatesQml.framework
rm -rf Jami.app/Contents/Frameworks/QtWebEngineQuick.framework
rm -rf Jami.app/Contents/Frameworks/QtWebEngineCore.framework
rm -rf Jami.app/Contents/Frameworks/QtWebChannel.framework
echo "remove web dSYM files"
find Jami.app/Contents/Resources/qml -type d -name "*.dSYM" -exec rm -r {} \;
codesign --force --sign "${APP_CERTIFICATE}" --entitlements ../resources/entitlements/appstore/Jami.entitlements Jami.app
codesign --verify Jami.app
echo "create .pkg"
productbuild --component Jami.app/ /Applications --sign "${INSTALLER_CERTIFICATE}" --product Jami.app/Contents/Info.plist Jami.pkg
/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Versions/A/Frameworks/AppStoreService.framework/Versions/A/Support/altool  --validate-app  --type osx -f Jami.pkg -u $APPLE_ACCOUNT --password $ALTOOL_PASSWORD
echo "start deploying"
/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Versions/A/Frameworks/AppStoreService.framework/Versions/A/Support/altool  --upload-app  --type osx -f Jami.pkg -u $APPLE_ACCOUNT --password $ALTOOL_PASSWORD
