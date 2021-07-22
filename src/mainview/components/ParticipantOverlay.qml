/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Authors: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 *          Albert Babí <albert.babi@savoirfairelinux.com>
 *          Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import QtQuick 2.15
import QtGraphicalEffects 1.15
import QtQuick.Layouts 1.15
import QtQuick.Shapes 1.15

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Item {
    id: root

    // svg path for the participant indicators background shape
    property int shapeWidth: indicatorsRowLayout.width + 8
    property int shapeHeight: 16
    property int shapeRadius: 5
    property string pathShape: "M0,0 h%1 q%2,0 %2,%2 v%3 h-%4 z"
        .arg(shapeWidth - shapeRadius)
        .arg(shapeRadius)
        .arg(shapeHeight - shapeRadius)
        .arg(shapeWidth)

    property bool isModerator: CallAdapter.isModerator()
    property bool isLocal: false
    property string uri: ""
    property bool participantIsModerator: false
    property bool participantIsHost: CallAdapter.participantIsHost(uri)
    property string bestName: ""
    property bool videoMuted: true
    property string sinkId: ""
    property bool participantIsActive: false
    property bool isHost: CallAdapter.isCurrentHost()
    property bool isLocalMuted: false
    property bool isModeratorMuted: false
    property bool participantIsMuted: isLocalMuted || isModeratorMuted

    Rectangle {
        id: peerOverlay

        anchors.centerIn: parent
        z: 1

        color: "transparent"
        border.color: "yellow"
        border.width: 0
        visible: true

        // Participant header with host, moderator and mute indicators
        Rectangle {
            id: participantIndicators
            width: indicatorsRowLayout.width
            height: shapeHeight
            visible: root.participantIsHost || root.participantIsModerator || participantIsMuted
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

                    visible: root.participantIsHost

                    source: JamiResources.star_outline_24dp_svg
                    color: JamiTheme.whiteColor
                }

                ResponsiveImage {
                    id: isModeratorIndicator

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6

                    containerHeight: 12
                    containerWidth: 12

                    visible: root.participantIsModerator

                    source: JamiResources.moderator_svg
                    color: JamiTheme.whiteColor
                }

                ResponsiveImage {
                    id: isMutedIndicator

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6

                    containerHeight: 12
                    containerWidth: 12

                    visible: participantIsMuted

                    source: JamiResources.mic_off_24dp_svg
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

                showSetModerator: root.isHost && !root.isLocal && !root.participantIsModerator
                showUnsetModerator: root.isHost && !root.isLocal && root.participantIsModerator
                showModeratorMute: root.isModerator && !root.isModeratorMuted
                showModeratorUnmute: root.isModerator && root.isModeratorMuted
                showMaximize: root.isModerator && CallParticipantsModel.conferenceLayout !== CallParticipantsModel.ONE
                showMinimize: root.isModerator && root.participantIsActive
                showHangup: root.isModerator && !root.isLocal && !root.participantIsHost
            }

            Behavior on opacity { NumberAnimation { duration: JamiTheme.shortFadeDuration }}
        }
    }

    Loader {
        id: avatar

        anchors.centerIn: parent

        active: root.videoMuted
        mode_: root.isLocal ? Avatar.Mode.Account : Avatar.Mode.Contact
        imageId_: root.isLocal ? LRCInstance.currentAccountId : root.uri

        property real size_: Math.min(parent.width / 2, parent.height / 2)
        height:  size_
        width:  size_
        z: 0

        property int mode_
        property string imageId_

        sourceComponent: Component {
            Avatar {
                // round the avatar source size up to some nearest multiple
                readonly property real step: 96
                property real size: Math.floor((size_ + step - 1) / step) * step
                sourceSize: Qt.size(size, size)
                mode: mode_
                imageId: size_ ? imageId_ : ""
                showPresenceIndicator: false
            }
        }
    }

    DistantRenderer {
        id: mediaDistRender

        anchors.fill: parent
        rendererId: root.sinkId
        visible: !root.videoMuted

        lrcInstance: LRCInstance

        onOffsetChanged: {
            participantMouseArea.height = mediaDistRender.getWidgetHeight() !== 0 ? mediaDistRender.getWidgetHeight() : mediaDistRender.height
            participantMouseArea.width = mediaDistRender.getWidgetWidth() !== 0 ? mediaDistRender.getWidgetWidth() : mediaDistRender.width
            peerOverlay.height = participantMouseArea.height + 3
            peerOverlay.width = participantMouseArea.width + 3
        }

        layer.enabled: !root.videoMuted
        layer.effect: OpacityMask {
            maskSource: Item {
                width: mediaDistRender.width
                height: mediaDistRender.height
                Rectangle {
                    anchors.centerIn: parent
                    width: peerOverlay.width
                    height: peerOverlay.height
                    radius: 10
                }
            }
        }
    }
}
