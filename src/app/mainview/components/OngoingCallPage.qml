/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

    // Constraints for the preview component.
    property int previewMargin: 15
    property int previewMarginYTop: previewMargin + 42
    property int previewMarginYBottom: previewMargin + 84

    property alias chatViewContainer: chatViewContainer
    property string callPreviewId

    // A link to the first child will provide access to the chat view.
    property var chatView: chatViewContainer.children[0]

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

    function setCallChatVisibility(visible) {
        if (visible) {
            mainColumnLayout.isHorizontal = UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally);
            chatViewContainer.visible = false;
            chatViewContainer.visible = true;
        } else {
            chatViewContainer.visible = false;
        }
    }

    function toggleCallChatVisibility() {
        setCallChatVisibility(!chatViewContainer.visible);
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

                anchors.topMargin: previewMarginYTop
                anchors.leftMargin: previewMargin
                anchors.rightMargin: previewMargin
                anchors.bottomMargin: previewMarginYBottom

                states: [
                    // Not anchored
                    State {
                        name: ""
                        AnchorChanges {
                            target: previewRenderer
                            anchors.top: undefined
                            anchors.right: undefined
                            anchors.bottom: undefined
                            anchors.left: undefined
                        }
                    },
                    State {
                        name: "anchor_top_left"
                        AnchorChanges {
                            target: previewRenderer
                            anchors.top: callPageMainRect.top
                            anchors.left: callPageMainRect.left
                        }
                    },
                    State {
                        name: "anchor_top_right"
                        AnchorChanges {
                            target: previewRenderer
                            anchors.top: callPageMainRect.top
                            anchors.right: callPageMainRect.right
                        }
                    },
                    State {
                        name: "anchor_bottom_right"
                        AnchorChanges {
                            target: previewRenderer
                            anchors.bottom: callPageMainRect.bottom
                            anchors.right: callPageMainRect.right
                        }
                    },
                    State {
                        name: "anchor_bottom_left"
                        AnchorChanges {
                            target: previewRenderer
                            anchors.bottom: callPageMainRect.bottom
                            anchors.left: callPageMainRect.left
                        }
                    }
                ]

                transitions: Transition {
                    AnchorAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
                        onStopped: previewRenderer.state = ""
                    }
                }

                DragHandler {
                    readonly property var container: callPageMainRect
                    target: parent
                    xAxis.maximum: container.width - parent.width - previewMargin
                    xAxis.minimum: previewMargin
                    yAxis.maximum: container.height - parent.height - previewMarginYBottom
                    yAxis.minimum: previewMarginYTop
                    onActiveChanged: {
                        if (active) {
                            previewRenderer.state = "";
                        } else {
                            const center = Qt.point(target.x + target.width / 2,
                                                    target.y + target.height / 2);
                            const containerCenter = Qt.point(container.x + container.width / 2,
                                                             container.y + container.height / 2);
                            if (center.x >= containerCenter.x) {
                                if (center.y >= containerCenter.y) {
                                    previewRenderer.state = "anchor_bottom_right";
                                } else {
                                    previewRenderer.state = "anchor_top_right";
                                }
                            } else {
                                if (center.y >= containerCenter.y) {
                                    previewRenderer.state = "anchor_bottom_left";
                                } else {
                                    previewRenderer.state = "anchor_top_left";
                                }
                            }
                        }
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

                objectName: "callOverlay"

                anchors.fill: parent

                function toggleConversation() {
                    toggleCallChatVisibility();
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

                onChatButtonClicked: toggleCallChatVisibility()
                onFullScreenClicked: callStackView.toggleFullScreen()
                onSwarmDetailsClicked: {
                    toggleCallChatVisibility();
                    if (chatViewContainer.visible) {
                        chatView.switchToPanel(ChatView.SwarmDetailsPanel);
                    }
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
