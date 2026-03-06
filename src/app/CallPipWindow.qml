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

    readonly property bool useFrameless: UtilsAdapter.getAppValue(Settings.Key.UseFramelessWindow)

    title: qsTr("Call in progress")

    width: 400
    height: 300
    minimumWidth: 260
    minimumHeight: 180

    color: "black"

    flags: Qt.Window | Qt.WindowStaysOnTopHint

    // ── Remote video (fills entire window) ───────────────────────────────────
    VideoView {
        id: remoteVideo
        anchors.fill: parent
        // Use the PiP call ID from the manager — stays valid after conv switch.
        rendererId: CallPipWindowManager.pipCallId
        // Crop to fill the small window rather than letterboxing
        crop: true
    }

    // Full-window hover detection target for CallOverlayModel event filter.
    Item {
        id: pipHoverZone
        anchors.fill: parent
    }

    // QWK-style close button — top-right corner, fades in/out with the overlay.
    QWKButton {
        id: closePipBtn
        visible: useFrameless
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 4
            rightMargin: 4
        }
        height: JamiTheme.qwkTitleBarHeight
        source: JamiResources.window_bar_close_svg
        forceLightIcons: true
        baseColor: "#e81123"
        opacity: pipOverlay.opacity
        enabled: pipOverlay.enabled
        onClicked: root.close()
    }

    // ── Hover-activated overlay (bottom) ─────────────────────────────────────
    Item {
        id: pipOverlay
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 64
        opacity: 0
        enabled: opacity > 0.05

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
            }
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: 8
            }
            spacing: 4

            // Call duration timer
            Text {
                id: durationLabel
                Layout.alignment: Qt.AlignVCenter
                color: "white"
                font.pointSize: JamiTheme.textFontSize - 1
                text: CallPipWindowManager.pipConvId.length
                      ? CallAdapter.getCallDurationTime(CallPipWindowManager.pipAccountId,
                                                        CallPipWindowManager.pipConvId)
                      : ""

                Timer {
                    interval: 1000
                    running: root.visible && CallPipWindowManager.pipConvId.length > 0
                    repeat: true
                    onTriggered: durationLabel.text = CallAdapter.getCallDurationTime(
                                     CallPipWindowManager.pipAccountId,
                                     CallPipWindowManager.pipConvId)
                }
            }

            Item { Layout.fillWidth: true }

            // Mute audio button
            NewIconButton {
                id: muteAudioBtn
                Layout.alignment: Qt.AlignVCenter
                iconSize: JamiTheme.iconButtonMedium
                iconSource: CallPipWindowManager.pipIsAudioMuted
                            ? JamiResources.micro_off_black_24dp_svg
                            : JamiResources.micro_black_24dp_svg
                checked: CallPipWindowManager.pipIsAudioMuted
                toolTipText: CallPipWindowManager.pipIsAudioMuted ? qsTr("Unmute audio") : qsTr("Mute audio")
                onClicked: CallAdapter.muteAudioToggle(CallPipWindowManager.pipAccountId,
                                                       CallPipWindowManager.pipConvId)
            }

            // Mute camera button
            NewIconButton {
                id: muteCameraBtn
                Layout.alignment: Qt.AlignVCenter
                iconSize: JamiTheme.iconButtonMedium
                iconSource: CallPipWindowManager.pipIsCapturing
                            ? JamiResources.videocam_24dp_svg
                            : JamiResources.videocam_off_24dp_svg
                checked: !CallPipWindowManager.pipIsCapturing
                toolTipText: CallPipWindowManager.pipIsCapturing ? qsTr("Stop camera") : qsTr("Start camera")
                onClicked: CallAdapter.muteCameraToggle(CallPipWindowManager.pipAccountId,
                                                        CallPipWindowManager.pipConvId)
            }

            // End-call button
            NewIconButton {
                id: endCallBtn
                Layout.alignment: Qt.AlignVCenter
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.call_end_white_24dp_svg
                toolTipText: qsTr("End call")
                onClicked: CallAdapter.endCall(CallPipWindowManager.pipAccountId,
                                               CallPipWindowManager.pipConvId)
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: JamiTheme.overlayFadeDuration }
        }
    }

    // ── Overlay activation ────────────────────────────────────────────────────
    function kickOverlay() {
        pipOverlay.opacity = 1;
        fadeOutTimer.restart();
    }

    Connections {
        target: CallOverlayModel
        function onMouseMoved(item) {
            if (item === pipHoverZone)
                kickOverlay();
        }
    }

    Timer {
        id: fadeOutTimer
        interval: JamiTheme.overlayFadeDelay
        onTriggered: pipOverlay.opacity = 0
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
        CallOverlayModel.setEventFilterActive(root, pipHoverZone, true);
        if (useFrameless) {
            windowAgent.setup(root);
            Qt.callLater(function () {
                // Entire video area serves as the drag handle for moving the window.
                windowAgent.setTitleBar(remoteVideo);
                windowAgent.setHitTestVisible(muteAudioBtn, true);
                windowAgent.setHitTestVisible(muteCameraBtn, true);
                windowAgent.setHitTestVisible(endCallBtn, true);
                windowAgent.setHitTestVisible(closePipBtn, true);
                windowAgent.setSystemButton(WindowAgent.Close, closePipBtn);
            });
        }
    }

    Component.onDestruction: CallOverlayModel.setEventFilterActive(root, pipHoverZone, false)
}
