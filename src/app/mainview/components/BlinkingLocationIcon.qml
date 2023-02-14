import QtQuick
import QtQuick.Layouts
import net.jami.Constants 1.1


import "../../commoncomponents"

ResponsiveImage {
    property bool isSharing: false

    visible: isSharing
             ? showSharePositionIndicator
             : showSharedPositionIndicator
    source: JamiResources.localisation_sharing_send_pin_svg
    color: isSharing
         ? JamiTheme.sharePositionIndicatorColor
         : JamiTheme.sharedPositionIndicatorColor

    ResponsiveImage {
        id: arrowSharePosition

        visible: locationIconTimer.showIconArrow
        source: JamiResources.localisation_sharing_send_arrow_svg
        color: isSharing
               ? JamiTheme.sharePositionIndicatorColor
               : JamiTheme.sharedPositionIndicatorColor
        mirrorHorizontally: isSharing ? false : true
        mirrorVertically: isSharing ? false : true
        anchors.fill: parent
        anchors.bottomMargin: isSharing ? 0 : 4
        anchors.leftMargin: isSharing ? 0 : 3
    }
}

