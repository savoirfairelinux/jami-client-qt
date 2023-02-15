import QtQuick
import QtQuick.Layouts
import net.jami.Constants 1.1


import "../../commoncomponents"

ResponsiveImage {
    id: root

    property bool isSharing: false
    property bool arrowTimerVisibility

    source: JamiResources.localisation_sharing_send_pin_svg

    ResponsiveImage {
        id: arrowSharePosition

        visible: arrowTimerVisibility
        source: JamiResources.localisation_sharing_send_arrow_svg
        color: root.color
        mirrorHorizontally: isSharing ? false : true
        mirrorVertically: isSharing ? false : true
        anchors.fill: parent
        anchors.bottomMargin: isSharing ? 0 : 4
        anchors.leftMargin: isSharing ? 0 : 3
    }
}

