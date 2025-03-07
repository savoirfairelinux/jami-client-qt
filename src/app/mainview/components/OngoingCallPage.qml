/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

    property alias chatViewContainer: chatViewContainer
    property string callPreviewId

    // A link to the first child will provide access to the chat view.
    property var chatView: chatViewContainer.children[0]

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
        if (chatViewContainer.visible && root.width < JamiTheme.mainViewMajorPaneMinWidth * 2) {
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
            SplitView.minimumWidth: JamiTheme.mainViewMajorPaneMinWidth
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
                        var isOnLocal = eventPoint.position.x >= localPreview.x && eventPoint.position.x <= localPreview.x + localPreview.width;
                        isOnLocal &= eventPoint.position.y >= localPreview.y && eventPoint.position.y <= localPreview.y + localPreview.height;
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

            // Note: this component should not be used within a layout, as
            // it implements anchor management itself.
            InCallLocalVideo {
                id: localPreview
                objectName: "localPreview"

                container: parent
                rendererId: CurrentCall.previewId
                opacityModifier: callOverlay.mainOverlayOpacity
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
                    if(chatViewContainer.visible) {
                        if(ChatView.SwarmDetailsPanel.visible) {
                            ChatView.SwarmDetailsPanel.visible = false;
                        }
                        else {
                            chatView.switchToPanel(ChatView.SwarmDetailsPanel);
                        }
                    }
                    else {
                        toggleCallChatVisibility();
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
            SplitView.preferredWidth: mainColumnLayout.isHorizontal ? JamiTheme.mainViewMajorPaneMinWidth : root.width
            SplitView.minimumWidth: JamiTheme.mainViewMajorPaneMinWidth
            visible: false
            clip: true
            property bool showDetails: false

            onVisibleChanged: {
                if (visible && root.width < JamiTheme.mainViewMajorPaneMinWidth * 2) {
                    callPageMainRect.visible = false;
                } else {
                    callPageMainRect.visible = true;
                }
            }
        }
    }
}
