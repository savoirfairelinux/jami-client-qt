/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

    property var accountPeerPair: [CurrentAccount.id, CurrentConversation.id]
    property point clickPos
    property int previewMargin: 15
    property int previewMarginYTop: previewMargin + 42
    property int previewMarginYBottom: previewMargin + 84
    property int previewToX: 0
    property int previewToY: 0
    property alias chatViewContainer: chatViewContainer
    property string callPreviewId

    onCallPreviewIdChanged: {
        controlPreview.start()
    }

    color: "black"

    onAccountPeerPairChanged: {
        if (accountPeerPair[0] === "" || accountPeerPair[1] === "")
            return
        contactImage.imageId = accountPeerPair[1]
    }

    Connections {
        target: UtilsAdapter

        function onChatviewPositionChanged() {
            mainColumnLayout.isHorizontal = UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally)
        }
    }

    function openInCallConversation() {
        mainColumnLayout.isHorizontal = UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally)
        chatViewContainer.visible = true
    }

    function closeInCallConversation() {
        chatViewContainer.visible = false
    }

    function closeContextMenuAndRelatedWindows() {
        callOverlay.closeContextMenuAndRelatedWindows()
    }

    function previewMagneticSnap() {
        // Calculate the position where the previewRenderer should attach to.
        var previewRendererCenter = Qt.point(
                    previewRenderer.x + previewRenderer.width / 2,
                    previewRenderer.y + previewRenderer.height / 2)
        var parentCenter = Qt.point(
                    parent.x + parent.width / 2,
                    parent.y + parent.height / 2)

        if (previewRendererCenter.x >= parentCenter.x) {
            if (previewRendererCenter.y >= parentCenter.y) {
                // Bottom right.
                previewToX = Qt.binding(function () {
                    return callPageMainRect.width - previewRenderer.width - previewMargin
                })
                previewToY = Qt.binding(function () {
                    return callPageMainRect.height - previewRenderer.height - previewMarginYBottom
                })
            } else {
                // Top right.
                previewToX = Qt.binding(function () {
                    return callPageMainRect.width - previewRenderer.width - previewMargin
                })
                previewToY = previewMarginYTop
            }
        } else {
            if (previewRendererCenter.y >= parentCenter.y) {
                // Bottom left.
                previewToX = previewMargin
                previewToY = Qt.binding(function () {
                    return callPageMainRect.height - previewRenderer.height - previewMarginYBottom
                })
            } else {
                // Top left.
                previewToX = previewMargin
                previewToY = previewMarginYTop
            }
        }
        previewRenderer.state = "geoChanging"
    }

    SplitView {
        id: mainColumnLayout

        anchors.fill: parent

        property bool isHorizontal: false // Calculated when showing the stack view
        orientation: isHorizontal ? Qt.Horizontal : Qt.Vertical

        handle: Rectangle {
            implicitWidth: isHorizontal ? JamiTheme.splitViewHandlePreferredWidth : root.width
            implicitHeight: isHorizontal ? root.height : JamiTheme.splitViewHandlePreferredWidth
            color: SplitHandle.pressed ? JamiTheme.pressColor :
                                         (SplitHandle.hovered ? JamiTheme.hoverColor :
                                                                JamiTheme.tabbarBorderColor)
        }

        Rectangle {
            id: callPageMainRect

            SplitView.preferredHeight: mainColumnLayout.isHorizontal ? root.height : (root.height / 3) * 2
            SplitView.preferredWidth: mainColumnLayout.isHorizontal ? (root.width / 3) * 2 : root.width
            SplitView.minimumHeight: root.height / 2 + 20
            SplitView.minimumWidth: root.width / 2 + 20
            SplitView.fillWidth: !mainColumnLayout.isHorizontal

            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onDoubleTapped: function (eventPoint, button) {
                    if (button === Qt.LeftButton) {
                        callStackView.toggleFullScreen()
                    }
                }

                onTapped: function (eventPoint, button) {
                    if (button === Qt.RightButton) {
                        callOverlay.openCallViewContextMenuInPos(eventPoint.position.x,
                                                                 eventPoint.position.y,
                                                                 participantsLayer.hoveredOverlayUri,
                                                                 participantsLayer.hoveredOverlaySinkId,
                                                                 participantsLayer.hoveredOverVideoMuted)
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
                    instantiate(JamiStrings.screenshotTaken.arg(UtilsAdapter.getDirScreenshot()),1000,400)
                }
            }

            LocalVideo {
                id: previewRenderer
                visible: (CurrentCall.isSharing || !CurrentCall.isVideoMuted)
                         && !CurrentCall.isConference

                height: width * invAspectRatio
                width: Math.max(callPageMainRect.width / 5, JamiTheme.minimumPreviewWidth)
                x: callPageMainRect.width - previewRenderer.width - previewMargin
                y: previewMarginYTop

                // HACK: this is a workaround to the preview video starting
                // and stopping a few times. The root cause should be investigated ASAP.
                Timer {
                    id: controlPreview
                    property bool startVideo
                    interval: 1000
                    onTriggered: {
                        var rendId = visible && startVideo ? root.callPreviewId : ""
                        previewRenderer.startWithId(rendId)
                    }
                }

                onVisibleChanged: {
                    controlPreview.stop()
                    if (visible) {
                        controlPreview.startVideo = true
                        controlPreview.interval = 1000
                    } else {
                        controlPreview.startVideo = false
                        controlPreview.interval = 0
                    }
                    controlPreview.start()
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
                            previewRenderer.state = ""
                        }
                    }
                }

                MouseArea {
                    id: dragMouseArea

                    anchors.fill: previewRenderer

                    onPressed: function (mouse) {
                        clickPos = Qt.point(mouse.x, mouse.y)
                    }

                    onReleased: {
                        previewRenderer.state = ""
                        previewMagneticSnap()
                    }

                    onPositionChanged: function (mouse) {
                        // Calculate mouse position relative change.
                        var delta = Qt.point(mouse.x - clickPos.x,
                                             mouse.y - clickPos.y)
                        var deltaW = previewRenderer.x + delta.x + previewRenderer.width
                        var deltaH = previewRenderer.y + delta.y + previewRenderer.height

                        // Check if the previewRenderer exceeds the border of callPageMainRect.
                        if (deltaW < callPageMainRect.width
                                && previewRenderer.x + delta.x > 1)
                            previewRenderer.x += delta.x
                        if (deltaH < callPageMainRect.height
                                && previewRenderer.y + delta.y > 1)
                            previewRenderer.y += delta.y
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
                        closeInCallConversation()
                    else
                        openInCallConversation()
                }

                Connections {
                    target: CurrentCall

                    function onPreviewIdChanged() {
                        if (CurrentCall.previewId !== "") {
                            if (root.callPreviewId !== "" &&
                                    root.callPreviewId !== CurrentCall.previewId) {
                                VideoDevices.stopDevice(root.callPreviewId)
                            }
                            VideoDevices.startDevice(CurrentCall.previewId)
                        } else {
                            VideoDevices.stopDevice(root.callPreviewId)
                        }
                        root.callPreviewId = CurrentCall.previewId
                    }
                }

                Connections {
                    target: MessagesAdapter
                    enabled: root.visible

                    function onNewInteraction(id, interactionType) {
                        // Ignore call notifications, as we are in the call.
                        if (interactionType !== Interaction.Type.CALL &&
                                !chatViewContainer.visible)
                            openInCallConversation()
                    }
                }

                onCloseClicked: {
                    participantsLayer.hoveredOverlayUri = ""
                    participantsLayer.hoveredOverlaySinkId = ""
                    participantsLayer.hoveredOverVideoMuted = true
                }

                onChatButtonClicked: {
                    chatViewContainer.visible ?
                                closeInCallConversation() :
                                openInCallConversation()
                }

                onFullScreenClicked: {
                    callStackView.toggleFullScreen()
                }
            }

            ColumnLayout {
                id: audioCallPageRectCentralRect

                anchors.centerIn: parent
                anchors.left: parent.left
                anchors.right: parent.right

                visible: !CurrentCall.isPaused &&
                         CurrentCall.isAudioOnly &&
                         !CurrentCall.isConference

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

            SplitView.preferredHeight: mainColumnLayout.isHorizontal ?
                                           root.height :
                                           root.height / 3
            SplitView.preferredWidth: mainColumnLayout.isHorizontal ?
                                          root.width / 3 :
                                          root.width
            visible: false
            clip: true
        }
    }
}
