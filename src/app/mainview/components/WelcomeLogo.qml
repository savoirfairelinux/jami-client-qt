import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Item {
    id: welcomeLogo

    property bool hasCustomLogo: viewNode.hasCustomLogo
    property string logoUrl: viewNode.customLogoUrl
    //logoSize has to be between 0 and 1
    property real logoSize: 1

    height: getHeight()
    width: getWidth()

    function getWidth() {
        return JamiTheme.welcomeHalfGridWidth;
    }

    function getHeight() {
        return 120;
    }

    CachedImage {
        id: cachedImgLogo
        objectName: "cachedImgLogo"
        downloadUrl: logoUrl
        defaultImage: JamiResources.jami_logo_icon_svg
        visible: welcomeLogo.visible
        height: parent.height * logoSize
        width: parent.width * logoSize
        anchors.centerIn: parent
        opacity: visible ? 1 : 0
        customLogo: hasCustomLogo
        localPath: UtilsAdapter.getCachePath() + "/" + CurrentAccount.id + "/welcomeview/" + UtilsAdapter.base64Encode(downloadUrl) + fileExtension

        imageFillMode: Image.PreserveAspectFit

        Behavior on opacity  {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}
