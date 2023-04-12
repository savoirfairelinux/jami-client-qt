/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    property string bestName: ""
    property bool canMaximize: root.meModerator && (!root.participantIsActive || CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE_WITH_SMALL)
    property string deviceId: ""
    property bool isLocalMuted: true
    property bool isMe: false
    property bool isRecording: false
    property bool isScreenshotButtonHovered: false
    property bool isSharing: false
    property bool meHost: CallAdapter.isCurrentHost()
    property bool meModerator: CallAdapter.isModerator()
    property bool muteAlertActive: false
    property string muteAlertMessage: ""
    property bool participantHandIsRaised: false
    property bool participantHovered: hoverIndicator.hovered
    property bool participantIsActive: false
    property bool participantIsHost: CallAdapter.participantIsHost(uri)
    property bool participantIsModerator: false
    property bool participantIsModeratorMuted: false
    property bool participantIsMuted: isLocalMuted || participantIsModeratorMuted
    property string pathShape: "M0,0 h%1 q%2,0 %2,%2 v%3 h-%4 z".arg(shapeWidth - shapeRadius).arg(shapeRadius).arg(shapeHeight - shapeRadius).arg(shapeWidth)
    property int shapeHeight: 30
    property int shapeRadius: 5

    // svg path for the participant indicators background shape
    property int shapeWidth: participantFootInfo.width + 8
    property string sinkId: ""
    property string uri: ""
    property bool videoMuted: true
    property bool voiceActive: false

    function takeScreenshot() {
        if (!hoveredOverVideoMuted) {
            if (CallAdapter.takeScreenshot(videoProvider.captureRawVideoFrame(hoveredOverlaySinkId), UtilsAdapter.getDirScreenshot())) {
                toastManager.instantiateToast();
            }
        }
    }

    onMuteAlertActiveChanged: {
        if (muteAlertActive) {
            alertTimer.restart();
        }
    }

    TextMetrics {
        id: nameTextMetrics
        font.pointSize: JamiTheme.participantFontSize
        text: bestName
    }

    // Timer to decide when ParticipantOverlay fade out
    Timer {
        id: fadeOutTimer
        interval: JamiTheme.overlayFadeDelay

        onTriggered: {
            if (overlayMenu.hovered) {
                fadeOutTimer.restart();
                return;
            }
            participantRect.opacity = 0;
        }
    }
    Rectangle {
        anchors.centerIn: participantIsActive ? parent : undefined
        anchors.fill: participantIsActive ? undefined : parent
        border.color: voiceActive ? JamiTheme.buttonTintedBlue : "yellow"
        border.width: 2
        color: "transparent"
        height: participantIsActive ? mediaDistRender.contentRect.height + 2 : undefined
        radius: 10
        visible: voiceActive || isScreenshotButtonHovered
        width: participantIsActive ? mediaDistRender.contentRect.width + 2 : undefined
        z: -1
    }
    VideoView {
        id: mediaDistRender
        anchors.fill: parent
        anchors.margins: 2
        crop: !participantIsActive
        flip: isMe && !isSharing && CurrentCall.flipSelf
        layer.enabled: !root.videoMuted
        rendererId: root.sinkId

        layer.effect: OpacityMask {
            maskSource: Item {
                height: mediaDistRender.height
                width: mediaDistRender.width

                Rectangle {
                    anchors.centerIn: parent
                    height: participantRect.height
                    radius: 10
                    width: participantRect.width
                }
            }
        }
        overlayItems: Item {
            id: overlayRect
            anchors.centerIn: participantIsActive ? parent : undefined
            anchors.fill: participantIsActive ? undefined : parent
            height: participantIsActive ? mediaDistRender.contentRect.height - 2 : undefined
            width: participantIsActive ? mediaDistRender.contentRect.width - 2 : undefined

            TapHandler {
                acceptedButtons: Qt.MiddleButton
                acceptedModifiers: Qt.ControlModifier

                onTapped: {
                    takeScreenshot();
                }
            }
            HoverHandler {
                id: hoverIndicator
                onHoveredChanged: {
                    if (overlayMenu.hovered) {
                        participantRect.opacity = 1;
                        fadeOutTimer.restart();
                        return;
                    }
                    participantRect.opacity = hovered ? 1 : 0;
                }
                onPointChanged: {
                    participantRect.opacity = 1;
                    fadeOutTimer.restart();
                }
            }
            Item {
                id: participantRect
                anchors.fill: parent
                opacity: 0

                // Participant buttons for moderation
                ParticipantOverlayMenu {
                    id: overlayMenu
                    anchors.fill: parent
                    showHangup: root.meModerator && !root.isMe && !root.participantIsHost
                    showMaximize: root.canMaximize
                    showMinimize: root.meModerator && root.participantIsActive
                    showModeratorMute: root.meModerator && !root.participantIsModeratorMuted
                    showModeratorUnmute: (root.meModerator || root.isMe) && root.participantIsModeratorMuted
                    showSetModerator: root.meHost && !root.isMe && !root.participantIsModerator
                    showUnsetModerator: root.meHost && !root.isMe && root.participantIsModerator
                    visible: isMe || meModerator

                    onHoveredChanged: {
                        if (hovered) {
                            participantRect.opacity = 1;
                            fadeOutTimer.restart();
                        } else {
                            participantRect.opacity = 0;
                        }
                    }
                }

                // Participant footer with host, moderator and mute indicators
                // Mute indicator is as follow:
                // - In another participant, if i am not moderator, the mute state is isLocalMuted || participantIsModeratorMuted
                // - In another participant, if i am moderator, the mute state is isLocalMuted
                // - In my video, the mute state is isLocalMuted
                Item {
                    id: participantIndicators
                    anchors.bottom: parent.bottom
                    height: shapeHeight
                    width: participantRect.width

                    Shape {
                        id: backgroundShape
                        ShapePath {
                            id: backgroundShapePath
                            capStyle: ShapePath.RoundCap
                            fillColor: JamiTheme.darkGreyColorOpacity
                            strokeColor: "transparent"

                            PathSvg {
                                path: pathShape
                            }
                        }
                    }
                    RowLayout {
                        id: participantFootInfo
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height

                        Text {
                            id: bestNameLabel
                            Layout.leftMargin: 8
                            Layout.preferredHeight: shapeHeight
                            Layout.preferredWidth: Math.min(nameTextMetrics.boundingRect.width + 8, participantIndicators.width - indicatorsRowLayout.width - 16)
                            color: JamiTheme.whiteColor
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.participantFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: bestName
                            verticalAlignment: Text.AlignVCenter

                            HoverHandler {
                                id: hoverName
                            }
                            MaterialToolTip {
                                text: bestNameLabel.truncated ? bestName : ""
                                visible: hoverName.hovered && (text.length > 0)
                            }
                        }
                        RowLayout {
                            id: indicatorsRowLayout
                            Layout.alignment: Qt.AlignVCenter
                            height: parent.height

                            ResponsiveImage {
                                id: isHostIndicator
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 6
                                color: JamiTheme.whiteColor
                                containerHeight: 12
                                containerWidth: 12
                                source: JamiResources.star_outline_24dp_svg
                                visible: root.participantIsHost

                                HoverHandler {
                                    id: hoverHost
                                }
                                MaterialToolTip {
                                    text: JamiStrings.host
                                    visible: hoverHost.hovered
                                }
                            }
                            ResponsiveImage {
                                id: isModeratorIndicator
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 6
                                color: JamiTheme.whiteColor
                                containerHeight: 12
                                containerWidth: 12
                                source: JamiResources.moderator_svg
                                visible: !root.participantIsHost && root.participantIsModerator

                                HoverHandler {
                                    id: hoverModerator
                                }
                                MaterialToolTip {
                                    text: JamiStrings.moderator
                                    visible: hoverModerator.hovered
                                }
                            }
                            ResponsiveImage {
                                id: isMutedIndicator
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 6
                                color: JamiTheme.redColor
                                containerHeight: 12
                                containerWidth: 12
                                source: JamiResources.micro_off_black_24dp_svg
                                visible: (!root.isMe && !root.meModerator) ? root.participantIsMuted : root.isLocalMuted

                                HoverHandler {
                                    id: hoverMicrophone
                                }
                                MaterialToolTip {
                                    text: {
                                        if (!root.isMe && !root.meModerator && root.participantIsModeratorMuted && root.isLocalMuted)
                                            return JamiStrings.bothMuted;
                                        if (root.isLocalMuted)
                                            return JamiStrings.localMuted;
                                        if (!root.isMe && !root.meModerator && root.participantIsModeratorMuted)
                                            return JamiStrings.moderatorMuted;
                                        return JamiStrings.notMuted;
                                    }
                                    visible: hoverMicrophone.hovered
                                }
                            }
                        }
                    }
                }

                Behavior on opacity  {
                    NumberAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }
            }
            PushButton {
                id: isRaiseHandIndicator
                anchors.right: participantRect.right
                anchors.top: participantRect.top
                checkable: root.meModerator
                hoveredColor: JamiTheme.raiseHandColor
                imageColor: JamiTheme.whiteColor
                normalColor: JamiTheme.raiseHandColor
                preferredSize: shapeHeight
                pressedColor: JamiTheme.raiseHandColor
                radius: 5
                source: JamiResources.hand_black_24dp_svg
                toolTipText: root.meModerator ? JamiStrings.lowerHand : ""
                visible: root.participantHandIsRaised
                z: participantRect.z + 1

                onClicked: CallAdapter.raiseHand(uri, deviceId, false)
            }
            Item {
                id: recordingIndicator
                anchors.right: isRaiseHandIndicator.visible ? isRaiseHandIndicator.left : participantRect.right
                anchors.top: participantRect.top
                height: shapeHeight
                visible: root.isRecording
                width: JamiTheme.recordingIndicatorSize
                z: participantRect.z + 1

                Rectangle {
                    anchors.centerIn: parent
                    color: JamiTheme.recordIconColor
                    height: JamiTheme.recordingBtnSize
                    radius: height / 2
                    width: JamiTheme.recordingBtnSize

                    SequentialAnimation on color  {
                        loops: Animation.Infinite
                        running: recordingIndicator.visible

                        ColorAnimation {
                            duration: JamiTheme.recordBlinkDuration
                            from: JamiTheme.recordIconColor
                            to: "transparent"
                        }
                        ColorAnimation {
                            duration: JamiTheme.recordBlinkDuration
                            from: "transparent"
                            to: JamiTheme.recordIconColor
                        }
                    }
                }
            }
            Rectangle {
                id: alertMessage
                anchors.centerIn: parent
                color: JamiTheme.darkGreyColorOpacity
                height: alertMessageTxt.contentHeight + 16
                radius: 5
                visible: root.muteAlertActive
                width: alertMessageTxt.width + 16

                Text {
                    id: alertMessageTxt
                    anchors.centerIn: parent
                    color: JamiTheme.whiteColor
                    font.pointSize: JamiTheme.textFontSize
                    horizontalAlignment: Text.AlignHCenter
                    text: root.muteAlertMessage
                    verticalAlignment: Text.AlignVCenter
                    width: Math.min(participantRect.width, contentWidth)
                    wrapMode: Text.Wrap
                }
                Timer {
                    id: alertTimer
                    interval: JamiTheme.overlayFadeDelay

                    onTriggered: {
                        root.muteAlertActive = false;
                    }
                }
            }
        }
        underlayItems: Avatar {
            property real componentSize: Math.min(mediaDistRender.contentRect.width / 2, mediaDistRender.contentRect.height / 2)
            property real size: Math.floor((componentSize + step - 1) / step) * step
            // round the avatar source size up to some nearest multiple
            readonly property real step: 96

            anchors.centerIn: parent
            height: componentSize
            mode: root.isMe ? Avatar.Mode.Account : Avatar.Mode.Contact
            showPresenceIndicator: false
            sourceSize: Qt.size(size, size)
            visible: root.videoMuted
            width: componentSize

            onVisibleChanged: {
                // Only request avatars when visibility changes (and once)
                // This avoid to request images for non showed participants
                if (visible && !imageId) {
                    imageId = root.isMe ? LRCInstance.currentAccountId : root.uri;
                }
            }
        }
    }
}
