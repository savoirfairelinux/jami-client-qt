/*
 * Copyright (C) 2020-2022 Savoir-faire Linux
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

import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Shapes

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Item {
    id: root

    // svg path for the participant indicators background shape
    property int shapeWidth: participantFootInfo.width + 8
    property int shapeHeight: 30
    property int shapeRadius: 5
    property string pathShape: "M0,0 h%1 q%2,0 %2,%2 v%3 h-%4 z"
        .arg(shapeWidth - shapeRadius)
        .arg(shapeRadius)
        .arg(shapeHeight - shapeRadius)
        .arg(shapeWidth)

    property string uri: ""
    property string bestName: ""
    property string sinkId: ""
    property bool participantIsActive: false
    property bool participantIsHost: CallAdapter.participantIsHost(uri)
    property bool participantIsModerator: false
    property bool participantIsMuted: isLocalMuted || participantIsModeratorMuted
    property bool participantIsModeratorMuted: false
    property bool participantHandIsRaised: false
    property bool videoMuted: true
    property bool isLocalMuted: true

    property bool meHost: CallAdapter.isCurrentHost()
    property bool meModerator: CallAdapter.isModerator()
    property bool isMe: false

    property string muteAlertMessage: ""
    property bool muteAlertActive: false

    onMuteAlertActiveChanged: {
        if (muteAlertActive) {
            alertTimer.restart()
        }
    }

    TextMetrics {
        id: nameTextMetrics
        text: bestName
        font.pointSize: JamiTheme.participantFontSize
    }

    Loader {
        id: avatar

        anchors.centerIn: parent

        active: root.videoMuted
        mode_: root.isMe ? Avatar.Mode.Account : Avatar.Mode.Contact
        imageId_: root.isMe ? LRCInstance.currentAccountId : root.uri

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

    // Timer to decide when ParticipantOverlay fade out
    Timer {
        id: fadeOutTimer
        interval: JamiTheme.overlayFadeDelay
        onTriggered: {
            if (overlayMenu.hovered) {
                fadeOutTimer.restart()
                return
            }
            participantRect.opacity = 0
        }
    }

    VideoView {
        id: mediaDistRender
        width: parent.width
        height: width * invAspectRatio
        anchors.centerIn: parent
        rendererId: root.sinkId
        visible: !root.videoMuted

        // Update overlays if the internal or visual geometry changes.
        property real area: width * height

        Item {
            anchors.fill: parent

            HoverHandler {
                onPointChanged: {
                    participantRect.opacity = 1
                    fadeOutTimer.restart()
                }

                onHoveredChanged: {
                    if (overlayMenu.hovered) {
                        participantRect.opacity = 1
                        fadeOutTimer.restart()
                        return
                    }
                    participantRect.opacity = hovered ? 1 : 0
                }
            }
        }

        layer.enabled: !root.videoMuted
        layer.effect: OpacityMask {
            maskSource: Item {
                width: mediaDistRender.width
                height: mediaDistRender.height
                Rectangle {
                    anchors.centerIn: parent
                    width: participantRect.width
                    height: participantRect.height
                    radius: 10
                }
            }
        }
    }

    // Participant background
    Rectangle {
        id: participantRect

        width: mediaDistRender.width
        height: mediaDistRender.height
        anchors.centerIn: parent
        color: "transparent"
        opacity: 0

        // Participant background and buttons for moderation
        ParticipantOverlayMenu {
            id: overlayMenu
            visible: isMe || meModerator
            anchors.fill: parent

            onHoveredChanged: {
                if (hovered) {
                    participantRect.opacity = 1
                    fadeOutTimer.restart()
                } else {
                    participantRect.opacity = 0
                }
            }

            showSetModerator: root.meHost && !root.isMe && !root.participantIsModerator
            showUnsetModerator: root.meHost && !root.isMe && root.participantIsModerator
            showModeratorMute: root.meModerator && !root.participantIsModeratorMuted
            showModeratorUnmute: (root.meModerator || root.isMe) && root.participantIsModeratorMuted
            showMaximize: root.meModerator && CallParticipantsModel.conferenceLayout !== CallParticipantsModel.ONE
            showMinimize: root.meModerator && root.participantIsActive
            showHangup: root.meModerator && !root.isMe && !root.participantIsHost
        }

        // Participant footer with host, moderator and mute indicators
        // Mute indicator is as follow:
        // - In another participant, if i am not moderator, the mute state is isLocalMuted || participantIsModeratorMuted
        // - In another participant, if i am moderator, the mute state is isLocalMuted
        // - In my video, the mute state is isLocalMuted
        Rectangle {
            id: participantIndicators
            width: participantRect.width
            height: shapeHeight
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
                id: participantFootInfo
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: bestNameLabel

                    Layout.leftMargin: 8
                    Layout.preferredWidth: Math.min(nameTextMetrics.boundingRect.width + 8,
                                                    participantIndicators.width - indicatorsRowLayout.width - 16)
                    Layout.preferredHeight: shapeHeight

                    text: bestName
                    elide: Text.ElideRight
                    color: JamiTheme.whiteColor
                    font.pointSize: JamiTheme.participantFontSize
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    HoverHandler { id: hoverName }
                    MaterialToolTip {
                        visible: hoverName.hovered && (text.length > 0)
                        text: bestNameLabel.truncated ? bestName : ""
                    }
                }

                RowLayout {
                    id: indicatorsRowLayout
                    height: parent.height
                    Layout.alignment: Qt.AlignVCenter

                    ResponsiveImage {
                        id: isHostIndicator

                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 6

                        containerHeight: 12
                        containerWidth: 12

                        visible: root.participantIsHost

                        source: JamiResources.star_outline_24dp_svg
                        color: JamiTheme.whiteColor

                        HoverHandler { id: hoverHost }
                        MaterialToolTip {
                            visible: hoverHost.hovered
                            text: JamiStrings.host
                        }
                    }

                    ResponsiveImage {
                        id: isModeratorIndicator

                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 6

                        containerHeight: 12
                        containerWidth: 12

                        visible: !root.participantIsHost && root.participantIsModerator

                        source: JamiResources.moderator_svg
                        color: JamiTheme.whiteColor

                        HoverHandler { id: hoverModerator }
                        MaterialToolTip {
                            visible: hoverModerator.hovered
                            text: JamiStrings.moderator
                        }
                    }

                    ResponsiveImage {
                        id: isMutedIndicator

                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 6

                        containerHeight: 12
                        containerWidth: 12

                        visible: (!root.isMe && !root.meModerator) ? root.participantIsMuted : root.isLocalMuted

                        source: JamiResources.micro_off_black_24dp_svg
                        color: "red"

                        HoverHandler { id: hoverMicrophone }
                        MaterialToolTip {
                            visible: hoverMicrophone.hovered
                            text: {
                                if (!root.isMe && !root.meModerator && root.participantIsModeratorMuted && root.isLocalMuted)
                                    return JamiStrings.bothMuted
                                if (root.isLocalMuted)
                                    return JamiStrings.localMuted
                                if (!root.isMe && !root.meModerator && root.participantIsModeratorMuted)
                                    return JamiStrings.moderatorMuted
                                return JamiStrings.notMuted
                            }
                        }
                    }
                }
            }
        }

        Behavior on opacity { NumberAnimation { duration: JamiTheme.shortFadeDuration }}
    }

    PushButton {
        id: isRaiseHandIndicator
        source: JamiResources.hand_black_24dp_svg
        imageColor: JamiTheme.whiteColor
        preferredSize: shapeHeight
        visible: root.participantHandIsRaised
        anchors.right: participantRect.right
        anchors.top: participantRect.top
        checkable: root.meModerator
        pressedColor: JamiTheme.raiseHandColor
        hoveredColor: JamiTheme.raiseHandColor
        normalColor: JamiTheme.raiseHandColor
        z: participantRect.z + 1
        toolTipText: root.meModerator ? JamiStrings.lowerHand : ""
        onClicked: CallAdapter.setHandRaised(uri, false)
        radius: 5
    }

    Rectangle {
        id: alertMessage

        anchors.centerIn: parent
        width: alertMessageTxt.width + 16
        height: alertMessageTxt.contentHeight + 16
        radius: 5
        visible: root.muteAlertActive
        color: JamiTheme.darkGreyColorOpacity

        Text {
            id: alertMessageTxt
            text: root.muteAlertMessage
            anchors.centerIn: parent
            width: Math.min(participantRect.width, contentWidth)
            color: JamiTheme.whiteColor
            font.pointSize: JamiTheme.textFontSize
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Timer {
            id: alertTimer
            interval: JamiTheme.overlayFadeDelay
            onTriggered: {
                root.muteAlertActive = false
            }
        }
    }
}
