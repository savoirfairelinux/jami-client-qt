/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Universal 2.14
import QtQml 2.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../js/contactpickercreation.js" as ContactPickerCreation
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

import "../../commoncomponents"

Item {
    id: root

    property alias participantsLayer: __participantsLayer
    property string timeText: "00:00"
    property string remoteRecordingLabel: ""
    property bool isVideoMuted: true
    property bool isAudioOnly: false
    property string bestName: ""

    signal overlayChatButtonClicked

    onVisibleChanged: if (!visible) callViewContextMenu.close()

    anchors.fill: parent

    ParticipantsLayer {
        id: __participantsLayer
        anchors.fill: parent
    }

    function setRecording(localIsRecording) {
        callViewContextMenu.localIsRecording = localIsRecording
        recordingRect.visible = localIsRecording
                || callViewContextMenu.peerIsRecording
    }

    function updateButtonStatus(isPaused, isAudioOnly, isAudioMuted, isVideoMuted,
                                isRecording, isSIP, isConferenceCall) {
        root.isVideoMuted = isVideoMuted
        callViewContextMenu.isSIP = isSIP
        callViewContextMenu.isPaused = isPaused
        callViewContextMenu.isAudioOnly = isAudioOnly
        callViewContextMenu.localIsRecording = isRecording
        recordingRect.visible = isRecording
        callOverlayButtonGroup.setButtonStatus(isPaused, isAudioOnly,
                                               isAudioMuted, isVideoMuted,
                                               isSIP, isConferenceCall)
    }

    function updateMenu() {
        callOverlayButtonGroup.updateMenu()
    }

    function showOnHoldImage(visible) {
        onHoldImage.visible = visible
    }

    function closePotentialContactPicker() {
        ContactPickerCreation.closeContactPicker()
    }

    function closePotentialPluginHandlerPicker() {
        PluginHandlerPickerCreation.closePluginHandlerPicker()
    }


    // x, y position does not need to be translated
    // since they all fill the call page
    function openCallViewContextMenuInPos(x, y) {
        callViewContextMenu.x = x
        callViewContextMenu.y = y
        callViewContextMenu.openMenu()
    }

    function showRemoteRecording(peers, state) {
        var label = ""
        var i = 0
        if (state) {
            for (var p in peers) {
                label += peers[p]
                if (i !== (peers.length - 1))
                    label += ", "
                i += 1
            }
            label += " " + ((peers.length > 1)? JamiStrings.areRecording
                                              : JamiStrings.isRecording)
        }

        remoteRecordingLabel = state? label : JamiStrings.peerStoppedRecording
        callViewContextMenu.peerIsRecording = state
        recordingRect.visible = callViewContextMenu.localIsRecording
                || callViewContextMenu.peerIsRecording
        callOverlayRectMouseArea.entered()
    }

    SipInputPanel {
        id: sipInputPanel

        x: root.width / 2 - sipInputPanel.width / 2
        y: root.height / 2 - sipInputPanel.height / 2
    }

    // Timer to decide when overlay fade out.
    Timer {
        id: callOverlayTimer
        interval: 5000
        onTriggered: {
            if (overlayUpperPartRect.state !== 'freezed') {
                overlayUpperPartRect.state = 'freezed'
                resetLabelsTimer.restart()
            }
            if (callOverlayButtonGroup.state !== 'freezed') {
                callOverlayButtonGroup.state = 'freezed'
                resetLabelsTimer.restart()
            }
        }
    }

    // Timer to reset recording label and call duration time
    Timer {
        id: resetLabelsTimer

        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: {
            timeText = CallAdapter.getCallDurationTime(LRCInstance.currentAccountId,
                                                       LRCInstance.selectedConvUid)
            if (callOverlayButtonGroup.state === 'freezed'
                    && !callViewContextMenu.peerIsRecording)
                remoteRecordingLabel = ""
        }
    }

    Rectangle {
        id: overlayUpperPartRect

        anchors.top: root.top

        width: root.width
        height: 50
        opacity: 0

        RowLayout {
            id: overlayUpperPartRectRowLayout

            anchors.fill: parent

            Text {
                id: jamiBestNameText

                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.preferredWidth: overlayUpperPartRect.width / 3
                Layout.preferredHeight: 50
                leftPadding: 16

                font.pointSize: JamiTheme.textFontSize

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                text: textMetricsjamiBestNameText.elidedText
                color: "white"

                TextMetrics {
                    id: textMetricsjamiBestNameText
                    font: jamiBestNameText.font
                    text: {
                        if (!root.isAudioOnly) {
                            if (remoteRecordingLabel === "") {
                                return root.bestName
                            } else {
                                return remoteRecordingLabel
                            }
                        }
                        return ""
                    }
                    elideWidth: overlayUpperPartRect.width / 3
                    elide: Qt.ElideRight
                }
            }

            Text {
                id: callTimerText
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.preferredWidth: 64
                Layout.minimumWidth: 64
                Layout.preferredHeight: 48
                Layout.rightMargin: recordingRect.visible?
                                        0 : JamiTheme.preferredMarginSize
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: textMetricscallTimerText.elidedText
                color: "white"
                TextMetrics {
                    id: textMetricscallTimerText
                    font: callTimerText.font
                    text: timeText
                    elideWidth: overlayUpperPartRect.width / 4
                    elide: Qt.ElideRight
                }
            }

            Rectangle {
                id: recordingRect
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.rightMargin: JamiTheme.preferredMarginSize
                height: 16
                width: 16
                radius: height / 2
                color: "red"

                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: true
                    ColorAnimation { from: "red"; to: "transparent";  duration: 500 }
                    ColorAnimation { from: "transparent"; to: "red"; duration: 500 }
                }
            }
        }

        color: "transparent"


        // Rect states: "entered" state should make overlay fade in,
        //              "freezed" state should make overlay fade out.
        // Combine with PropertyAnimation of opacity.
        states: [
            State {
                name: "entered"
                PropertyChanges {
                    target: overlayUpperPartRect
                    opacity: 1
                }
            },
            State {
                name: "freezed"
                PropertyChanges {
                    target: overlayUpperPartRect
                    opacity: 0
                }
            }
        ]

        transitions: Transition {
            PropertyAnimation {
                target: overlayUpperPartRect
                property: "opacity"
                duration: 1000
            }
        }
    }

    ResponsiveImage {
        id: onHoldImage

        anchors.verticalCenter: root.verticalCenter
        anchors.horizontalCenter: root.horizontalCenter

        width: 200
        height: 200

        visible: false

        source: "qrc:/images/icons/ic_pause_white_100px.svg"
    }

    CallOverlayButtonGroup {
        id: callOverlayButtonGroup

        anchors.bottom: root.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: root.horizontalCenter

        height: 56
        width: root.width
        opacity: 0

        onChatButtonClicked: {
            root.overlayChatButtonClicked()
        }

        onAddToConferenceButtonClicked: {
            // Create contact picker - conference.
            ContactPickerCreation.createContactPickerObjects(
                        ContactList.CONFERENCE,
                        root)
            ContactPickerCreation.openContactPicker()
        }

        states: [
            State {
                name: "entered"
                PropertyChanges {
                    target: callOverlayButtonGroup
                    opacity: 1
                }
            },
            State {
                name: "freezed"
                PropertyChanges {
                    target: callOverlayButtonGroup
                    opacity: 0
                }
            }
        ]

        transitions: Transition {
            PropertyAnimation {
                target: callOverlayButtonGroup
                property: "opacity"
                duration: 1000
            }
        }
    }

    // MouseAreas to make sure that overlay states are correctly set.
    MouseArea {
        id: callOverlayButtonGroupLeftSideMouseArea

        anchors.bottom: root.bottom
        anchors.left: root.left

        width: root.width / 6
        height: 60

        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.NoButton

        onEntered: {
            callOverlayRectMouseArea.entered()
        }

        onMouseXChanged: {
            callOverlayRectMouseArea.entered()
        }
    }

    MouseArea {
        id: callOverlayButtonGroupRightSideMouseArea

        anchors.bottom: root.bottom
        anchors.right: root.right

        width: root.width / 6
        height: 60

        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.NoButton

        onEntered: {
            callOverlayRectMouseArea.entered()
        }

        onMouseXChanged: {
            callOverlayRectMouseArea.entered()
        }
    }

    MouseArea {
        id: callOverlayRectMouseArea

        anchors.top: root.top

        width: root.width
        height: root.height

        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton

        function resetStates() {
            if (overlayUpperPartRect.state !== 'entered') {
                overlayUpperPartRect.state = 'entered'
            }
            if (callOverlayButtonGroup.state !== 'entered') {
                callOverlayButtonGroup.state = 'entered'
            }
            callOverlayTimer.restart()
        }

        onReleased: {
            resetStates()
        }
        onEntered: {
            resetStates()
        }

        onMouseXChanged: {
            resetStates()
        }
    }

    CallViewContextMenu {
        id: callViewContextMenu

        onTransferCallButtonClicked: {
            // Create contact picker - sip transfer.
            ContactPickerCreation.createContactPickerObjects(
                        ContactList.TRANSFER,
                        root)
            ContactPickerCreation.openContactPicker()
        }

        onPluginItemClicked: {
            // Create plugin handler picker - PLUGINS
            PluginHandlerPickerCreation.createPluginHandlerPickerObjects(root, true)
            PluginHandlerPickerCreation.openPluginHandlerPicker()
        }
    }
}
