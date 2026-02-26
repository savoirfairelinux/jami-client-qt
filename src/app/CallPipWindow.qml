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
import QWindowKit

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "commoncomponents"

// Picture-in-Picture call window.
// Shown automatically when the user navigates away from a conversation
// that has an active call. Managed by CallPipWindowManager.
ApplicationWindow {
    id: root

    // Set by CallPipWindowManager via createWithInitialProperties.
    property string pipConvId: ""
    property string pipAccountId: ""

    readonly property bool useFrameless: true
    readonly property real scaleVal: Math.min(width / minimumWidth, height / minimumHeight)
    readonly property real iconButtonSize: Math.min(JamiTheme.iconButtonSmall * scaleVal, JamiTheme.iconButtonMedium)

    title: JamiStrings.pipTitle

    width: 400
    height: 300
    minimumWidth: 260
    minimumHeight: 180

    color: JamiTheme.blackColor

    flags: Qt.Window | Qt.WindowStaysOnTopHint

    // ── Remote video (fills entire window) ───────────────────────────────────
    VideoView {
        id: remoteVideo
        anchors.fill: parent
        // Use the PiP call ID from the manager — stays valid after conv switch.
        rendererId: CallPipWindowManager.pipCallId
        // Crop to fill the small window rather than letterboxing
        crop: true

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

            imageId: CallPipWindowManager.pipPeerUri

            onVisibleChanged: {
                // Lazy-load the image the first time the avatar becomes visible.
                if (visible && !imageId)
                    imageId = CallPipWindowManager.pipPeerUri;
            }
        }
    }

    // QWK-style close button — top-right corner, fades in/out with the overlay.
    QWKButton {
        id: closePipButton

        anchors.top: parent.top
        anchors.right: parent.right

        height: Math.min(JamiTheme.iconButtonLarge * scaleVal, JamiTheme.qwkTitleBarHeight)
        visible: useFrameless
        source: JamiResources.window_bar_close_svg
        forceLightIcons: true
        baseColor: "#e81123"
        opacity: pipWindowMouseArea.hovered ? 1.0 : 0.0
        enabled: visible

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        onClicked: root.close()
    }

    HoverHandler {
        id: pipWindowMouseArea
    }

    NewIconButton {
        id: popOutButton

        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.pipActionButtonMargin
        anchors.top: parent.top
        anchors.topMargin: JamiTheme.pipActionButtonMargin

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

    // Gradient backgrounds behind call management buttons
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

    // Call duration indicator
    Text {
        id: durationLabel

        anchors.bottom: parent.bottom
        anchors.bottomMargin: JamiTheme.pipActionButtonMargin * 3
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.pipActionButtonMargin * 3

        text: CallPipWindowManager.pipConvId.length
              ? CallAdapter.getCallDurationTime(CallPipWindowManager.pipAccountId, CallPipWindowManager.pipConvId)
              : ""
        color: JamiTheme.textColor

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
            onTriggered: durationLabel.text = CallAdapter.getCallDurationTime(CallPipWindowManager.pipAccountId, CallPipWindowManager.pipConvId)
        }
    }

    // Call management buttons
    Control {
        id: controlRow

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
            }
        }

        contentItem: Row {

            spacing: 8

            NewIconButton {
                id: muteAudioButton

                anchors.verticalCenter: parent.verticalCenter

                icon.color: JamiTheme.whiteColor
                iconSize: root.iconButtonSize
                iconSource: CallPipWindowManager.pipIsAudioMuted ? JamiResources.micro_off_black_24dp_svg : JamiResources.micro_black_24dp_svg
                toolTipText: CallPipWindowManager.pipIsAudioMuted ? JamiStrings.unmute : JamiStrings.mute

                onClicked: CallAdapter.muteAudioToggle(CallPipWindowManager.pipAccountId, CallPipWindowManager.pipConvId)
            }

            // Note this component has been heavily overwritten,
            // it will be generalized in a future patch when a coloured
            // icon button is defined.
            NewIconButton {
                id: endCallButton

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
                    CallAdapter.endCall(CallPipWindowManager.pipAccountId, CallPipWindowManager.pipConvId);
                    root.close();
                }
            }

            NewIconButton {
                id: muteCameraButton

                anchors.verticalCenter: parent.verticalCenter

                icon.color: JamiTheme.whiteColor
                iconSize: root.iconButtonSize
                iconSource: CallPipWindowManager.pipIsCapturing ? JamiResources.videocam_24dp_svg : JamiResources.videocam_off_24dp_svg
                toolTipText: CallPipWindowManager.pipIsCapturing ? JamiStrings.stopCamera : JamiStrings.startCamera

                onClicked: CallAdapter.muteCameraToggle(CallPipWindowManager.pipAccountId, CallPipWindowManager.pipConvId)
            }
        }

        background: Rectangle {
            radius: height / 2
            color: JamiTheme.pipActionButtonBackgroundColor
        }
    }

    // Button to raise hand (conferences only)
    Control {
        id: raiseHandButton

        anchors.bottom: parent.bottom
        anchors.bottomMargin: JamiTheme.pipActionButtonMargin
        anchors.right: parent.right
        anchors.rightMargin: JamiTheme.pipActionButtonMargin

        padding: JamiTheme.pipActionButtonPadding

        contentItem: NewIconButton {
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
            color: CurrentCall.isHandRaised ? JamiTheme.raiseHandColor : JamiTheme.pipActionButtonBackgroundColor

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }
    }


    // ── QWK frameless window agent ───────────────────────────────────────────
    WindowAgent { id: windowAgent }

    // ── Geometry persistence ─────────────────────────────────────────────────
    function saveGeometry() {
        AppSettingsManager.setValue(Settings.PipWindowGeometry,
                                    Qt.rect(root.x, root.y, root.width, root.height));
    }

    function restoreGeometry() {
        const saved = AppSettingsManager.getValue(Settings.PipWindowGeometry);
        if (saved && saved.width > 0 && saved.height > 0) {
            root.x = saved.x;
            root.y = saved.y;
            root.width = saved.width;
            root.height = saved.height;
        }
    }

    onClosing: saveGeometry()
    onXChanged: saveGeometry()
    onYChanged: saveGeometry()
    onWidthChanged: saveGeometry()
    onHeightChanged: saveGeometry()

    Component.onCompleted: {
        restoreGeometry();
        CallOverlayModel.setEventFilterActive(root, remoteVideo, true);
        if (useFrameless) {
            windowAgent.setup(root);
            Qt.callLater(function () {
                // Entire video area serves as the drag handle for moving the window.
                windowAgent.setTitleBar(remoteVideo);
                windowAgent.setHitTestVisible(muteAudioButton, true);
                windowAgent.setHitTestVisible(muteCameraButton, true);
                windowAgent.setHitTestVisible(endCallButton, true);
                windowAgent.setHitTestVisible(closePipButton, true);
                windowAgent.setHitTestVisible(raiseHandButton, true);
                windowAgent.setHitTestVisible(popOutButton, true);
                windowAgent.setSystemButton(WindowAgent.Close, closePipButton);
            });
        }
    }

    Component.onDestruction: CallOverlayModel.setEventFilterActive(root, remoteVideo, false)
}
