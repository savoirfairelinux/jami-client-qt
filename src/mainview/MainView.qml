/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import QtQml 2.12

import QtQuick.Controls 1.4 as QtQuickOne

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

// Import qml component files.
import "components"
import "../"
import "../wizardview"
import "../settingsview"
import "../settingsview/components"
import "../commoncomponents"

Item {
    id: mainView

    property variant clickPos: "1,1"

    /*VideoRenderingItemBase {
        id: previewWidget

        anchors.centerIn: mainView

        width: 500
        height: 500

        VideoRenderingItemBase {
            id: previewWidgetTwo

            x: 0
            y: 0

            width: 300
            height: 300

            MaterialButton {
                id: downloadButton

                anchors.bottom: previewWidgetTwo.bottom
                anchors.horizontalCenter: previewWidgetTwo.horizontalCenter

                width: 150
                height: JamiTheme.preferredFieldHeight

                toolTipText: JamiStrings.tipChooseDownloadFolder
                text: "sssssssssssss"
                source: "qrc:/images/icons/round-folder-24px.svg"
                color: JamiTheme.buttonTintedGrey
                hoveredColor: JamiTheme.buttonTintedGreyHovered
                pressedColor: JamiTheme.buttonTintedGreyPressed
            }

            MouseArea {
                id: dragMouseArea

                anchors.fill: previewWidgetTwo

                onPressed: {
                    clickPos = Qt.point(mouse.x, mouse.y)
                }

                onPositionChanged: {
                    // Calculate mouse position relative change.
                    var delta = Qt.point(mouse.x - clickPos.x,
                                        mouse.y - clickPos.y)
                    var deltaW = previewWidgetTwo.x + delta.x + previewWidgetTwo.width
                    var deltaH = previewWidgetTwo.y + delta.y + previewWidgetTwo.height

                    previewWidgetTwo.x += delta.x
                    previewWidgetTwo.y += delta.y
                }
            }
        }
    }*/

    VideoRenderingItemBase {
        id: previewWidgetTwo

        x: (mainView.width - previewWidgetTwo.width) / 2
        y: (mainView.height - previewWidgetTwo.height) / 2

        width: 300
        height: 300

        MaterialButton {
            id: downloadButton

            anchors.top: previewWidgetTwo.top
            anchors.left: previewWidgetTwo.left
            anchors.horizontalCenter: previewWidgetTwo.horizontalCenter

            width: 150
            height: JamiTheme.preferredFieldHeight

            toolTipText: JamiStrings.tipChooseDownloadFolder
            text: "sssssssssssss"
            source: "qrc:/images/icons/round-folder-24px.svg"
            color: JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedGreyHovered
            pressedColor: JamiTheme.buttonTintedGreyPressed
        }

        MouseArea {
            id: dragMouseArea

            anchors.fill: previewWidgetTwo

            onPressed: {
                clickPos = Qt.point(mouse.x, mouse.y)
            }

            onPositionChanged: {
                // Calculate mouse position relative change.
                var delta = Qt.point(mouse.x - clickPos.x,
                                    mouse.y - clickPos.y)
                var deltaW = previewWidgetTwo.x + delta.x + previewWidgetTwo.width
                var deltaH = previewWidgetTwo.y + delta.y + previewWidgetTwo.height

                previewWidgetTwo.x += delta.x
                previewWidgetTwo.y += delta.y

                //console.log("ssss    " + previewWidgetTwo.y)
            }
        }
    }

    Rectangle {
        id: labelFrame
        anchors.margins: -10
        radius: 10
        color: "white"
        border.color: "black"
        opacity: 0.8
        anchors.fill: description
    }

    Text {
        id: description
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        wrapMode: Text.WordWrap
        text: "This example creates two animated items and sets 'layer.enabled: true' on both of them. " +
              "This turns the items into texture providers and we can access their texture from C++ in a custom material. " +
              "The XorBlender is a custom C++ item which uses performs an Xor blend between them."
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: AccountAdapter.startPreviewing(false)
    }
}
