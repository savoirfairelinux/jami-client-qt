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
import QWindowKit

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "commoncomponents"

// Picture-in-Picture call window.
// Shown automatically when the user navigates away from a conversation
// that has an active call. Managed by CallPipWindowManager.
// Visual content lives in CallPipWindowContent.qml so it can be tested
// independently of the ApplicationWindow / QWindowKit stack.
Window {
    id: root

    // Set by CallPipWindowManager via createWithInitialProperties.
    property string pipConvId: ""
    property string pipAccountId: ""

    readonly property bool useFrameless: JamiQmlUtils.isMacOS26OrLater || UtilsAdapter.getAppValue(Settings.Key.UseFramelessWindow)
    readonly property real scaleVal: Math.min(width / minimumWidth, height / minimumHeight)
    readonly property real iconButtonSize: Math.min(JamiTheme.iconButtonSmall * scaleVal, JamiTheme.iconButtonMedium)

    title: JamiStrings.pipTitle

    width: 400
    height: 300
    minimumWidth: 260
    minimumHeight: 180

    color: JamiTheme.blackColor

    flags: Qt.Window | Qt.WindowStaysOnTopHint

    // Drag handle — covers the whole window so the user can move it anywhere
    // except over hit-test-visible interactive items.
    Item {
        id: dragHandle
        anchors.fill: parent
        z: -1

        // On Windows (frameless), use startSystemMove() for dragging instead of
        // QWindowKit's setTitleBar, to avoid HTCAPTION blocking hover events.
        DragHandler {
            enabled: root.useFrameless && !JamiQmlUtils.isMacOS26OrLater
            target: null
            onActiveChanged: if (active) root.startSystemMove()
        }
    }

    MouseArea {
        id: macDragArea
        anchors.fill: parent
        visible: JamiQmlUtils.isMacOS26OrLater
        enabled: JamiQmlUtils.isMacOS26OrLater
        z: 10
        onPressed: function(mouse) {
            MainApplication.startSystemMove(root);
            mouse.accepted = false;
        }
    }

    // All call-related visual content (video, avatars, buttons, labels).
    CallPipWindowContent {
        id: content
        anchors.fill: parent
        scaleVal: root.scaleVal
        iconButtonSize: root.iconButtonSize
        useFrameless: root.useFrameless

        onEndCallRequested: root.close()
    }

    // QWK-style close button — top-right corner, fades in/out with the overlay.
    QWKButton {
        id: closePipButton

        anchors.top: parent.top
        anchors.right: parent.right

        height: Math.min(JamiTheme.iconButtonLarge * scaleVal, JamiTheme.qwkTitleBarHeight)
        visible: root.useFrameless || JamiQmlUtils.isMacOS26OrLater
        source: JamiResources.window_bar_close_svg
        forceLightIcons: true
        baseColor: "#e81123"
        opacity: (content.isHovered || closePipButton.hovered) ? 1.0 : 0.0
        enabled: visible

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        onClicked: root.close()

        states: State {
            name: "macOS26"
            when: JamiQmlUtils.isMacOS26OrLater
            AnchorChanges {
                target: closePipButton
                anchors.right: undefined
                anchors.left: parent.left
            }
            PropertyChanges {
                target: closePipButton
                anchors.topMargin: JamiTheme.pipActionButtonMarginMac
                anchors.leftMargin: JamiTheme.pipActionButtonMarginMac
                height: root.iconButtonSize + root.iconButtonSize / 2
                width: root.iconButtonSize + root.iconButtonSize / 2
                backgroundRadius: height / 2
            }
        }
    }

    // QWK frameless window agent
    WindowAgent { id: windowAgent }

    // Geometry persistence
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
        CallOverlayModel.setEventFilterActive(root, content, true);
        if (JamiQmlUtils.isMacOS26OrLater) {
            MainApplication.setupPipWindow(root);
        } else if (useFrameless) {
            windowAgent.setup(root);
            Qt.callLater(function () {
                // No title bar registered - dragging is handled by DragHandler
                // via startSystemMove() to keep the full window as HTCLIENT.
                windowAgent.setHitTestVisible(content.muteAudioButton, true);
                windowAgent.setHitTestVisible(content.muteCameraButton, true);
                windowAgent.setHitTestVisible(content.endCallButton, true);
                windowAgent.setHitTestVisible(closePipButton, true);
                windowAgent.setHitTestVisible(content.raiseHandControl, true);
                windowAgent.setHitTestVisible(content.popOutButton, true);
                windowAgent.setHitTestVisible(content.emptyConferenceVisuals, true);
                windowAgent.setSystemButton(WindowAgent.Close, closePipButton);
            });
        }
    }

    Component.onDestruction: CallOverlayModel.setEventFilterActive(root, content, false)
}
