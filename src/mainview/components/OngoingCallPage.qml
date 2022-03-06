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

    property var accountPeerPair: ["", ""]
    property variant clickPos: "1,1"
    property int previewMargin: 15
    property int previewMarginYTop: previewMargin + 42
    property int previewMarginYBottom: previewMargin + 84
    property int previewToX: 0
    property int previewToY: 0
    property bool isAudioOnly: false
    property alias callId: distantRenderer.rendererId
    property var linkedWebview: null
    property string callPreviewId: ""
    property bool sharingActive: AvAdapter.currentRenderingDeviceType === Video.DeviceType.DISPLAY
                                 || AvAdapter.currentRenderingDeviceType === Video.DeviceType.FILE

    onSharingActiveChanged: {
        const deviceId = AvAdapter.currentRenderingDeviceId
        previewRenderer.startWithId(deviceId, true)
    }

    color: "black"

    onAccountPeerPairChanged: {
        if (accountPeerPair[0] === "" || accountPeerPair[1] === "")
            return
        contactImage.imageId = accountPeerPair[1]
        callOverlay.participantsLayer.update(CallAdapter.getConferencesInfos())
        root.callId = UtilsAdapter.getCallId(accountPeerPair[0],
                                             accountPeerPair[1])
    }

    function setLinkedWebview(webViewId) {
        linkedWebview = webViewId
        linkedWebview.needToHideConversationInCall.disconnect(
                    closeInCallConversation)
        linkedWebview.needToHideConversationInCall.connect(
                    closeInCallConversation)
    }

    function openInCallConversation() {
        mainColumnLayout.isHorizontal = UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally)
        inCallMessageWebViewStack.visible = true
        inCallMessageWebViewStack.push(linkedWebview)
    }

    function closeInCallConversation() {
        inCallMessageWebViewStack.visible = false
        inCallMessageWebViewStack.clear()
    }

    function closeContextMenuAndRelatedWindows() {
        callOverlay.closeContextMenuAndRelatedWindows()
    }

    function handleParticipantsInfo(infos) {
        callOverlay.participantsLayer.update(infos)
    }

    function previewMagneticSnap() {
        // Calculate the position where the previewRenderer should attach to.
        var previewRendererCenter = Qt.point(
                    previewRenderer.x + previewRenderer.width / 2,
                    previewRenderer.y + previewRenderer.height / 2)
        var distantRendererCenter = Qt.point(
                    distantRenderer.x + distantRenderer.width / 2,
                    distantRenderer.y + distantRenderer.height / 2)

        if (previewRendererCenter.x >= distantRendererCenter.x) {
            if (previewRendererCenter.y >= distantRendererCenter.y) {
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
            if (previewRendererCenter.y >= distantRendererCenter.y) {
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

            MouseArea {
                anchors.fill: parent

                hoverEnabled: true
                propagateComposedEvents: true

                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onDoubleClicked: function (mouse) {
                    if (mouse.button === Qt.LeftButton)
                        callStackView.toggleFullScreen()
                }

                onClicked: function (mouse) {
                    if (mouse.button === Qt.RightButton)
                        callOverlay.openCallViewContextMenuInPos(mouse.x, mouse.y)
                }

                VideoView {
                    id: distantRenderer

                    anchors.centerIn: parent
                    anchors.fill: parent
                    z: -1

                    visible: !root.isAudioOnly

                    // Update overlays if the internal or visual geometry changes.
                    // Use Qt.callLater to combine the events in the queue since these
                    // signals can be emitted together.
                    property real area: width * height
                    function updateParticipantsLayer() {
                        callOverlay.participantsLayer.update(CallAdapter.getConferencesInfos())
                    }
                    onAreaChanged: Qt.callLater(updateParticipantsLayer)
                    onContentRectChanged: Qt.callLater(updateParticipantsLayer)
                }

                LocalVideo {
                    id: previewRenderer

                    visible: !callOverlay.isAudioOnly && !callOverlay.isConferenceCall && !callOverlay.isVideoMuted && !callOverlay.isPaused &&
                             ((VideoDevices.listSize !== 0 && AvAdapter.currentRenderingDeviceType === Video.DeviceType.CAMERA) || AvAdapter.currentRenderingDeviceType !== Video.DeviceType.CAMERA )

                    rendererId: root.callPreviewId

                    height: width * invAspectRatio
                    width: Math.max(callPageMainRect.width / 5, JamiTheme.minimumPreviewWidth)
                    x: callPageMainRect.width - previewRenderer.width - previewMargin
                    y: previewMarginYTop

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
                        target: CallAdapter

                        function onUpdateOverlay(isPaused, isAudioOnly, isAudioMuted, isVideoMuted,
                                                 isSIP, isConferenceCall, isGrid, previewId) {
                            if (previewId !== "") {
                                if (root.callPreviewId !== previewId)
                                    VideoDevices.stopDevice(root.callPreviewId, true)
                                VideoDevices.startDevice(previewId)
                            } else {
                                VideoDevices.stopDevice(root.callPreviewId, true)
                            }
                            root.callPreviewId = previewId
                            callOverlay.showOnHoldImage(isPaused)
                            root.isAudioOnly = isAudioOnly
                            audioCallPageRectCentralRect.visible = !isPaused && root.isAudioOnly
                            callOverlay.updateUI(isPaused, isAudioOnly,
                                                 isAudioMuted, isVideoMuted,
                                                 isSIP,
                                                 isConferenceCall, isGrid)
                            callOverlay.participantsLayer.update(CallAdapter.getConferencesInfos())
                        }

                        function onShowOnHoldLabel(isPaused) {
                            callOverlay.showOnHoldImage(isPaused)
                            audioCallPageRectCentralRect.visible = !isPaused && root.isAudioOnly
                        }

                        function onRemoteRecordingChanged(label, state) {
                            callOverlay.showRemoteRecording(label, state)
                        }

                        function onEraseRemoteRecording() {
                            callOverlay.resetRemoteRecording()
                        }
                    }

                    Connections {
                        target: MessagesAdapter
                        enabled: root.visible

                        function onNewInteraction(interactionType) {
                            // Ignore call notifications, as we are in the call.
                            if (interactionType !== Interaction.Type.CALL && !inCallMessageWebViewStack.visible)
                                openInCallConversation()
                        }
                    }

                    onChatButtonClicked: {
                        inCallMessageWebViewStack.visible ?
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

                    visible: root.isAudioOnly

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
            }

            color: "transparent"
        }

        StackView {
            id: inCallMessageWebViewStack

            SplitView.preferredHeight: mainColumnLayout.isHorizontal ? root.height : root.height / 3
            SplitView.preferredWidth: mainColumnLayout.isHorizontal ? root.width / 3 : root.width
            SplitView.fillWidth: false

            visible: false

            clip: true
        }
    }
}
