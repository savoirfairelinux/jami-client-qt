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
    minimumWidth: 280
    minimumHeight: 200

    color: "black"

    flags: Qt.Window | Qt.WindowStaysOnTopHint

    // ── Remote video ─────────────────────────────────────────────────────────
    VideoView {
        id: remoteVideo
        anchors {
            top: pipToolBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        // Use the PiP call ID from the manager — stays valid after conv switch.
        rendererId: CallPipWindowManager.pipCallId
        // Crop to fill the small window rather than letterboxing
        crop: true
    }

    // ── Minimal toolbar ──────────────────────────────────────────────────────
    Rectangle {
        id: pipToolBar
        width: parent.width
        height: useFrameless ? JamiTheme.qwkTitleBarHeight : implicitHeight
        implicitHeight: 36
        color: JamiTheme.globalBackgroundColor
        z: 2

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: useFrameless && sysBtnsLoader.active ? sysBtnsLoader.width + 4 : 4
            }
            spacing: 6

            // Call duration timer
            Text {
                id: durationLabel
                Layout.alignment: Qt.AlignVCenter
                color: JamiTheme.faddedLastInteractionFontColor
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
                iconSource: JamiResources.micro_black_24dp_svg
                toolTipText: qsTr("Mute audio")
                onClicked: CallAdapter.muteAudioToggle(CallPipWindowManager.pipAccountId,
                                                       CallPipWindowManager.pipConvId)
            }

            // Mute camera button
            NewIconButton {
                id: muteCameraBtn
                Layout.alignment: Qt.AlignVCenter
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.videocam_24dp_svg
                toolTipText: qsTr("Mute camera")
                onClicked: CallAdapter.muteCameraToggle(CallPipWindowManager.pipAccountId,
                                                        CallPipWindowManager.pipConvId)
            }

            // Return-to-call button
            NewIconButton {
                id: returnBtn
                Layout.alignment: Qt.AlignVCenter
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.bidirectional_return_to_call_24dp_svg
                toolTipText: qsTr("Return to call")
                onClicked: CallPipWindowManager.reabsorb()
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

        // QWK: system buttons (minimize / maximize / close) in frameless mode.
        Loader {
            id: sysBtnsLoader
            active: useFrameless && Qt.platform.os.toString() !== "osx"
            height: parent.height
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 1
                rightMargin: 1
            }
            source: "qrc:/commoncomponents/QWKSystemButtonGroup.qml"
            onLoaded: item.targetWindow = root
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
        if (useFrameless) {
            windowAgent.setup(root);
            Qt.callLater(function () {
                windowAgent.setTitleBar(pipToolBar);
                // Action buttons sit inside the title bar: mark them as
                // hit-test visible so QWindowKit passes clicks through
                // instead of consuming them for window dragging.
                windowAgent.setHitTestVisible(muteAudioBtn, true);
                windowAgent.setHitTestVisible(muteCameraBtn, true);
                windowAgent.setHitTestVisible(returnBtn, true);
                windowAgent.setHitTestVisible(endCallBtn, true);
                if (sysBtnsLoader.item && Qt.platform.os.toString() !== "osx") {
                    windowAgent.setSystemButton(WindowAgent.Minimize, sysBtnsLoader.item.minButton);
                    windowAgent.setSystemButton(WindowAgent.Maximize, sysBtnsLoader.item.maxButton);
                    windowAgent.setSystemButton(WindowAgent.Close, sysBtnsLoader.item.closeButton);
                }
            });
        }
    }
}
