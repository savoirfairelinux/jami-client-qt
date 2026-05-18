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

    readonly property bool useFrameless: UtilsAdapter.getAppValue(Settings.Key.UseFramelessWindow)
    readonly property real scaleVal: Math.min(width / minimumWidth, height / minimumHeight)
    readonly property real iconButtonSize: Math.min(JamiTheme.iconButtonSmall * scaleVal, JamiTheme.iconButtonMedium)

    title: JamiStrings.pipTitle

    width: 400
    height: 300
    minimumWidth: 260
    minimumHeight: 180

    color: JamiTheme.blackColor

    flags: Qt.Window | Qt.WindowStaysOnTopHint

    // Keep the window's aspect ratio in sync with the incoming video
    // stream, so the user always sees the full frame without crop or
    // letterboxing. When the video aspect ratio changes (typically when
    // the remote phone rotates), we preserve the on-screen area so the
    // window doesn't suddenly shrink or grow — only its shape changes.
    // When the user resizes the window manually, we update height to
    // match the current video AR.
    // _resizing guards against re-entrancy while we programmatically
    // change the size, and _restored ensures we don't override the
    // user's persisted geometry on the very first frame.
    property bool _resizing: false
    property bool _restored: false
    property real _lastInvAspect: 0

    function _applyVideoAspect() {
        if (!_restored)
            return;
        const r = content.videoInvAspectRatio;
        if (r <= 0)
            return;
        if (_lastInvAspect > 0 && Math.abs(r - _lastInvAspect) > 0.001) {
            // Aspect ratio changed (e.g., rotation): keep the same area
            // and just reshape the window.
            const area = width * height;
            const newWidth = Math.max(minimumWidth, Math.round(Math.sqrt(area / r)));
            const newHeight = Math.max(minimumHeight, Math.round(Math.sqrt(area * r)));
            _resizing = true;
            width = newWidth;
            height = newHeight;
            _resizing = false;
        } else {
            // Initial subscription or user resize: just match the height.
            const newHeight = Math.max(minimumHeight, Math.round(width * r));
            if (Math.abs(newHeight - height) > 1) {
                _resizing = true;
                height = newHeight;
                _resizing = false;
            }
        }
        _lastInvAspect = r;
    }

    Connections {
        target: content
        function onVideoInvAspectRatioChanged() { root._applyVideoAspect(); }
    }

    // Drag handle — covers the whole window so the user can move it anywhere
    // except over hit-test-visible interactive items.
    Item {
        id: dragHandle
        anchors.fill: parent
        z: -1
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
    onWidthChanged: { if (!_resizing) _applyVideoAspect(); saveGeometry(); }
    onHeightChanged: saveGeometry()

    Component.onCompleted: {
        restoreGeometry();
        _restored = true;
        _applyVideoAspect();
        CallOverlayModel.setEventFilterActive(root, content, true);
        if (JamiQmlUtils.isMacOS26OrLater) {
            MainApplication.setupPipWindow(root);
        } else if (useFrameless) {
            windowAgent.setup(root);
            Qt.callLater(function () {
                // Entire video area serves as the drag handle for moving the window.
                windowAgent.setTitleBar(dragHandle);
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
