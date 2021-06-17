/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import QtQuick.Controls.Universal 2.14
import QtGraphicalEffects 1.14

import net.jami.Adapters 1.0
import net.jami.Models 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Item {
    id: root

    // svg path for the participant indicators background shape
    property int shapeWidth: indicatorsRowLayout.width + 8
    property int shapeHeight: 16
    property int shapeRadius: 6
    property string pathShape: "M0,0 h%1 q%2,0 %2,%2 v%3 h-%4 z"
        .arg(shapeWidth - shapeRadius)
        .arg(shapeRadius)
        .arg(shapeHeight - shapeRadius)
        .arg(shapeWidth)

    property string uri: overlayMenu.uri
    property alias sinkId:  mediaDistRender.rendererId
    property bool participantIsActive: false
    property bool participantIsHost: false
    property bool participantIsModerator: false
    property bool participantIsMuted: false
    property bool participantIsModeratorMuted: false

    Connections {
        target: CallParticipantsModel

        function onUpdateParticipant(participantInfos) {
            if (participantInfos.uri === overlayMenu.uri) {
                root.sinkId = participantInfos.videoMuted ? "" : participantInfos.sinkId
                setMenu(participantInfos.uri, participantInfos.bestName, participantInfos.isLocal, participantInfos.active, true)
                setAvatar(participantInfos.videoMuted, participantInfos.avatar, participantInfos.uri, participantInfos.isLocal, participantInfos.isContact)
            }
        }
    }

    function setAvatar(show, avatar, uri, local, isContact) {
        if (!show) {
            contactImage.visible = false
        } else {
            if (avatar) {
                contactImage.avatarMode = AvatarImage.AvatarMode.FromBase64
                contactImage.updateImage(avatar)
            } else if (local) {
                contactImage.avatarMode = AvatarImage.AvatarMode.FromAccount
                contactImage.updateImage(LRCInstance.currentAccountId)
            } else if (isContact) {
                contactImage.avatarMode = AvatarImage.AvatarMode.FromContactUri
                contactImage.updateImage(uri)
            } else {
                contactImage.avatarMode = AvatarImage.AvatarMode.FromTemporaryName
                contactImage.updateImage(uri)
            }
            contactImage.visible = true
        }
    }

    function setMenu(uri, bestName, isLocal, isActive, showMax) {
        overlayMenu.uri = uri
        overlayMenu.bestName = bestName

        var isHost = CallAdapter.isCurrentHost()
        var isModerator = CallAdapter.isCurrentModerator()
        participantIsHost = CallAdapter.participantIsHost(overlayMenu.uri)
        participantIsModerator = CallAdapter.isModerator(overlayMenu.uri)
        participantIsActive = isActive
        overlayMenu.showSetModerator = isHost && !isLocal && !participantIsModerator
        overlayMenu.showUnsetModerator = isHost && !isLocal && participantIsModerator

        var muteState = CallAdapter.getMuteState(overlayMenu.uri)
        overlayMenu.isLocalMuted = muteState === CallAdapter.LOCAL_MUTED
                || muteState === CallAdapter.BOTH_MUTED
        var isModeratorMuted = muteState === CallAdapter.MODERATOR_MUTED
                || muteState === CallAdapter.BOTH_MUTED

        participantIsMuted = overlayMenu.isLocalMuted || isModeratorMuted

        overlayMenu.showModeratorMute = isModerator && !isModeratorMuted
        overlayMenu.showModeratorUnmute = isModerator && isModeratorMuted
        overlayMenu.showMaximize = isModerator
        overlayMenu.showMinimize = isModerator && participantIsActive
        overlayMenu.showHangup = isModerator && !isLocal && !participantIsHost
    }

    Rectangle {
        id: peerOverlay

        anchors.centerIn: parent
        z: 1

        color: "transparent"
        border.color: "yellow"
        border.width: root.participantIsActive ? 3 : 0
        visible: true

        // Participant header with host, moderator and mute indicators
        Rectangle {
            id: participantIndicators
            width: indicatorsRowLayout.width
            height: shapeHeight
            visible: participantIsHost || participantIsModerator || participantIsMuted
            color: "transparent"
            anchors.bottom: parent.bottom

            Shape {
                id: backgroundShape
                ShapePath {
                    id: backgroundShapePath
                    strokeColor: "transparent"
                    fillColor: JamiTheme.darkGreyColorOpacity
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: pathShape }
                }
            }

            RowLayout {
                id: indicatorsRowLayout
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter

                ResponsiveImage {
                    id: isHostIndicator

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6

                    containerHeight: 12
                    containerWidth: 12

                    visible: participantIsHost

                    source: "qrc:/images/icons/star_outline-24px.svg"
                    color: JamiTheme.whiteColor
                }

                ResponsiveImage {
                    id: isModeratorIndicator

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6

                    containerHeight: 12
                    containerWidth: 12

                    visible: participantIsModerator

                    source: "qrc:/images/icons/moderator.svg"
                    color: JamiTheme.whiteColor
                }

                ResponsiveImage {
                    id: isMutedIndicator

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6

                    containerHeight: 12
                    containerWidth: 12

                    visible: participantIsMuted

                    source: "qrc:/images/icons/mic_off-24px.svg"
                    color: JamiTheme.whiteColor
                }
            }
        }

        // Participant background and buttons for moderation
        MouseArea {
            id: participantMouseArea

            anchors.centerIn: parent
            opacity: 0

            propagateComposedEvents: true
            hoverEnabled: true
            onPositionChanged: {
                participantMouseArea.opacity = 1
                fadeOutTimer.restart()
                // Here we could call: root.parent.positionChanged(mouse)
                // to relay the event to a main overlay mouse area, either
                // as a parent object or some property passed in. But, this
                // will still fail when hovering over menus, etc.
            }
            onExited: {
                root.z = 1
                participantMouseArea.opacity = 0
            }
            onEntered: {
                root.z = 2
                participantMouseArea.opacity = 1
            }

            // Timer to decide when ParticipantOverlay fade out
            Timer {
                id: fadeOutTimer
                interval: JamiTheme.overlayFadeDelay
                onTriggered: {
                    if (overlayMenu.hovered)
                        return
                    participantMouseArea.opacity = 0
                }
            }

            ParticipantOverlayMenu {
                id: overlayMenu
                anchors.fill: parent
            }

            Behavior on opacity { NumberAnimation { duration: JamiTheme.shortFadeDuration }}
        }
    }

    AvatarImage {
        id: contactImage
        
        anchors.centerIn: parent
        height:  Math.min(root.width / 2, root.height / 2)
        width:  Math.min(root.width / 2, root.height / 2)
        z: 0

        fillMode: Image.PreserveAspectFit
        imageId: ""
        avatarMode: AvatarImage.AvatarMode.Default
        showPresenceIndicator: false

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
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
        onVisibleChanged: {
            if (visible) {
                participantMouseArea.height = contactImage.height * 2
                participantMouseArea.width = contactImage.height * 2
                peerOverlay.height = participantMouseArea.height + 3
                peerOverlay.width = participantMouseArea.width + 3
            }
        }
    }

    DistantRenderer {
        id: mediaDistRender

        anchors.fill: parent
        anchors.centerIn: parent
        z: -1

        lrcInstance: LRCInstance

        onOffsetChanged: {
            participantMouseArea.height = mediaDistRender.getWidgetHeight() !== 0 ? mediaDistRender.getWidgetHeight() : mediaDistRender.height
            participantMouseArea.width = mediaDistRender.getWidgetWidth() !== 0 ? mediaDistRender.getWidgetWidth() : mediaDistRender.width
            peerOverlay.height = participantMouseArea.height + 3
            peerOverlay.width = participantMouseArea.width + 3
        }
    }
}
