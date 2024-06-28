/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */



// KESS this was taken from mainview/components/RecordBox.qml but is aiming to replace settingsview/components/LinkScannerBest.qml as candidate for the dialog
// this dialog should improve on the old design by being more square in design and should have less visual clutter
// - the size should be bigger
// - the guide should be less invasive
// - the flip video should be a visible button overlayed on the panel
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    width: 600
    height: 600
    // radius: 5

    property string imageId
    property bool newItem
    property real buttonSize: 48
    property real imageSize: 25


    // KESS this function can be used to automatically show the camera with a fade in animation on the preview dialog
    // there should also be two buttons overlayed...
    // 1. list to change the camera
    // 2. button to open manual entry of qr image below the scanner and pause the preview
    property bool deviceHasCamerasAvail: VideoDevices.listSize !== 0

    function startPreviewing(force = false) {
        if (!deviceHasCamerasAvail) {
            // startAlternativeEntry();
            return
        }
        previewWidget.show()
        previewWidget.startWithId(VideoDevices.getDefaultDevice(), force)
    }

    Rectangle {
        id: previewWidget

        width: 550
        height: 550

    //     readonly property real minSize: 100
    //     readonly property real maxSize: 1080
    //     readonly property real preferredSize: root.width
    //     readonly property real aspectRatio: 1
    // readonly property real adjustedWidth: Math.min(maxSize, Math.max(minSize, innerContent.width - senderMargin))
    // anchors.right: isOutgoing ? parent.right : undefined
    // width: isFullScreen ? parent.width : adjustedWidth
    // height: isVideo ? isFullScreen ? parent.height : Math.ceil(adjustedWidth / aspectRatio) : 54

        color: JamiTheme.secondaryBackgroundColor
        LocalVideo {
            id: localVideo
            anchors.fill: parent
            visible: true

            layer.enabled: true
        }

        // LocalVideo {
        //     id: localVideo
        //     anchors.fill: parent
        //     visible: parent.visible
        //     layer.enabled: true

        //     // TODO layer qr scanner
        //     // layer.effect: OpacityMask {
        //     //     maskSource: rectBox
        //     // }
        // }
    }
}
