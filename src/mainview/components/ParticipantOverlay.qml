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
import QtQuick.Controls.Universal 2.14
import QtGraphicalEffects 1.14
import net.jami.Models 1.0

import "../../commoncomponents"

Rectangle {
    id: root

    property var uri: ""
    property var active: true
    property int minimumOverlayMenuWidth: 200

    function setParticipantName(name) {
        overlayMenu.participantName = name
    }

    // TODO: try to use AvatarImage as well
    function setAvatar(avatar) {
        if (avatar === "") {
            opacity = 0
            contactImage.source = ""
        } else {
            opacity = 1
            contactImage.source = "data:image/png;base64," + avatar
        }
    }

    function setMenu(isModerator, isHost, setUri, bestName, setActive, isLocal) {
        overlayMenu.isModerator = isModerator //CallAdapter.isModerator(uri) // Albert: review!!!
        uri = setUri
        overlayMenu.bestName = bestName
        active = setActive
        var layout = CallAdapter.getCurrentLayoutType()
        var showMaximized = layout !== 2
        var showMinimized = !(layout === 0 || (layout === 1 && !active))
        var participantIsHost = CallAdapter.participantIsHost(uri)
        overlayMenu.showHangup = !isLocal && isHost
        overlayMenu.showMaximize = showMaximized
        overlayMenu.showMinimize = showMinimized
        overlayMenu.active = active
        overlayMenu.showSetModerator = (isHost && !participantIsHost && !isModerator)
        overlayMenu.showUnsetModerator = (isHost && !participantIsHost && isModerator)
        overlayMenu.isMuted = CallAdapter.isMuted(uri)
    }

    border.width: 1
    opacity: 0
    color: "transparent"
    z: 1

    MouseArea {
        id: mouseAreaHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton

        Image {
            id: contactImage

            anchors.centerIn: parent

            height:  Math.min(parent.width / 2, parent.height / 2)
            width:  Math.min(parent.width / 2, parent.height / 2)

            fillMode: Image.PreserveAspectFit
            source: ""
            asynchronous: true

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle{
                    width: contactImage.width
                    height: contactImage.height
                    radius: {
                        var size = ((contactImage.width <= contactImage.height)?
                                        contactImage.width : contactImage.height)
                        return size / 2
                    }
                }
            }
            layer.mipmap: false
            layer.smooth: true
        }

        Rectangle {
            color: "black"
            opacity: 0.6
            height: parent.height
            width: parent.width

            ParticipantOverlayMenu {
                id: overlayMenu
                visible: true
                anchors.centerIn: parent

                hasMinimumWidth: root.width > minimumOverlayMenuWidth
            }
        }

        onClicked: {
            CallAdapter.maximizeParticipant(uri, active)
        }

        onEntered: {
            if (contactImage.status === Image.Null)
                root.state = "entered"
        }

        onExited: {
            if (contactImage.status === Image.Null)
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
