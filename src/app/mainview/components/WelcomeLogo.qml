import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Item{

    property bool hasCustomLogo: viewNode.hasCustomLogo
    property string logoUrl: viewNode.customLogoUrl

    property bool alwaysVisible: false;
    id: welcomeLogo
    visible: (root.width > root.thresholdSize) || alwaysVisible

    height: 150
    width: 250

    Behavior on width  {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    Behavior on height  {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    CachedImage{
        id: cachedImgLogo
        objectName: "cachedImgLogo"
        downloadUrl: logoUrl
        defaultImage: JamiResources.logo_jami_standard_coul_svg
        visible: welcomeLogo.visible
        anchors.fill: parent
        opacity: visible ? 1 : 0
        customLogo: hasCustomLogo
        localPath: UtilsAdapter.getCachePath()+"/"+CurrentAccount.id+"/welcomeview/"+UtilsAdapter.base64Encode(downloadUrl)+fileExtension

        imageFillMode: Image.PreserveAspectFit

        Behavior on opacity  {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

    }

    Component.onCompleted: {
        print(this,"cachedImgLogo", cachedImgLogo.height, cachedImgLogo.width )
    }
}
