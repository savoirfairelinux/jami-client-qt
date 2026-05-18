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

    // Keep the window matched to the current video aspect ratio.
    property bool geometryRestored: false
    property real lastVideoInvAspect: 0
    function applyVideoAspect(fromHeight) {
        const videoInvAspect = geometryRestored ? content.videoInvAspectRatio : 0;
        if (videoInvAspect <= 0)
            return;
        let newWidth, newHeight;
        if (fromHeight) {
            newWidth = Math.round(height / videoInvAspect);
            if (newWidth < minimumWidth) {
                newWidth = minimumWidth;
                newHeight = Math.max(minimumHeight, Math.round(newWidth * videoInvAspect));
            } else {
                newHeight = height;
            }
        } else if (lastVideoInvAspect > 0
                   && Math.abs(videoInvAspect - lastVideoInvAspect) / lastVideoInvAspect > 0.01) {
            const area = width * height;
            newWidth = Math.max(minimumWidth, Math.round(Math.sqrt(area / videoInvAspect)));
            newHeight = Math.round(newWidth * videoInvAspect);
            if (newHeight < minimumHeight) {
                newHeight = minimumHeight;
                newWidth = Math.max(minimumWidth, Math.round(newHeight / videoInvAspect));
            }
        } else {
            newWidth = width;
            newHeight = Math.round(width * videoInvAspect);
            if (newHeight < minimumHeight) {
                newHeight = minimumHeight;
                newWidth = Math.max(minimumWidth, Math.round(newHeight / videoInvAspect));
            }
        }
        root.setAspectGeometry(newWidth, newHeight);
        lastVideoInvAspect = videoInvAspect;
    }

    Connections {
        target: content
        function onVideoInvAspectRatioChanged() { root.applyVideoAspect(); }
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

    // Guards programmatic width/height writes so onWidthChanged and
    // onHeightChanged do not re-enter the opposite resize path.
    property bool adjustingAspectGeometry: false

    // Applies width/height updates once while suppressing resize-handler feedback loops.
    // The guard is released via Qt.callLater rather than synchronously, since some
    // window managers confirm/clamp the requested size asynchronously and would
    // otherwise re-enter applyVideoAspect() after the guard was already cleared.
    function setAspectGeometry(newWidth, newHeight) {
        adjustingAspectGeometry = true;
        if (newWidth !== width)
            width = newWidth;
        if (newHeight !== height)
            height = newHeight;
        _settledWidth = width;
        _settledHeight = height;
        Qt.callLater(function () { adjustingAspectGeometry = false; });
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

    onClosing: {
        // Flush any pending coalesced save synchronously.
        saveGeometryTimer.stop();
        AppSettingsManager.setValue(Settings.PipWindowGeometry,
                                    Qt.rect(root.x, root.y, root.width, root.height));
    }
    onXChanged: saveGeometry()
    onYChanged: saveGeometry()

    // A corner drag delivers width and height changes in the same event-loop
    // turn, in unspecified order. Calling applyVideoAspect() straight from
    // each handler makes the two calls derive opposite dimensions and race:
    // whichever handler runs last wins, and the first call's geometry is
    // immediately overwritten. Coalesce both into a single, 0-interval-later
    // pass that compares against the last settled size to tell which edge
    // actually moved.
    property real _settledWidth: width
    property real _settledHeight: height
    Timer {
        id: applyAspectTimer
        interval: 0
        repeat: false
        onTriggered: {
            const widthChanged = root.width !== root._settledWidth;
            const heightChanged = root.height !== root._settledHeight;
            root.applyVideoAspect(heightChanged && !widthChanged);
            root._settledWidth = root.width;
            root._settledHeight = root.height;
        }
    }
    onWidthChanged: {
        if (!adjustingAspectGeometry)
            applyAspectTimer.restart();
        saveGeometry();
    }
    onHeightChanged: {
        if (!adjustingAspectGeometry)
            applyAspectTimer.restart();
        saveGeometry();
    }

    Component.onCompleted: {
        restoreGeometry();
        _settledWidth = width;
        _settledHeight = height;
        geometryRestored = true;
        applyVideoAspect();
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
