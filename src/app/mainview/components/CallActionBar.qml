/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"

Control {
    id: root
    enum ActionPopupMode {
        MediaDevice,
        ListElement,
        LayoutOption
    }

    property bool barHovered: false
    property real itemSpacing: 2
    property list<Action> menuActions: [
        Action {
            id: audioInputMenuAction
            property var listModel: AudioDeviceModel {
                id: audioInputDeviceListModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Record
            }

            text: JamiStrings.selectAudioInputDevice

            function accept(index) {
                AvAdapter.stopAudioMeter();
                AVModel.setInputDevice(index);
                AvAdapter.startAudioMeter();
            }

            Component.onCompleted: enabled = audioInputDeviceListModel.rowCount()
        },
        Action {
            id: audioOutputMenuAction
            property var listModel: AudioDeviceModel {
                id: audioOutputDeviceListModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Playback
            }

            text: JamiStrings.selectAudioOutputDevice

            function accept(index) {
                AvAdapter.stopAudioMeter();
                AVModel.setOutputDevice(index);
                AvAdapter.startAudioMeter();
            }

            Component.onCompleted: enabled = audioOutputDeviceListModel.rowCount()
        },
        Action {
            id: shareMenuAction
            property var listModel: ListModel {
                id: shareModel
            }
            property int popupMode: CallActionBar.ActionPopupMode.ListElement

            text: JamiStrings.selectShareMethod

            function accept(index) {
                switch (shareModel.get(index).Name) {
                case JamiStrings.shareScreen:
                    shareScreenClicked();
                    break;
                case JamiStrings.shareWindow:
                    shareWindowClicked();
                    break;
                case JamiStrings.shareScreenArea:
                    shareScreenAreaClicked();
                    break;
                case JamiStrings.shareFile:
                    shareFileClicked();
                    break;
                }
            }

            onTriggered: {
                shareModel.clear();
                shareModel.append({
                        "Name": JamiStrings.shareScreen,
                        "IconSource": JamiResources.laptop_black_24dp_svg
                    });
                if (Qt.platform.os.toString() !== "osx") {
                    shareModel.append({
                            "Name": JamiStrings.shareWindow,
                            "IconSource": JamiResources.window_black_24dp_svg
                        });
                }
                if (Qt.platform.os.toString() !== "windows") {
                    // temporarily disable for windows
                    shareModel.append({
                            "Name": JamiStrings.shareScreenArea,
                            "IconSource": JamiResources.share_area_black_24dp_svg
                        });
                }
                shareModel.append({
                        "Name": JamiStrings.shareFile,
                        "IconSource": JamiResources.file_black_24dp_svg
                    });
            }
        },
        Action {
            id: layoutMenuAction
            property var listModel: ListModel {
                id: layoutModel
            }
            property int popupMode: CallActionBar.ActionPopupMode.LayoutOption

            text: JamiStrings.layoutSettings

            function accept(index) {
                switch (layoutModel.get(index).Name) {
                case JamiStrings.viewFullScreen:
                    root.fullScreenClicked();
                    layoutModel.get(index).ActiveSetting = layoutManager.isCallFullscreen;
                    break;
                case JamiStrings.mosaic:
                    if (!CurrentCall.isGrid)
                        CallAdapter.showGridConferenceLayout();
                    break;
                case JamiStrings.participantsSide:
                    if (!UtilsAdapter.getAppValue(Settings.ParticipantsSide)) {
                        UtilsAdapter.setAppValue(Settings.ParticipantsSide, true);
                        participantsSide = true;
                    }
                    break;
                case JamiStrings.participantsTop:
                    if (UtilsAdapter.getAppValue(Settings.ParticipantsSide)) {
                        UtilsAdapter.setAppValue(Settings.ParticipantsSide, false);
                        participantsSide = false;
                    }
                    break;
                case JamiStrings.hideSelf:
                    UtilsAdapter.setAppValue(Settings.HideSelf, !layoutModel.get(index).ActiveSetting);
                    CurrentCall.hideSelf = UtilsAdapter.getAppValue(Settings.HideSelf);
                    break;
                case JamiStrings.hideSpectators:
                    UtilsAdapter.setAppValue(Settings.HideSpectators, !layoutModel.get(index).ActiveSetting);
                    CurrentCall.hideSpectators = UtilsAdapter.getAppValue(Settings.HideSpectators);
                    break;
                }
            }

            onTriggered: {
                layoutModel.clear();
                if (CurrentCall.isConference) {
                    layoutModel.append({
                            "Name": JamiStrings.mosaic,
                            "IconSource": JamiResources.mosaic_black_24dp_svg,
                            "ActiveSetting": CurrentCall.isGrid,
                            "TopMargin": true,
                            "BottomMargin": true,
                            "SectionEnd": true
                        });
                    var onTheSide = UtilsAdapter.getAppValue(Settings.ParticipantsSide);
                    layoutModel.append({
                            "Name": JamiStrings.participantsTop,
                            "IconSource": JamiResources.onthetop_black_24dp_svg,
                            "ActiveSetting": !onTheSide,
                            "TopMargin": true,
                            "BottomMargin": false,
                            "SectionEnd": false
                        });
                    layoutModel.append({
                            "Name": JamiStrings.participantsSide,
                            "IconSource": JamiResources.ontheside_black_24dp_svg,
                            "ActiveSetting": onTheSide,
                            "TopMargin": false,
                            "BottomMargin": true,
                            "SectionEnd": true
                        });
                    layoutModel.append({
                            "Name": JamiStrings.hideSelf,
                            "IconSource": JamiResources.hidemyself_black_24dp_svg,
                            "ActiveSetting": UtilsAdapter.getAppValue(Settings.HideSelf),
                            "TopMargin": true,
                            "BottomMargin": false,
                            "SectionEnd": false
                        });
                }
                layoutModel.append({
                        "Name": JamiStrings.viewFullScreen,
                        "IconSource": JamiResources.open_in_full_24dp_svg,
                        "ActiveSetting": layoutManager.isCallFullscreen,
                        "TopMargin": true,
                        "BottomMargin": true,
                        "SectionEnd": CurrentCall.isConference
                    });
                if (CurrentCall.isConference) {
                    layoutModel.append({
                            "Name": JamiStrings.hideSpectators,
                            "IconSource": JamiResources.videocam_off_24dp_svg,
                            "ActiveSetting": UtilsAdapter.getAppValue(Settings.HideSpectators),
                            "TopMargin": true,
                            "BottomMargin": true
                        });
                }
            }
        },
        Action {
            id: videoInputMenuAction
            property var listModel: VideoDevices.deviceSourceModel

            enabled: VideoDevices.listSize !== 0
            text: JamiStrings.selectVideoDevice

            function accept(index) {
                VideoDevices.setDefaultDevice(index);
            }
        }
    ]
    property var overflowItemCount
    property alias overflowOpen: overflowButton.popup.visible
    property real parentHeight
    property list<Action> primaryActions: [
        Action {
            id: muteAudioAction
            property var menuAction: audioInputMenuAction

            checkable: true
            checked: CurrentCall.isAudioMuted
            icon.color: checked ? "red" : "white"
            icon.source: checked ? JamiResources.micro_off_black_24dp_svg : JamiResources.micro_black_24dp_svg
            text: !checked ? JamiStrings.mute : JamiStrings.unmute

            onTriggered: {
                var muteState = CallAdapter.getMuteState(CurrentAccount.uri);
                var modMuted = muteState === CallAdapter.MODERATOR_MUTED || muteState === CallAdapter.BOTH_MUTED;
                if (muteAudioAction.checked && modMuted) {
                    muteAlertActive = true;
                    muteAlertMessage = JamiStrings.participantModIsStillMuted;
                }
                CallAdapter.muteAudioToggle();
            }
        },
        Action {
            id: hangupAction
            property bool hasBg: true

            icon.color: "white"
            icon.source: JamiResources.ic_call_end_white_24dp_svg
            text: JamiStrings.endCall

            onTriggered: CallAdapter.hangUpThisCall()
        },
        Action {
            id: muteVideoAction
            property var menuAction: videoInputMenuAction

            checkable: true
            checked: !CurrentCall.isCapturing
            icon.color: checked ? "red" : "white"
            icon.source: checked ? JamiResources.videocam_off_24dp_svg : JamiResources.videocam_24dp_svg
            text: !checked ? JamiStrings.muteCamera : JamiStrings.unmuteCamera

            onTriggered: CallAdapter.muteCameraToggle()
        }
    ]
    property list<Action> secondaryActions: [
        Action {
            id: audioOutputAction
            property var menuAction: audioOutputMenuAction
            // temp hack for missing back-end, just open device selection
            property bool openPopupWhenClicked: true

            checkable: !openPopupWhenClicked
            icon.color: "white"
            icon.source: JamiResources.spk_black_24dp_svg
            text: JamiStrings.selectAudioOutputDevice
        },
        Action {
            id: addPersonAction
            icon.color: "white"
            icon.source: JamiResources.add_people_black_24dp_svg
            text: JamiStrings.addParticipants

            onTriggered: root.addToConferenceClicked()
        },
        Action {
            id: chatAction
            icon.color: "white"
            icon.source: JamiResources.chat_black_24dp_svg
            text: JamiStrings.chat

            onTriggered: root.chatClicked()
        },
        Action {
            id: resumePauseCallAction
            icon.color: "white"
            icon.source: CurrentCall.isPaused ? JamiResources.play_circle_outline_24dp_svg : JamiResources.pause_circle_outline_24dp_svg
            text: CurrentCall.isPaused ? JamiStrings.resumeCall : JamiStrings.pauseCall

            onTriggered: root.resumePauseCallClicked()
        },
        Action {
            id: inputPanelSIPAction
            icon.color: "white"
            icon.source: JamiResources.ic_keypad_svg
            text: JamiStrings.sipInputPanel

            onTriggered: root.showInputPanelClicked()
        },
        Action {
            id: callTransferAction
            icon.color: "white"
            icon.source: JamiResources.phone_forwarded_24dp_svg
            text: JamiStrings.transferCall

            onTriggered: root.transferClicked()
        },
        Action {
            id: shareAction
            property var menuAction: shareMenuAction
            property real size: 34

            icon.color: CurrentCall.isSharing ? "red" : "white"
            icon.source: CurrentCall.isSharing ? JamiResources.share_stop_black_24dp_svg : JamiResources.share_screen_black_24dp_svg
            text: CurrentCall.isSharing ? JamiStrings.stopSharing : JamiStrings.shareScreen

            onTriggered: {
                if (CurrentCall.isSharing)
                    root.stopSharingClicked();
                else
                    root.shareScreenClicked();
            }
        },
        Action {
            id: raiseHandAction
            property real size: 34

            checkable: true
            checked: CurrentCall.isHandRaised
            icon.color: checked ? JamiTheme.raiseHandColor : "white"
            icon.source: JamiResources.hand_black_24dp_svg
            text: checked ? JamiStrings.lowerHand : JamiStrings.raiseHand

            onTriggered: CallAdapter.raiseHand("", "", !CallAdapter.isHandRaised())
        },
        Action {
            id: layoutAction
            property var menuAction: layoutMenuAction
            property real size: 28

            checkable: true
            icon.color: "white"
            icon.source: JamiResources.mosaic_black_24dp_svg
            text: JamiStrings.layoutSettings

            onTriggered: {
                if (!CurrentCall.isGrid)
                    CallAdapter.showGridConferenceLayout();
            }
        },
        Action {
            id: recordAction
            property bool blinksWhenChecked: true
            property real size: 28

            checkable: true
            checked: CurrentCall.isRecordingLocally
            icon.color: checked ? "red" : "white"
            icon.source: JamiResources.record_black_24dp_svg
            text: !checked ? JamiStrings.startRec : JamiStrings.stopRec

            onCheckedChanged: function (checked) {
                CallOverlayModel.setUrgentCount(recordAction, checked ? -1 : 0);
            }
            onTriggered: root.recordCallClicked()
        },
        Action {
            id: pluginsAction
            enabled: PluginAdapter.isEnabled && PluginAdapter.callMediaHandlersListCount
            icon.color: "white"
            icon.source: JamiResources.plugins_24dp_svg
            text: JamiStrings.viewPlugin

            onTriggered: root.pluginsClicked()
        },
        Action {
            id: swarmDetailsAction
            enabled: {
                if (LRCInstance.currentAccountType === Profile.Type.SIP)
                    return true;
                if (!CurrentConversation.isTemporary && !CurrentConversation.isSwarm)
                    return false;
                if (CurrentConversation.isRequest || CurrentConversation.needsSyncing)
                    return false;
                return true;
            }
            icon.color: "white"
            icon.source: JamiResources.swarm_details_panel_svg
            text: JamiStrings.details

            onTriggered: root.swarmDetailsClicked()
        }
    ]
    property bool subMenuOpen: false

    signal addToConferenceClicked
    signal chatClicked
    signal fullScreenClicked
    signal pluginsClicked
    signal recordCallClicked
    function reset() {
        CallOverlayModel.clearControls();

        // centered controls
        CallOverlayModel.addPrimaryControl(muteAudioAction);
        CallOverlayModel.addPrimaryControl(hangupAction);
        if (CurrentAccount.videoEnabled_Video)
            CallOverlayModel.addPrimaryControl(muteVideoAction);

        // overflow controls
        CallOverlayModel.addSecondaryControl(audioOutputAction);
        if (CurrentCall.isConference) {
            CallOverlayModel.addSecondaryControl(raiseHandAction);
        }
        if (CurrentCall.isModerator && !CurrentCall.isSIP)
            CallOverlayModel.addSecondaryControl(addPersonAction);
        if (CurrentCall.isSIP) {
            CallOverlayModel.addSecondaryControl(resumePauseCallAction);
            CallOverlayModel.addSecondaryControl(inputPanelSIPAction);
            CallOverlayModel.addSecondaryControl(callTransferAction);
        }
        CallOverlayModel.addSecondaryControl(chatAction);
        if (CurrentAccount.videoEnabled_Video && !CurrentCall.isSIP)
            CallOverlayModel.addSecondaryControl(shareAction);
        CallOverlayModel.addSecondaryControl(layoutAction);
        CallOverlayModel.addSecondaryControl(recordAction);
        if (pluginsAction.enabled)
            CallOverlayModel.addSecondaryControl(pluginsAction);
        if (swarmDetailsAction.enabled)
            CallOverlayModel.addSecondaryControl(swarmDetailsAction);
        overflowItemCount = CallOverlayModel.secondaryModel().rowCount();
    }
    signal resumePauseCallClicked
    signal shareFileClicked
    signal shareScreenAreaClicked
    signal shareScreenClicked
    signal shareWindowClicked
    signal showInputPanelClicked
    signal stopSharingClicked
    signal swarmDetailsClicked
    signal transferClicked

    Component {
        id: buttonDelegate
        CallButtonDelegate {
            barWidth: root.width
            height: width
            width: root.height

            onHoveredChanged: root.barHovered = hovered
            onSubMenuVisibleChanged: subMenuOpen = subMenuVisible
        }
    }
    Connections {
        target: AvAdapter

        function onAudioDeviceListChanged(inputs, outputs) {
            audioInputDeviceListModel.reset();
            audioInputMenuAction.enabled = inputs;
            audioOutputDeviceListModel.reset();
            audioOutputMenuAction.enabled = outputs;
        }
    }
    Connections {
        target: CurrentCall

        function onIsActiveChanged() {
            if (CurrentCall.isActive)
                reset();
        }
        function onIsAudioMutedChanged() {
            Qt.callLater(reset);
        }
        function onIsAudioOnlyChanged() {
            Qt.callLater(reset);
        }
        function onIsConferenceChanged() {
            Qt.callLater(reset);
        }
        function onIsHandRaisedChanged() {
            Qt.callLater(reset);
        }
        function onIsModeratorChanged() {
            Qt.callLater(reset);
        }
        function onIsRecordingLocallyChanged() {
            Qt.callLater(reset);
        }
        function onIsSIPChanged() {
            Qt.callLater(reset);
        }
        function onIsVideoMutedChanged() {
            Qt.callLater(reset);
        }
    }
    Connections {
        target: CurrentAccount

        function onVideoEnabledVideoChanged() {
            reset();
        }
    }
    Item {
        id: centralControls
        anchors.centerIn: parent
        height: root.height
        width: childrenRect.width

        RowLayout {
            spacing: 0

            ListView {
                id: itemListView
                property bool centeredGroup: true

                delegate: buttonDelegate
                implicitHeight: contentHeight
                implicitWidth: contentWidth
                interactive: false
                model: CallOverlayModel.primaryModel()
                orientation: ListView.Horizontal
            }
        }
    }
    Item {
        id: overflowRect
        property real remainingSpace: (root.width - centralControls.width) / 2

        anchors.right: parent.right
        height: root.height
        width: childrenRect.width

        RowLayout {
            spacing: itemSpacing

            ListView {
                id: overflowItemListView
                property int nOverflowItems: overflowItemCount - overflowIndex
                property int overflowIndex: {
                    var maxItems = Math.floor((overflowRect.remainingSpace) / (root.height + itemSpacing)) - 2;
                    return Math.min(overflowItemCount, maxItems);
                }

                delegate: buttonDelegate
                implicitHeight: overflowRect.height
                implicitWidth: contentWidth
                interactive: false
                model: CallOverlayModel.overflowModel()
                orientation: ListView.Horizontal
                spacing: itemSpacing

                onNOverflowItemsChanged: {
                    var diff = overflowItemListView.count - nOverflowItems;
                    var effectiveOverflowIndex = overflowIndex;
                    if (effectiveOverflowIndex === overflowItemCount - 2)
                        effectiveOverflowIndex += diff;
                    CallOverlayModel.overflowIndex = effectiveOverflowIndex;
                }
            }
            ComboBox {
                id: overflowButton
                delegate: buttonDelegate
                height: width
                indicator: null
                model: CallOverlayModel.overflowHiddenModel()
                visible: CallOverlayModel.overflowIndex < overflowItemCount - 2
                width: root.height

                Item {
                    anchors.bottom: parent.top
                    anchors.bottomMargin: itemSpacing
                    implicitHeight: (overflowButton.width + itemSpacing) * urgentOverflowListView.count
                    visible: !overflowButton.popup.visible
                    width: overflowButton.width

                    JamiListView {
                        id: urgentOverflowListView
                        anchors.fill: parent
                        delegate: buttonDelegate
                        model: !overflowButton.popup.visible ? CallOverlayModel.overflowVisibleModel() : null
                        spacing: itemSpacing

                        add: Transition {
                            NumberAnimation {
                                duration: 80
                                from: 0
                                property: "opacity"
                                to: 1.0
                            }
                            NumberAnimation {
                                duration: 80
                                from: 0
                                property: "scale"
                                to: 1.0
                            }
                        }
                    }
                }

                background: HalfPill {
                    color: overflowButton.down ? "#c4777777" : overflowButton.hovered ? "#c4444444" : "#c4272727"
                    implicitHeight: implicitWidth
                    implicitWidth: root.height
                    radius: type === HalfPill.None ? 0 : 5
                    type: {
                        if (overflowItemListView.count || urgentOverflowListView.count || (overflowHiddenListView.count && overflowButton.popup.visible)) {
                            return HalfPill.None;
                        } else {
                            return HalfPill.Left;
                        }
                    }

                    Behavior on color  {
                        ColorAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }
                contentItem: ResponsiveImage {
                    anchors.fill: parent
                    anchors.margins: 17
                    color: "white"
                    source: JamiResources.more_vert_24dp_svg
                }
                popup: Popup {
                    implicitHeight: Math.min(root.parentHeight - itemSpacing, (overflowButton.width + itemSpacing) * overflowHiddenListView.count)
                    padding: 0
                    width: overflowButton.width
                    y: overflowButton.height + itemSpacing

                    background: Rectangle {
                        color: "transparent"
                    }
                    contentItem: JamiListView {
                        id: overflowHiddenListView
                        implicitHeight: Math.min(contentHeight, parent.height)
                        interactive: true
                        model: overflowButton.popup.visible ? overflowButton.delegateModel : null
                        spacing: itemSpacing
                    }
                }
            }
        }
    }
}
