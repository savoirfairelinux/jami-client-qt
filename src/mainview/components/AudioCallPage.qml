/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import QtQml 2.12

import QtQuick.Controls 1.4 as QtQuickOne

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: audioCallPageRect

    property string bestName: "Best Name"
    property string bestId: "Best Id"

    property var linkedWebview: null

    function updateUI(accountId, convUid) {
        contactImage.updateImage(convUid)
        bestName = UtilsAdapter.getBestName(accountId, convUid)

        var id = UtilsAdapter.getBestId(accountId, convUid)
        bestId = (bestName !== id) ? id : ""
    }

    function setLinkedWebview(webViewId) {
        linkedWebview = webViewId
        linkedWebview.needToHideConversationInCall.disconnect(
                    closeInCallConversation)
        linkedWebview.needToHideConversationInCall.connect(
                    closeInCallConversation)
    }

    function closeInCallConversation() {
        if (inAudioCallMessageWebViewStack.visible) {
            linkedWebview.resetMessagingHeaderBackButtonSource(
                        true)
            linkedWebview.setMessagingHeaderButtonsVisible(true)
            inAudioCallMessageWebViewStack.visible = false
            inAudioCallMessageWebViewStack.clear()
        }
    }

    function closeContextMenuAndRelatedWindows() {
        audioCallOverlay.closePotentialContactPicker()
    }

    anchors.fill: parent

    QtQuickOne.SplitView {
        id: mainColumnLayout

        anchors.fill: parent

        orientation: Qt.Vertical

        handleDelegate: Rectangle {
            implicitWidth: audioCallPageRect.width
            implicitHeight: JamiTheme.splitViewHandlePreferredWidth
            color: styleData.pressed ? JamiTheme.pressColor : (styleData.hovered ? JamiTheme.hoverColor : JamiTheme.tabbarBorderColor)
        }

        Rectangle {
            id: audioCallPageMainRect

            Layout.preferredHeight: (audioCallPageRect.height / 3) * 2
            Layout.minimumHeight: audioCallPageRect.height / 2 + 20
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
                        audioCallOverlay.openCallViewContextMenuInPos(mouse.x, mouse.y)
                }

                CallOverlay {
                    id: audioCallOverlay

                    anchors.fill: parent

                    Connections {
                        target: CallAdapter

                        onUpdateTimeText: {
                            audioCallOverlay.timeText = time
                            audioCallOverlay.setRecording(CallAdapter.isRecordingThisCall())
                        }

                        onUpdateOverlay: {
                            audioCallOverlay.showOnHoldImage(isPaused)
                            audioCallPageRectCentralRect.visible = !isPaused
                            audioCallOverlay.updateButtonStatus(isPaused,
                                                                isAudioOnly,
                                                                isAudioMuted,
                                                                isVideoMuted,
                                                                isRecording, isSIP,
                                                                isConferenceCall)
                            audioCallPageRect.bestName = bestName
                        }

                        onShowOnHoldLabel: {
                            audioCallOverlay.showOnHoldImage(isPaused)
                            audioCallPageRectCentralRect.visible = !isPaused
                        }
                    }

                    onOverlayChatButtonClicked: {
                        if (inAudioCallMessageWebViewStack.visible) {
                            linkedWebview.resetMessagingHeaderBackButtonSource(
                                        true)
                            linkedWebview.setMessagingHeaderButtonsVisible(
                                        true)
                            inAudioCallMessageWebViewStack.visible = false
                            inAudioCallMessageWebViewStack.clear()
                        } else {
                            linkedWebview.resetMessagingHeaderBackButtonSource(
                                        false)
                            linkedWebview.setMessagingHeaderButtonsVisible(
                                        false)
                            inAudioCallMessageWebViewStack.visible = true
                            inAudioCallMessageWebViewStack.push(
                                        linkedWebview)
                        }
                    }
                }

                Rectangle {
                    id: audioCallPageRectCentralRect

                    anchors.centerIn: parent

                    width: audioCallPageRect.width
                    height: audioCallPageRegisteredNameText.height
                            + audioCallPageIdText.height + contactImage.height + 10

                    ColumnLayout {
                        id: audioCallPageRectColumnLayout

                        AvatarImage {
                            id: contactImage

                            Layout.alignment: Qt.AlignCenter

                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 100

                            mode: AvatarImage.Mode.FromConvUid
                            showPresenceIndicator: false
                        }

                        Text {
                            id: audioCallPageRegisteredNameText

                            Layout.alignment: Qt.AlignCenter

                            Layout.preferredWidth: audioCallPageRectCentralRect.width
                            Layout.preferredHeight: 50

                            font.pointSize: JamiTheme.textFontSize + 3

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            text: textMetricsAudioCallPageRegisteredNameText.elidedText
                            color: "white"

                            TextMetrics {
                                id: textMetricsAudioCallPageRegisteredNameText
                                font: audioCallPageRegisteredNameText.font
                                text: bestName
                                elideWidth: audioCallPageRectCentralRect.width - 50
                                elide: Qt.ElideMiddle
                            }
                        }

                        Text {
                            id: audioCallPageIdText

                            Layout.alignment: Qt.AlignCenter

                            Layout.preferredWidth: audioCallPageRectCentralRect.width
                            Layout.preferredHeight: 30

                            font.pointSize: JamiTheme.textFontSize

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            text: textMetricsAudioCallPageIdText.elidedText
                            color: "white"

                            TextMetrics {
                                id: textMetricsAudioCallPageIdText
                                font: audioCallPageIdText.font
                                text: bestId
                                elideWidth: audioCallPageRectCentralRect.width - 50
                                elide: Qt.ElideMiddle
                            }
                        }
                    }

                    color: "transparent"
                }
            }
            color: "transparent"
        }

        StackView {
            id: inAudioCallMessageWebViewStack

            Layout.preferredHeight: audioCallPageRect.height / 3
            Layout.fillWidth: true

            visible: false

            clip: true
        }
    }

    color: "black"
}
