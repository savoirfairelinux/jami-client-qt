
/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.14
import net.jami.Models 1.0

import "../../commoncomponents"

Rectangle {
    id: root
    border.width: 1
    opacity: 0
    color: "transparent"
    z: 1

    property int buttonPreferredSize: 12
    property var uri: ""
    property var active: true
    property var isLocal: true

    function setParticipantName(name) {
        participantName.text = name
    }

    function setMenuVisible(isVisible) {
        optionsButton.visible = isVisible
    }

    MouseArea {
        id: mouseAreaHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton

        Row {
            id: bottomLabel

            height: 24
            width: parent.width
            anchors.bottom: parent.bottom

            Rectangle {
                color: "black"
                opacity: 0.8
                height: parent.height
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    id: participantName
                    anchors.fill: parent
                    leftPadding: 8.0

                    TextMetrics {
                        id: participantMetrics
                        elide: Text.ElideRight
                        elideWidth: bottomLabel.width - 8
                    }

                    text: participantMetrics.elidedText

                    color: "white"
                    font.pointSize: JamiTheme.textFontSize
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Button {
                    id: optionsButton

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    background: Rectangle {
                        color: "transparent"
                    }


                    icon.color: "white"
                    icon.height: buttonPreferredSize
                    icon.width: buttonPreferredSize
                    icon.source: "qrc:/images/icons/more_vert-24px.svg"

                    onClicked: {
                        var mousePos = mapToItem(videoCallPageRect, parent.x, parent.y)
                        var layout = CallAdapter.getCurrentLayoutType()
                        var showMaximized = layout != 2
                        var showMinimized = !(layout == 0 || (layout == 1 && !active))
                        participantContextMenu.showHangup(!root.isLocal)
                        participantContextMenu.showMaximize(showMaximized)
                        participantContextMenu.showMinimize(showMinimized)
                        participantContextMenu.setHeight((root.isLocal ? 0 : 1) + (showMaximized ? 1 : 0) + (showMinimized ? 1 : 0))
                        participantContextMenu.uri = uri
                        participantContextMenu.active = active
                        participantContextMenu.x = mousePos.x
                        participantContextMenu.y = mousePos.y - participantContextMenu.height
                        participantContextMenu.open()
                    }
                }
            }
        }

        onClicked: {
            CallAdapter.maximizeParticipant(uri, active)
        }

        onEntered: {
            root.state = "entered"
        }

        onExited: {
            root.state = "exited"
        }
    }

    states: [
        State {
            name: "entered"
            PropertyChanges {
                target: root
                opacity: 1
            }
        },
        State {
            name: "exited"
            PropertyChanges {
                target: root
                opacity: 0
            }
        }
    ]

    transitions: Transition {
        PropertyAnimation {
            target: root
            property: "opacity"
            duration: 500
        }
    }
}