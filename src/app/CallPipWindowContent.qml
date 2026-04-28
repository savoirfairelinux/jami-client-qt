/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.impl
import QtQuick.Effects

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "commoncomponents"

// Visual content of the Picture-in-Picture call window.
// Extracted into a standalone Item so it can be tested independently
// of the ApplicationWindow / QWindowKit stack.
// Used by CallPipWindow.qml as its body.
Item {
    id: root

    // Scaling helpers — set by CallPipWindow, or kept at sane defaults in tests.
    property real scaleVal: 1.0
    property real iconButtonSize: JamiTheme.iconButtonSmall

    // When true the window chrome close-button (QWKButton) is shown.
    // False in tests (no frameless window present).
    property bool useFrameless: false

    // True when the mouse is anywhere inside the window.
    readonly property bool isHovered: pipWindowMouseArea.hovered

    // Emitted when the user clicks the end-call button so the parent window
    // can close itself immediately without waiting for the daemon round-trip.
    signal endCallRequested()

    // Expose children so CallPipWindow.qml can hand them to WindowAgent.
    readonly property alias muteAudioButton: muteAudioButton
    readonly property alias muteCameraButton: muteCameraButton
    readonly property alias endCallButton: endCallButton
    readonly property alias popOutButton: popOutButton
    readonly property alias raiseHandControl: raiseHandButton
    readonly property alias emptyConferenceVisuals: emptyConferenceVisuals

    // Remote video
    VideoView {
        id: remoteVideo
        objectName: "remoteVideo"

        anchors.fill: parent
        // Use the PiP call ID from the manager — stays valid after conv switch.
        rendererId: CallPipWindowManager.pipIsConference
                    ? CallPipWindowManager.pipActiveSpeakerSinkId
                    : CallPipWindowManager.pipCallId
        // Crop to fill the small window rather than letterboxing.
        crop: true

        visible: !CallPipWindowManager.pipIsEmptyConference

        underlayItems: Avatar {
            id: peerAvatar

            readonly property real componentSize: Math.min(remoteVideo.width / 2,
                                                           remoteVideo.height / 2)
            anchors.centerIn: parent

            width: componentSize
            height: componentSize

            visible: CallPipWindowManager.pipPeerVideoMuted

            mode: Avatar.Mode.Contact
            showPresenceIndicator: false

            imageId: CallPipWindowManager.pipIsConference
                     ? CallPipWindowManager.pipActiveSpeakerUri
                     : CallPipWindowManager.pipPeerUri

            onVisibleChanged: {
                if (visible && !imageId)
                    imageId = CallPipWindowManager.pipIsConference
                              ? CallPipWindowManager.pipActiveSpeakerUri
                              : CallPipWindowManager.pipPeerUri;
            }

            opacity: visible ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        Connections {
            target: CurrentCall

            function onIsConferenceChanged() {
                console.warn("IS CONFERENCE CHANGED", CurrentCall.isConference);
            }
        }
    }

    // Empty-conference placeholder
    Column {
        id: emptyConferenceVisuals
        objectName: "emptyConferenceVisuals"

        anchors.centerIn: parent

        visible: CallPipWindowManager.pipIsEmptyConference

        spacing: 4

        IconImage {
            id: emptyConferenceIcon

            anchors.horizontalCenter: parent.horizontalCenter

            width: root.scaleVal * JamiTheme.iconButtonLarge
            height: root.scaleVal * JamiTheme.iconButtonLarge

            source: JamiResources.ghost_line_24dp_svg
            sourceSize.width: root.scaleVal * JamiTheme.iconButtonLarge
            sourceSize.height: root.scaleVal * JamiTheme.iconButtonLarge

            color: JamiTheme.whiteColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: JamiStrings.noParticipantsInConference
            color: JamiTheme.whiteColor
            elide: Text.ElideRight
        }
    }

    // Hover detection
    HoverHandler {
        id: pipWindowMouseArea
    }

    // Pop-in / reabsorb button
    NewIconButton {
        id: popOutButton
        objectName: "popOutButton"

        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.pipActionButtonMargin
        anchors.top: parent.top
        anchors.topMargin: JamiTheme.pipActionButtonMargin


        iconColor: JamiTheme.whiteColor
        iconSource: JamiResources.bidirectional_pip_exit_24dp_svg
        iconSize: root.iconButtonSize
        toolTipText: JamiStrings.popIn

        visible: pipWindowMouseArea.hovered
        opacity: visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        onClicked: CallPipWindowManager.reabsorb()
    }

    // Gradient behind control row
    Rectangle {
        anchors.bottom: parent.bottom

        width: parent.width
        height: controlRow.height

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: JamiTheme.transparentColor }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
        }

        visible: pipWindowMouseArea.hovered
        opacity: visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    // Call duration label
    Text {
        id: durationLabel
        objectName: "durationLabel"

        anchors.bottom: parent.bottom
        anchors.bottomMargin: JamiTheme.pipActionButtonMargin * 3
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.pipActionButtonMargin * 3

        text: CallPipWindowManager.pipConvId.length
              ? CallAdapter.getCallDurationTime(CallPipWindowManager.pipAccountId,
                                               CallPipWindowManager.pipConvId)
              : ""

        color: JamiTheme.whiteColor

        font.pointSize: JamiTheme.textFontSize - 1

        visible: pipWindowMouseArea.hovered
        opacity: visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        Timer {
            interval: 1000
            running: durationLabel.visible && CallPipWindowManager.pipConvId.length > 0
            repeat: true
            onTriggered: durationLabel.text = CallAdapter.getCallDurationTime(
                             CallPipWindowManager.pipAccountId,
                             CallPipWindowManager.pipConvId)
        }
    }

    // Call management buttons
    Control {
        id: controlRow
        objectName: "controlRow"

        anchors.bottom: parent.bottom
        anchors.bottomMargin: pipWindowMouseArea.hovered ? 4 : -implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding)

        padding: 4

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
                easing.type: Easing.InOutCubic
            }
        }

        contentItem: Row {

            spacing: 8

            NewIconButton {
                id: muteAudioButton
                objectName: "muteAudioButton"

                anchors.verticalCenter: parent.verticalCenter

                iconColor: JamiTheme.whiteColor
                backgroundColor: "#4d4d4d"
                iconSize: root.iconButtonSize
                iconSource: CallPipWindowManager.pipIsAudioMuted
                            ? JamiResources.micro_off_black_24dp_svg
                            : JamiResources.micro_black_24dp_svg
                toolTipText: CallPipWindowManager.pipIsAudioMuted ? JamiStrings.unmute : JamiStrings.mute

                onClicked: CallAdapter.muteAudioToggle(CallPipWindowManager.pipAccountId,
                                                       CallPipWindowManager.pipConvId)
            }

            // Note: heavily overridden — will be generalised in a future patch
            // when a coloured icon button is defined.
            NewIconButton {
                id: endCallButton
                objectName: "endCallButton"

                anchors.verticalCenter: parent.verticalCenter

                leftInset: -controlRow.padding
                rightInset: -controlRow.padding
                topInset: -controlRow.padding
                bottomInset: -controlRow.padding

                iconSize: root.iconButtonSize
                toolTipText: JamiStrings.endCall

                contentItem: IconImage {
                    id: iconImage

                    anchors.centerIn: parent

                    width: parent.iconSize
                    height: parent.iconSize

                    source: JamiResources.call_end_white_24dp_svg
                    sourceSize.width: parent.iconSize
                    sourceSize.height: parent.iconSize

                    color: JamiTheme.whiteColor
                }

                background: Rectangle {
                    implicitWidth: parent.iconSize + (parent.iconSize / 2)
                    implicitHeight: parent.iconSize + (parent.iconSize / 2)

                    radius: height / 2

                    color: {
                        if (parent.pressed) {
                            return JamiTheme.declineButtonPressedRed;
                        } else if (parent.hovered) {
                            return JamiTheme.declineButtonHoverRed;
                        } else {
                            return JamiTheme.declineButtonRed;
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                onClicked: {
                    CallAdapter.endCall(CallPipWindowManager.pipAccountId,
                                       CallPipWindowManager.pipConvId);
                    root.endCallRequested();
                }
            }

            NewIconButton {
                id: muteCameraButton
                objectName: "muteCameraButton"

                anchors.verticalCenter: parent.verticalCenter

                iconColor: JamiTheme.whiteColor
                backgroundColor: "#4d4d4d"
                iconSize: root.iconButtonSize
                iconSource: CallPipWindowManager.pipIsCapturing
                            ? JamiResources.videocam_24dp_svg
                            : JamiResources.videocam_off_24dp_svg
                toolTipText: CallPipWindowManager.pipIsCapturing ? JamiStrings.stopCamera : JamiStrings.startCamera

                onClicked: CallAdapter.muteCameraToggle(CallPipWindowManager.pipAccountId,
                                                        CallPipWindowManager.pipConvId)
            }
        }

        background: Rectangle {
            radius: height / 2
            color: JamiTheme.pipActionButtonBackgroundColor
        }
    }

    // Raise-hand button (conferences only)
    Control {
        id: raiseHandButton
        objectName: "raiseHandButton"

        anchors.bottom: parent.bottom
        anchors.bottomMargin: JamiTheme.pipActionButtonMargin
        anchors.right: parent.right
        anchors.rightMargin: JamiTheme.pipActionButtonMargin

        padding: JamiTheme.pipActionButtonPadding

        contentItem: NewIconButton {
            iconColor: JamiTheme.whiteColor
            backgroundColor: "#4d4d4d"
            iconSource: JamiResources.hand_black_24dp_svg
            iconSize: root.iconButtonSize
            toolTipText: CurrentCall.isHandRaised ? JamiStrings.lowerHand : JamiStrings.raiseHand

            checkable: true
            checked: CurrentCall.isHandRaised

            onClicked: CallAdapter.raiseHand("", "", !CallAdapter.isHandRaised())
        }

        visible: CurrentCall.isConference && (pipWindowMouseArea.hovered || CurrentCall.isHandRaised)
        opacity: visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        background: Rectangle {
            radius: height / 2
            color: CurrentCall.isHandRaised
                   ? JamiTheme.raiseHandColor
                   : JamiTheme.pipActionButtonBackgroundColor

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }
    }
}
