/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 *         Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 *         Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root

    property point clickPos
    property int previewMargin: 15
    property int previewMarginYTop: previewMargin + 42
    property int previewMarginYBottom: previewMargin + 84
    property int previewToX: 0
    property int previewToY: 0
    property alias chatViewContainer: chatViewContainer
    property string callPreviewId

    onCallPreviewIdChanged: {
        controlPreview.start();
    }

    color: "black"

    Connections {
        target: CurrentConversation
        function onIdChanged() {
            if (CurrentConversation.id !== "")
                contactImage.imageId = CurrentConversation.id;
        }
    }

    Connections {
        target: UtilsAdapter

        function onChatviewPositionChanged() {
            mainColumnLayout.isHorizontal = UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally);
        }
    }

    function openInCallConversation() {
        mainColumnLayout.isHorizontal = UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally);
        chatViewContainer.visible = false;
        chatViewContainer.visible = true;
    }

    function closeInCallConversation() {
        chatViewContainer.visible = false;
    }

    function closeContextMenuAndRelatedWindows() {
        callOverlay.closeContextMenuAndRelatedWindows();
    }

    function previewMagneticSnap() {
        // Calculate the position where the previewRenderer should attach to.
        var previewRendererCenter = Qt.point(previewRenderer.x + previewRenderer.width / 2, previewRenderer.y + previewRenderer.height / 2);
        var parentCenter = Qt.point(parent.x + parent.width / 2, parent.y + parent.height / 2);
        if (previewRendererCenter.x >= parentCenter.x) {
            if (previewRendererCenter.y >= parentCenter.y) {
                // Bottom right.
                previewToX = Qt.binding(function () {
                        return callPageMainRect.width - previewRenderer.width - previewMargin;
                    });
                previewToY = Qt.binding(function () {
                        return callPageMainRect.height - previewRenderer.height - previewMarginYBottom;
                    });
            } else {
                // Top right.
                previewToX = Qt.binding(function () {
                        return callPageMainRect.width - previewRenderer.width - previewMargin;
                    });
                previewToY = previewMarginYTop;
            }
        } else {
            if (previewRendererCenter.y >= parentCenter.y) {
                // Bottom left.
                previewToX = previewMargin;
                previewToY = Qt.binding(function () {
                        return callPageMainRect.height - previewRenderer.height - previewMarginYBottom;
                    });
            } else {
                // Top left.
                previewToX = previewMargin;
                previewToY = previewMarginYTop;
            }
        }
        previewRenderer.state = "geoChanging";
    }

    onWidthChanged: {
        if (chatViewContainer.visible && root.width < JamiTheme.mainViewPaneMinWidth * 2) {
            callPageMainRect.visible = false;
        } else {
            callPageMainRect.visible = true;
        }
    }

    SplitView {
        id: mainColumnLayout

        anchors.fill: parent

        property bool isHorizontal: false // Calculated when showing the stack view
        orientation: isHorizontal ? Qt.Vertical : Qt.Horizontal // Chatview is horizontal if split is vertical (so chatview takes full width)

        handle: Rectangle {
            implicitWidth: mainColumnLayout.isHorizontal ? root.width : JamiTheme.splitViewHandlePreferredWidth
            implicitHeight: mainColumnLayout.isHorizontal ? JamiTheme.splitViewHandlePreferredWidth : root.height
            color: SplitHandle.pressed ? JamiTheme.pressColor : (SplitHandle.hovered ? JamiTheme.hoverColor : JamiTheme.tabbarBorderColor)
        }

        Rectangle {
            id: callPageMainRect

            SplitView.preferredHeight: mainColumnLayout.isHorizontal ? (root.height / 3) * 2 : root.height
            SplitView.minimumWidth: JamiTheme.mainViewPaneMinWidth
            SplitView.fillWidth: true

            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onDoubleTapped: function (eventPoint, button) {
                    if (button === Qt.LeftButton) {
                        callStackView.toggleFullScreen();
                    }
                }

                onTapped: function (eventPoint, button) {
                    if (button === Qt.RightButton) {
                        var isOnLocal = eventPoint.position.x >= previewRenderer.x && eventPoint.position.x <= previewRenderer.x + previewRenderer.width;
                        isOnLocal &= eventPoint.position.y >= previewRenderer.y && eventPoint.position.y <= previewRenderer.y + previewRenderer.height;
                        isOnLocal |= participantsLayer.hoveredOverlaySinkId.indexOf("camera://") === 0;
                        callOverlay.openCallViewContextMenuInPos(eventPoint.position.x, eventPoint.position.y, participantsLayer.hoveredOverlayUri, participantsLayer.hoveredOverlaySinkId, participantsLayer.hoveredOverVideoMuted, isOnLocal);
                    }
                }
            }

            VideoView {
                id: distantRenderer

                rendererId: CurrentCall.id
                anchors.centerIn: parent
                anchors.fill: parent
                z: -1

                visible: !CurrentCall.isConference && !CurrentCall.isAudioOnly
            }

            ParticipantsLayer {
                id: participantsLayer

                anchors.fill: parent
                anchors.centerIn: parent
                anchors.margins: 1
                visible: CurrentCall.isConference
                participantsSide: callOverlay.participantsSide
            }

            ToastManager {
                id: toastManager

                anchors.fill: parent

                function instantiateToast() {
                    instantiate(JamiStrings.screenshotTaken.arg(UtilsAdapter.getDirScreenshot()), 1000, 400);
                }
            }

            LocalVideo {
                id: previewRenderer
                visible: (CurrentCall.isSharing || !CurrentCall.isVideoMuted) && !CurrentCall.isConference

                height: width * invAspectRatio
                width: Math.max(callPageMainRect.width / 5, JamiTheme.minimumPreviewWidth)
                x: callPageMainRect.width - previewRenderer.width - previewMargin
                y: previewMarginYTop
                flip: CurrentCall.flipSelf && !CurrentCall.isSharing

                onRendererIdChanged: {
                    seekTimer.stop();
                    progressBar.to = 0;
                    progressBar.from = 0;
                    progressBar.value = 0;
                    CurrentCall.sharingPaused = true;
                    CurrentCall.sharingMuted = false;
                }

                overlayItems: Item {
                    id: overlayRect

                    anchors.fill: parent
                    anchors.centerIn: parent
                    visible: CurrentCall.sharingSource.startsWith("file")

                    onVisibleChanged: {
                        if (visible) {
                            progressBar.to = AVModel.getPlayerDuration(CurrentCall.sharingSource);
                        } else {
                            seekTimer.stop();
                            progressBar.to = 0;
                            progressBar.from = 0;
                            progressBar.value = 0;
                            CurrentCall.sharingPaused = true;
                            CurrentCall.sharingMuted = false;
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height / 4
                        color: "transparent"

                        HoverHandler {
                            id: mediaHover
                        }

                        RowLayout {
                            id: mediaControls
                            anchors.fill: parent
                            PushButton {
                                id: pauseBtn
                                toolTipText: CurrentCall.sharingPaused ? JamiStrings.play : JamiStrings.pause
                                source: CurrentCall.sharingPaused ? JamiResources.play_circle_outline_24dp_svg : JamiResources.pause_circle_outline_24dp_svg
                                onClicked: {
                                    CurrentCall.sharingPaused = !CurrentCall.sharingPaused
                                    AVModel.pausePlayer(CurrentCall.sharingSource, CurrentCall.sharingPaused)
                                    if (CurrentCall.sharingPaused) {
                                        seekTimer.stop();
                                    } else {
                                        seekTimer.restart();
                                    }
                                }
                            }

                            Rectangle {
                                id: seekBar
                                // Timer to fetch seek position
                                Layout.fillWidth: true
                                Layout.preferredHeight: parent.height
                                color: "transparent"

                                Slider {
                                    id: progressBar
                                    anchors.fill: parent
                                    handle.height: 10
                                    live: false

                                    onPressedChanged: {
                                        if (!pressed) {
                                            AVModel.playerSeekToTime(CurrentCall.sharingSource, progressBar.value)
                                        }
                                    }
                                }

                                Timer {
                                    id: seekTimer
                                    interval: 1000
                                    onTriggered: {
                                        if (progressBar.pressed)
                                            seekTimer.restart();

                                        if (CurrentCall.sharingPaused) {
                                            seekTimer.stop();
                                            return;
                                        }
                                        if (progressBar.from == 0) {
                                            progressBar.from = AVModel.getPlayerPosition(CurrentCall.sharingSource);
                                        }
                                        if (progressBar.to == 0) {
                                            progressBar.to = AVModel.getPlayerDuration(CurrentCall.sharingSource);
                                        }
                                        progressBar.value = AVModel.getPlayerPosition(CurrentCall.sharingSource);
                                        var delta = progressBar.value - progressBar.from;
                                        if (delta <= 0) {
                                            CurrentCall.sharingPaused = true
                                            progressBar.value = progressBar.from;
                                            seekTimer.stop();
                                            return;
                                        }
                                        seekTimer.restart();
                                    }
                                }
                            }

                            PushButton {
                                id: muteBtn
                                toolTipText: CurrentCall.sharingMuted ? JamiStrings.unmute : JamiStrings.mute
                                source: CurrentCall.sharingMuted ? JamiResources.spkoff_black_24dp_svg : JamiResources.spk_black_24dp_svg
                                onClicked: {
                                    CurrentCall.sharingMuted = !CurrentCall.sharingMuted
                                    AVModel.mutePlayerAudio(CurrentCall.sharingSource, CurrentCall.sharingMuted)
                                }
                            }
                        }
                    }
                }

                // Timer to decide when sharing overlay fade out
                Timer {
                    id: fadeOutTimer
                    interval: JamiTheme.overlayFadeDelay
                    onTriggered: {
                        if (overlayRect.hovered) {
                            fadeOutTimer.restart();
                            return;
                        }
                        overlayRect.opacity = 0;
                    }
                }

                HoverHandler {
                    id: hoverIndicator

                    onPointChanged: {
                        overlayRect.opacity = 1;
                        fadeOutTimer.restart();
                    }

                    onHoveredChanged: {
                        if (previewRenderer.hovered) {
                            overlayRect.opacity = 1;
                            fadeOutTimer.restart();
                            return;
                        }
                        overlayRect.opacity = hovered ? 1 : 0;
                    }
                }

                // HACK: this is a workaround to the preview video starting
                // and stopping a few times. The root cause should be investigated ASAP.
                Timer {
                    id: controlPreview
                    property bool startVideo
                    interval: 1000
                    onTriggered: {
                        var rendId = visible && startVideo ? root.callPreviewId : "";
                        previewRenderer.startWithId(rendId);
                    }
                }

                onVisibleChanged: {
                    controlPreview.stop();
                    if (visible) {
                        controlPreview.startVideo = true;
                        controlPreview.interval = 1000;
                    } else {
                        controlPreview.startVideo = false;
                        controlPreview.interval = 0;
                    }
                    controlPreview.start();
                }

                states: [
                    State {
                        name: "geoChanging"
                        PropertyChanges {
                            target: previewRenderer
                            x: previewToX
                            y: previewToY
                        }
                    }
                ]

                transitions: Transition {
                    PropertyAnimation {
                        properties: "x,y"
                        easing.type: Easing.OutExpo
                        duration: 250

                        onStopped: {
                            previewRenderer.state = "";
                        }
                    }
                }

                MouseArea {
                    id: dragMouseArea

                    anchors.fill: previewRenderer
                    enabled: !mediaHover.hovered
                    propagateComposedEvents: true

                    onPressed: function (mouse) {
                        clickPos = Qt.point(mouse.x, mouse.y);
                    }

                    onReleased: {
                        previewRenderer.state = "";
                        previewMagneticSnap();
                    }

                    onPositionChanged: function (mouse) {
                        // Calculate mouse position relative change.
                        var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y);
                        var deltaW = previewRenderer.x + delta.x + previewRenderer.width;
                        var deltaH = previewRenderer.y + delta.y + previewRenderer.height;

                        // Check if the previewRenderer exceeds the border of callPageMainRect.
                        if (deltaW < callPageMainRect.width && previewRenderer.x + delta.x > 1)
                            previewRenderer.x += delta.x;
                        if (deltaH < callPageMainRect.height && previewRenderer.y + delta.y > 1)
                            previewRenderer.y += delta.y;
                    }
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: previewRenderer.width
                        height: previewRenderer.height
                        radius: JamiTheme.primaryRadius
                    }
                }
            }

            CallOverlay {
                id: callOverlay

                anchors.fill: parent

                function toggleConversation() {
                    if (inCallMessageWebViewStack.visible)
                        closeInCallConversation();
                    else
                        openInCallConversation();
                }

                Connections {
                    target: CurrentCall

                    function onPreviewIdChanged() {
                        root.callPreviewId = CurrentCall.previewId;
                    }
                }

                Connections {
                    target: MessagesAdapter
                    enabled: root.visible

                    function onNewInteraction(id, interactionType) {
                        // Ignore call notifications, as we are in the call.
                        if (interactionType !== Interaction.Type.CALL && !chatViewContainer.visible)
                            openInCallConversation();
                    }
                }

                onCloseClicked: {
                    participantsLayer.hoveredOverlayUri = "";
                    participantsLayer.hoveredOverlaySinkId = "";
                    participantsLayer.hoveredOverVideoMuted = true;
                }

                onChatButtonClicked: {
                    var detailsVisible = chatViewContainer.showDetails;
                    chatViewContainer.showDetails = false;
                    !chatViewContainer.visible || detailsVisible ? openInCallConversation() : closeInCallConversation();
                }

                onFullScreenClicked: {
                    callStackView.toggleFullScreen();
                }

                onSwarmDetailsClicked: {
                    chatViewContainer.showDetails = !chatViewContainer.showDetails;
                    chatViewContainer.showDetails ? openInCallConversation() : closeInCallConversation();
                }
            }

            ColumnLayout {
                id: audioCallPageRectCentralRect

                anchors.centerIn: parent
                anchors.left: parent.left
                anchors.right: parent.right

                visible: !CurrentCall.isPaused && CurrentCall.isAudioOnly && !CurrentCall.isConference

                ConversationAvatar {
                    id: contactImage

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: JamiTheme.avatarSizeInCall
                    Layout.preferredHeight: JamiTheme.avatarSizeInCall

                    showPresenceIndicator: false
                }

                Text {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.preferredMarginSize

                    Layout.preferredWidth: root.width

                    font.pointSize: JamiTheme.titleFontSize

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    text: CurrentConversation.title
                    elide: Text.ElideMiddle
                    color: "white"
                }
            }

            color: "transparent"
        }

        Item {
            id: chatViewContainer
            objectName: "CallViewChatViewContainer"

            SplitView.preferredHeight: mainColumnLayout.isHorizontal ? root.height : root.height / 3
            SplitView.preferredWidth: mainColumnLayout.isHorizontal ? JamiTheme.mainViewPaneMinWidth : root.width
            SplitView.minimumWidth: JamiTheme.mainViewPaneMinWidth
            visible: false
            clip: true
            property bool showDetails: false

            onVisibleChanged: {
                if (visible && root.width < JamiTheme.mainViewPaneMinWidth * 2) {
                    callPageMainRect.visible = false;
                } else {
                    callPageMainRect.visible = true;
                }
            }
        }
    }
}
