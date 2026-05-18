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
    //
    // The window-side property-change signals can be delivered
    // asynchronously by the window manager, so we don't rely on a
    // re-entrancy flag. Instead, _applyVideoAspect() is idempotent:
    // it computes the target geometry and bails out if the window is
    // already within one pixel of it, breaking any feedback loop
    // naturally. _restored avoids overriding the user's persisted
    // geometry on the very first frame after restoration.
    property bool _restored: false
    property real _lastInvAspect: 0
    // Track whether _lastInvAspect has ever been set; this preserves the
    // "user resize" path when the remote camera temporarily drops and
    // resumes at the same resolution.
    property bool _lastInvAspectInit: false

    function _applyVideoAspect() {
        if (!_restored)
            return;
        const r = content.videoInvAspectRatio;
        if (r <= 0)
            return;
        // Relative threshold so the check works equally well for very
        // tall (e.g. 9:21) and very wide (e.g. 21:9) aspect ratios.
        const aspectChanged = _lastInvAspectInit
                              && Math.abs(r - _lastInvAspect) / _lastInvAspect > 0.01;
        let newWidth, newHeight;
        if (aspectChanged) {
            // Aspect ratio changed (e.g. rotation): preserve the
            // on-screen area and just reshape the window. We derive
            // height from width after clamping so the resulting
            // proportions exactly match r even at the minimum-size
            // boundary.
            const area = width * height;
            newWidth = Math.max(minimumWidth, Math.round(Math.sqrt(area / r)));
            newHeight = Math.max(minimumHeight, Math.round(newWidth * r));
        } else {
            // Initial subscription or user resize: match height to the
            // current width.
            newWidth = width;
            newHeight = Math.max(minimumHeight, Math.round(width * r));
        }
        _lastInvAspect = r;
        _lastInvAspectInit = true;
        if (Math.abs(newWidth - width) <= 1 && Math.abs(newHeight - height) <= 1)
            return;
        // Assign in one shot. Even if the property-change signals fire
        // asynchronously and re-enter this function, the dimension
        // check above will short-circuit and we won't recurse.
        if (newWidth !== width)
            width = newWidth;
        if (newHeight !== height)
            height = newHeight;
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

    // Geometry persistence. Saves are coalesced through a short timer
    // so a programmatic aspect-ratio adjustment (which fires both
    // onWidthChanged and onHeightChanged) only writes once, at the
    // final settled size.
    Timer {
        id: saveGeometryTimer
        interval: 50
        repeat: false
        onTriggered: AppSettingsManager.setValue(Settings.PipWindowGeometry,
                                                 Qt.rect(root.x, root.y, root.width, root.height))
    }
    function saveGeometry() { saveGeometryTimer.restart(); }

    function restoreGeometry() {
        const saved = AppSettingsManager.getValue(Settings.PipWindowGeometry);
        if (saved && saved.width > 0 && saved.height > 0) {
            root.x = saved.x;
            root.y = saved.y;
            root.width = saved.width;
            root.height = saved.height;
        }
    }

    onClosing: {
        // Flush any pending coalesced save synchronously.
        saveGeometryTimer.stop();
        AppSettingsManager.setValue(Settings.PipWindowGeometry,
                                    Qt.rect(root.x, root.y, root.width, root.height));
    }
    onXChanged: saveGeometry()
    onYChanged: saveGeometry()
    onWidthChanged: { _applyVideoAspect(); saveGeometry(); }
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
