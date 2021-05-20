/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../js/selectscreenwindowcreation.js" as SelectScreenWindowCreation
import "../js/contactpickercreation.js" as ContactPickerCreation
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Control {
    id: root

    property alias overflowOpen: overflowButton.popup.visible
    property real itemSpacing: 2
    property bool localIsRecording: false

    signal chatClicked
    signal addToConferenceClicked
    signal transferClicked // TODO: this
    signal shareScreenClicked
    signal shareScreenAreaClicked // TODO: this
    signal pluginsClicked

    Component {
        id: buttonDelegate

        CallButtonDelegate {
            width: root.height
            height: width
        }
    }

    // test
    Timer {
        running: true
        repeat: false
        interval: 15000
        onTriggered: CallOverlayModel.setBadgeCount(2, 3)
    }

    Action {
        id: dummyControlAction
        onTriggered: print("dummyControlAction triggered")
    }
    Action {
        id: dummyMenuAction
        onTriggered: print("dummyMenuAction triggered")
    }

    property list<Action> menuActions: [
        Action {
            id: audioInputMenuAction
            onTriggered: print("audioInputMenuAction triggered")
            text: JamiStrings.selectAudioInputDevice
            property var listModel: AudioDeviceModel {
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Record
            }
            function accept(index) {
                AVModel.setInputDevice(listModel.data(
                                           listModel.index(index, 0),
                                           AudioDeviceModel.RawDeviceName))
                AvAdapter.startAudioMeter(false)
            }
        },
        Action {
            id: audioOutputMenuAction
            onTriggered: print("audioOutputMenuAction triggered")
            text: JamiStrings.selectAudioOutputDevice
            property var listModel: AudioDeviceModel {
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Playback
            }
            function accept(index) {
                AVModel.setOutputDevice(listModel.data(
                                           listModel.index(index, 0),
                                           AudioDeviceModel.RawDeviceName))
                AvAdapter.startAudioMeter(false)
            }
        },
        Action {
            id: videoInputMenuAction
            onTriggered: print("videoInputMenuAction triggered")
            text: JamiStrings.selectVideoDevice
            property var listModel: VideoInputDeviceModel {
                lrcInstance: LRCInstance
            }
            function accept(index) {
                if(listModel.deviceCount() < 1)
                    return
                try {
                    var deviceId = listModel.data(
                                listModel.index(index, 0),
                                VideoInputDeviceModel.DeviceId)
                    var deviceName = listModel.data(
                                listModel.index(index, 0),
                                VideoInputDeviceModel.DeviceName)
                    if(deviceId.length === 0) {
                        console.warn("Couldn't find device: " + deviceName)
                        return
                    }
                    if (AVModel.getCurrentVideoCaptureDevice() !== deviceId) {
                        AVModel.setCurrentVideoCaptureDevice(deviceId)
                        AVModel.setDefaultDevice(deviceId)
                    }
                    AvAdapter.selectVideoInputDeviceById(deviceId)
                } catch(err){ console.warn(err.message) }
            }
        }
    ]

    property list<Action> primaryActions: [
        Action {
            id: muteAudioAction
            onTriggered: CallAdapter.muteThisCallToggle()
            checkable: true
            icon.source: checked ?
                             "qrc:/images/icons/mic_off-24px.svg" :
                             "qrc:/images/icons/mic-24px.svg"
            icon.color: checked ? "red" : "white"
            text: !checked ? JamiStrings.mute : JamiStrings.unmute
        },
        Action {
            id: hangupAction
            onTriggered: CallAdapter.hangUpThisCall()
            icon.source: "qrc:/images/icons/ic_call_end_white_24px.svg"
            icon.color: "white"
            text: JamiStrings.hangup
            property bool hasBg: true
        },
        Action {
            id: muteVideoAction
            onTriggered: CallAdapter.videoPauseThisCallToggle()
            checkable: true
            icon.source: checked ?
                             "qrc:/images/icons/videocam_off-24px.svg" :
                             "qrc:/images/icons/videocam-24px.svg"
            icon.color: checked ? "red" : "white"
            text: !checked ? JamiStrings.pauseVideo : JamiStrings.resumeVideo
        }
    ]

    property list<Action> secondaryActions: [
        Action {
            id: audioOutputAction
            onTriggered: print("audioOutputAction triggered")
            checkable: true
            icon.source: checked ?
                             "qrc:/images/icons/spk_none_black_24dp.svg" :
                             "qrc:/images/icons/spk_black_24dp.svg"
            icon.color: checked ? "red" : "white"
            text: !checked ? JamiStrings.mute : JamiStrings.unmute
        },
        Action {
            id: addPersonAction
            onTriggered: root.addToConferenceClicked()
            icon.source: "qrc:/images/icons/add_people_black_24dp.svg"
            icon.color: "white"
            text: JamiStrings.addParticipants
        },
        Action {
            id: chatAction
            onTriggered: root.chatClicked()
            icon.source: "qrc:/images/icons/chat_black_24dp.svg"
            icon.color: "white"
            text: JamiStrings.chat
        },
        Action {
            id: shareAction
            onTriggered: root.shareScreenClicked()
            icon.source: "qrc:/images/icons/share_screen_black_24dp.svg"
            icon.color: "white"
            text: JamiStrings.shareScreen
        },
        Action {
            id: recordAction
            onTriggered: CallAdapter.recordThisCallToggle()
            checkable: true
            icon.source: "qrc:/images/icons/record_black_24dp.svg"
            icon.color: checked ? "white" : "red"
            text: !checked ? JamiStrings.startRec : JamiStrings.stopRec
        },
        Action {
            id: pluginsAction
            onTriggered: root.pluginsClicked()
            icon.source: "qrc:/images/icons/plugins-24px.svg"
            icon.color: "white"
            text: JamiStrings.viewPlugin
            enabled: UtilsAdapter.checkShowPluginsButton(true)
        }
    ]

    property var overflowItemCount
    Component.onCompleted: reset()
    function reset() {
        // TODO: clear models
        CallOverlayModel.addPrimaryControl({"ItemAction": muteAudioAction,
                                            "MenuAction": audioInputMenuAction})
        CallOverlayModel.addPrimaryControl({"ItemAction": hangupAction})
        CallOverlayModel.addPrimaryControl({"ItemAction": muteVideoAction,
                                            "MenuAction": videoInputMenuAction})

        CallOverlayModel.addSecondaryControl({"ItemAction": audioOutputAction,
                                              "MenuAction": audioOutputMenuAction})
        CallOverlayModel.addSecondaryControl({"ItemAction": addPersonAction})
        CallOverlayModel.addSecondaryControl({"ItemAction": chatAction})
        CallOverlayModel.addSecondaryControl({"ItemAction": shareAction})
        CallOverlayModel.addSecondaryControl({"ItemAction": recordAction})
        if (UtilsAdapter.checkShowPluginsButton(true))
            CallOverlayModel.addSecondaryControl({"ItemAction": pluginsAction})

        overflowItemCount = CallOverlayModel.secondaryModel().rowCount()
    }

    Item {
        id: centralControls
        anchors.centerIn: parent
        width: childrenRect.width
        height: root.height

        RowLayout {
            spacing: 0

            ListView {
                property bool centeredGroup: true

                orientation: ListView.Horizontal
                implicitWidth: contentWidth
                implicitHeight: contentHeight

                model: CallOverlayModel.primaryModel()
                delegate: buttonDelegate
            }
        }
    }
    Item {
        id: overflowRect
        property real remainingSpace: (root.width - centralControls.width) / 2
        anchors.right: parent.right
        width: childrenRect.width
        height: root.height

        RowLayout {
            spacing: itemSpacing

            ListView {
                id: overflowItemListView

                orientation: ListView.Horizontal
                implicitWidth: contentWidth
                implicitHeight: overflowRect.height

                spacing: itemSpacing

                property int overflowIndex: {
                    var maxItems = Math.floor((overflowRect.remainingSpace - 24) / root.height) - 1
                    return Math.min(overflowItemCount, maxItems)
                }
                property int nOverflowItems: overflowItemCount - overflowIndex
                onNOverflowItemsChanged: {
                    var diff = overflowItemListView.count - nOverflowItems
                    var effectiveOverflowIndex = overflowIndex
                    if (effectiveOverflowIndex === overflowItemCount - 1)
                        effectiveOverflowIndex += diff

                    CallOverlayModel.overflowIndex = effectiveOverflowIndex
                }

                model: CallOverlayModel.overflowModel()
                delegate: buttonDelegate
            }
            ComboBox {
                id: overflowButton

                visible: CallOverlayModel.overflowIndex < overflowItemCount
                width: root.height
                height: width

                model: CallOverlayModel.overflowHiddenModel()

                delegate: buttonDelegate

                indicator: null

                contentItem: Text {
                    text: "⋮"
                    color: "white"
                    font.pointSize: 18
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                background: Rectangle {
                    implicitWidth: root.height
                    implicitHeight: implicitWidth
                    color: overflowButton.down ?
                               "#80aaaaaa" :
                               overflowButton.hovered ?
                                   "#80777777" :
                                   "#80444444"
                }

                Item {
                    implicitHeight: children[0].contentHeight
                    width: overflowButton.width
                    anchors.bottom: parent.top
                    anchors.bottomMargin: itemSpacing
                    visible: !overflowButton.popup.visible
                    ListView {
                        spacing: itemSpacing
                        anchors.fill: parent
                        model: CallOverlayModel.overflowVisibleModel()
                        delegate: buttonDelegate
                        ScrollIndicator.vertical: ScrollIndicator {}

                        add: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 80 }
                            NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: 80 }
                        }
                    }
                }

                popup: Popup {
                    y: overflowButton.height + itemSpacing
                    width: overflowButton.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 0

                    contentItem: ListView {
                        id: overflowListView
                        spacing: itemSpacing
                        implicitHeight: contentHeight
                        model: overflowButton.popup.visible ?
                                   overflowButton.delegateModel :
                                   null

                        ScrollIndicator.vertical: ScrollIndicator {}

                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }
    }
}
