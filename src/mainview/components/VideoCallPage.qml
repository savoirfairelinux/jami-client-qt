/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import QtQml 2.12

import QtQuick.Controls 1.4 as QtQuickOne

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: videoCallPageRect

    property string bestName: "Best Name"
    property string bestId: "Best Id"
    property variant clickPos: "1,1"
    property int previewMargin: 15
    property int previewMarginY: previewMargin + 56
    property int previewToX: 0
    property int previewToY: 0

    property var linkedWebview: null

    function updateUI(accountId, convUid) {
        videoCallOverlay.handleParticipantsInfo(CallAdapter.getConferencesInfos())

        bestName = UtilsAdapter.getBestName(accountId, convUid)

        var id = UtilsAdapter.getBestId(accountId, convUid)
        bestId = (bestName !== id) ? id : ""
    }

    function setDistantRendererId(id) {
        distantRenderer.setRendererId(id)
    }

    function setLinkedWebview(webViewId) {
        linkedWebview = webViewId
        linkedWebview.needToHideConversationInCall.disconnect(
                    closeInCallConversation)
        linkedWebview.needToHideConversationInCall.connect(
                    closeInCallConversation)
    }

    function closeInCallConversation() {
        if (inVideoCallMessageWebViewStack.visible) {
            mainColumnLayout.removeItem(inVideoCallMessageWebViewStack)

            linkedWebview.resetMessagingHeaderBackButtonSource(
                        true)
            linkedWebview.setMessagingHeaderButtonsVisible(true)
            inVideoCallMessageWebViewStack.visible = false
            inVideoCallMessageWebViewStack.clear()
        }
    }

    function closeContextMenuAndRelatedWindows() {
        videoCallOverlay.closePotentialContactPicker()
    }

    function handleParticipantsInfo(infos) {
        if (infos.length === 0) {
            bestName = UtilsAdapter.getBestName(AccountAdapter.currentAccountId,
                                                UtilsAdapter.getCurrConvId())
        } else {
            bestName = ""
        }
        videoCallOverlay.handleParticipantsInfo(infos)
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
                    return videoCallPageMainRect.width - previewRenderer.width - previewMargin
                })
                previewToY = Qt.binding(function () {
                    return videoCallPageMainRect.height - previewRenderer.height - previewMarginY
                })
            } else {
                // Top right.
                previewToX = Qt.binding(function () {
                    return videoCallPageMainRect.width - previewRenderer.width - previewMargin
                })
                previewToY = previewMarginY
            }
        } else {
            if (previewRendererCenter.y >= distantRendererCenter.y) {
                // Bottom left.
                previewToX = previewMargin
                previewToY = Qt.binding(function () {
                    return videoCallPageMainRect.height - previewRenderer.height - previewMarginY
                })
            } else {
                // Top left.
                previewToX = previewMargin
                previewToY = previewMarginY
            }
        }
        previewRenderer.state = "geoChanging"
    }

    StackView {
        id: inVideoCallMessageWebViewStack

        Layout.preferredHeight: visible ? videoCallPageRect.height / 3 : 0
        Layout.fillWidth: true

        visible: false

        clip: true
    }

    anchors.fill: parent

    QtQuickOne.SplitView {
        id: mainColumnLayout

        anchors.fill: parent

        orientation: Qt.Vertical

        handleDelegate: Rectangle {
            implicitWidth: videoCallPageRect.width
            implicitHeight: JamiTheme.splitViewHandlePreferredWidth

            visible: inVideoCallMessageWebViewStack.visible
            color: styleData.pressed ? JamiTheme.pressColor :
                                       (styleData.hovered ? JamiTheme.hoverColor :
                                                            JamiTheme.tabbarBorderColor)
        }

        Rectangle {
            id: videoCallPageMainRect

            Layout.minimumHeight: videoCallPageRect.height / 2 + 20
            Layout.fillWidth: true

            MouseArea {
                anchors.fill: parent

                hoverEnabled: true
                propagateComposedEvents: true

                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onDoubleClicked: {
                    if (mouse.button === Qt.LeftButton)
                        callStackView.toggleFullScreen()
                }

                onClicked: {
                    if (mouse.button === Qt.RightButton)
                        videoCallOverlay.openCallViewContextMenuInPos(mouse.x, mouse.y)
                }

                CallOverlay {
                    id: videoCallOverlay

                    anchors.fill: parent

                    Connections {
                        target: CallAdapter

                        onUpdateTimeText: {
                            videoCallOverlay.timeText = time
                            videoCallOverlay.setRecording(CallAdapter.isRecordingThisCall())
                        }

                        onUpdateOverlay: {
                            videoCallOverlay.showOnHoldImage(isPaused)
                            videoCallOverlay.updateButtonStatus(isPaused,
                                                                isAudioOnly,
                                                                isAudioMuted,
                                                                isVideoMuted,
                                                                isRecording, isSIP,
                                                                isConferenceCall)
                            videoCallPageRect.bestName = bestName
                            videoCallOverlay.handleParticipantsInfo(CallAdapter.getConferencesInfos())
                        }

                        onShowOnHoldLabel: {
                            videoCallOverlay.showOnHoldImage(isPaused)
                        }

                        onRemoteRecordingChanged: {
                            videoCallOverlay.showRemoteRecording(label, state)
                        }
                    }

                    onOverlayChatButtonClicked: {
                        if (inVideoCallMessageWebViewStack.visible) {
                            mainColumnLayout.removeItem(inVideoCallMessageWebViewStack)

                            linkedWebview.resetMessagingHeaderBackButtonSource(
                                        true)
                            linkedWebview.setMessagingHeaderButtonsVisible(
                                        true)
                            inVideoCallMessageWebViewStack.visible = false
                            inVideoCallMessageWebViewStack.clear()

                            videoCallPageMainRect.height = Qt.binding(function() {
                                return mainColumnLayout.height
                            })
                        } else {
                            mainColumnLayout.addItem(inVideoCallMessageWebViewStack)

                            linkedWebview.resetMessagingHeaderBackButtonSource(
                                        false)
                            linkedWebview.setMessagingHeaderButtonsVisible(
                                        false)
                            inVideoCallMessageWebViewStack.visible = true
                            inVideoCallMessageWebViewStack.push(
                                        linkedWebview)

                            videoCallPageMainRect.height = videoCallPageRect.height / 2 + 20
                        }
                    }
                }

                DistantRenderer {
                    id: distantRenderer

                    anchors.centerIn: parent
                    z: -1

                    width: videoCallPageMainRect.width
                    height: videoCallPageMainRect.height

                    onOffsetChanged: {
                        videoCallOverlay.handleParticipantsInfo(CallAdapter.getConferencesInfos())
                    }
                }

                VideoCallPreviewRenderer {
                    id: previewRenderer

                    Connections {
                        target: CallAdapter

                        onPreviewVisibilityNeedToChange: {
                            previewRenderer.visible = visible
                        }
                    }

                    Connections {
                        target: AvAdapter

                        onVideoDeviceListChanged: {
                            previewRenderer.visible = !listIsEmpty
                        }
                    }

                    width: Math.max(videoCallPageMainRect.width / 5, JamiTheme.minimumPreviewWidth)
                    x: videoCallPageMainRect.width - previewRenderer.width - previewMargin
                    y: videoCallPageMainRect.height - previewRenderer.height - previewMargin - 56 // Avoid overlay
                    z: -1

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

                        onPressed: {
                            clickPos = Qt.point(mouse.x, mouse.y)
                        }

                        onReleased: {
                            previewRenderer.state = ""
                            previewMagneticSnap()
                        }

                        onPositionChanged: {
                            // Calculate mouse position relative change.
                            var delta = Qt.point(mouse.x - clickPos.x,
                                                mouse.y - clickPos.y)
                            var deltaW = previewRenderer.x + delta.x + previewRenderer.width
                            var deltaH = previewRenderer.y + delta.y + previewRenderer.height


                            // Check if the previewRenderer exceeds the border of videoCallPageMainRect.
                            if (deltaW < videoCallPageMainRect.width
                                    && previewRenderer.x + delta.x > 1)
                                previewRenderer.x += delta.x
                            if (deltaH < videoCallPageMainRect.height
                                    && previewRenderer.y + delta.y > 1)
                                previewRenderer.y += delta.y
                        }
                    }

                    onWidthChanged: {
                        previewRenderer.height = previewRenderer.width * previewImageScalingFactor
                    }
                    onPreviewImageScalingFactorChanged: {
                        previewRenderer.height = previewRenderer.width * previewImageScalingFactor
                    }
                }
            }

            color: "transparent"
        }
    }

    onBestNameChanged: {
        ContactAdapter.setCalleeDisplayName(bestName)
    }

    color: "black"
}
