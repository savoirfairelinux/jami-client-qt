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
import SortFilterProxyModel 0.2
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

    property alias overflowOpen: overflowButton.popup.visible
    property bool subMenuOpen: false
    property real parentHeight
    property bool barHovered: false

    property real itemSpacing: 2

    signal chatClicked
    signal addToConferenceClicked
    signal transferClicked
    signal resumePauseCallClicked
    signal showInputPanelClicked
    signal shareScreenClicked
    signal shareWindowClicked
    signal stopSharingClicked
    signal shareScreenAreaClicked
    signal shareFileClicked
    signal pluginsClicked
    signal recordCallClicked
    signal fullScreenClicked
    signal swarmDetailsClicked

    Component {
        id: buttonDelegate

        CallButtonDelegate {
            width: root.height
            height: width
            barWidth: root.width
            onSubMenuVisibleChanged: subMenuOpen = subMenuVisible
            onHoveredChanged: root.barHovered = hovered
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

    property list<Action> menuActions: [
        Action {
            id: audioInputMenuAction
            text: JamiStrings.selectAudioInputDevice
            Component.onCompleted: enabled = audioInputDeviceListModel.rowCount()
            property var listModel: AudioDeviceModel {
                id: audioInputDeviceListModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Record
            }
            function accept(index) {
                AvAdapter.stopAudioMeter();
                AVModel.setInputDevice(index);
                AvAdapter.startAudioMeter();
            }
        },
        Action {
            id: audioOutputMenuAction
            text: JamiStrings.selectAudioOutputDevice
            Component.onCompleted: enabled = audioOutputDeviceListModel.rowCount()
            property var listModel: AudioDeviceModel {
                id: audioOutputDeviceListModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Playback
            }
            function accept(index) {
                AvAdapter.stopAudioMeter();
                AVModel.setOutputDevice(index);
                AvAdapter.startAudioMeter();
            }
        },
        Action {
            id: shareMenuAction
            text: JamiStrings.selectShareMethod
            property int popupMode: CallActionBar.ActionPopupMode.ListElement
            property var listModel: ListModel {
                id: shareModel
            }
            onTriggered: {
                shareModel.clear();
                shareModel.append({
                        "Name": JamiStrings.shareScreen,
                        "IconSource": JamiResources.laptop_black_24dp_svg
                    });
                if (Qt.platform.os.toString() !== "osx" && !UtilsAdapter.isWayland()) {
                    shareModel.append({
                            "Name": JamiStrings.shareWindow,
                            "IconSource": JamiResources.window_black_24dp_svg
                        });
                }
                if (Qt.platform.os.toString() !== "windows" && !UtilsAdapter.isWayland()) {
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
        },
        Action {
            id: layoutMenuAction
            text: JamiStrings.layoutSettings
            property int popupMode: CallActionBar.ActionPopupMode.LayoutOption
            property var listModel: ListModel {
                id: layoutModel
            }
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
            enabled: VideoDevices.listSize !== 0
            text: JamiStrings.selectVideoDevice
            property var listModel: VideoDevices.deviceSourceModel
            function accept(index) {
                VideoDevices.setDefaultDevice(index);
            }
        }
    ]

    property list<Action> primaryActions: [
        Action {
            id: muteAudioAction
            onTriggered: {
                var muteState = CallAdapter.getMuteState(CurrentAccount.uri);
                var modMuted = muteState === CallAdapter.MODERATOR_MUTED || muteState === CallAdapter.BOTH_MUTED;
                if (muteAudioAction.checked && modMuted) {
                    muteAlertActive = true;
                    muteAlertMessage = JamiStrings.participantModIsStillMuted;
                }
                CallAdapter.muteAudioToggle();
            }
            checkable: true
            icon.source: checked ? JamiResources.micro_off_black_24dp_svg : JamiResources.micro_black_24dp_svg
            icon.color: checked ? "red" : "white"
            text: !checked ? JamiStrings.mute : JamiStrings.unmute
            checked: CurrentCall.isAudioMuted
            property var menuAction: audioInputMenuAction
        },
        Action {
            id: hangupAction
            onTriggered: CallAdapter.hangUpThisCall()
            icon.source: JamiResources.ic_call_end_white_24dp_svg
            icon.color: "white"
            text: JamiStrings.endCall
            property bool hasBg: true
        },
        Action {
            id: muteVideoAction
            onTriggered: CallAdapter.muteCameraToggle()
            checkable: true
            icon.source: checked ? JamiResources.videocam_off_24dp_svg : JamiResources.videocam_24dp_svg
            icon.color: checked ? "red" : "white"
            text: !checked ? JamiStrings.muteCamera : JamiStrings.unmuteCamera
            checked: !CurrentCall.isCapturing
            property var menuAction: videoInputMenuAction
            enabled: CurrentAccount.videoEnabled_Video
            onEnabledChanged: CallOverlayModel.setEnabled(this, muteVideoAction.enabled)
        }
    ]

    property list<Action> secondaryActions: [
        Action {
            id: audioOutputAction
            // temp hack for missing back-end, just open device selection
            property bool openPopupWhenClicked: true
            checkable: !openPopupWhenClicked
            icon.source: JamiResources.spk_black_24dp_svg
            icon.color: "white"
            text: JamiStrings.selectAudioOutputDevice
            property var menuAction: audioOutputMenuAction
        },
        Action {
            id: addPersonAction
            onTriggered: root.addToConferenceClicked()
            icon.source: JamiResources.add_people_black_24dp_svg
            icon.color: "white"
            text: JamiStrings.addParticipants
            enabled: CurrentCall.isModerator && !CurrentCall.isSIP
            onEnabledChanged: CallOverlayModel.setEnabled(this, addPersonAction.enabled)
        },
        Action {
            id: chatAction
            onTriggered: root.chatClicked()
            icon.source: JamiResources.chat_black_24dp_svg
            icon.color: "white"
            text: JamiStrings.chat
        },
        Action {
            id: resumePauseCallAction
            onTriggered: root.resumePauseCallClicked()
            icon.source: CurrentCall.isPaused ? JamiResources.play_circle_outline_24dp_svg : JamiResources.pause_circle_outline_24dp_svg
            icon.color: "white"
            text: CurrentCall.isPaused ? JamiStrings.resumeCall : JamiStrings.pauseCall
            enabled: CurrentCall.isSIP
            onEnabledChanged: CallOverlayModel.setEnabled(this, resumePauseCallAction.enabled)
        },
        Action {
            id: inputPanelSIPAction
            onTriggered: root.showInputPanelClicked()
            icon.source: JamiResources.ic_keypad_svg
            icon.color: "white"
            text: JamiStrings.sipInputPanel
            enabled: CurrentCall.isSIP
            onEnabledChanged: CallOverlayModel.setEnabled(this, inputPanelSIPAction.enabled)
        },
        Action {
            id: callTransferAction
            onTriggered: root.transferClicked()
            icon.source: JamiResources.phone_forwarded_24dp_svg
            icon.color: "white"
            text: JamiStrings.transferCall
            enabled: CurrentCall.isSIP
            onEnabledChanged: CallOverlayModel.setEnabled(this, callTransferAction.enabled)
        },
        Action {
            id: shareAction
            onTriggered: {
                if (CurrentCall.isSharing)
                    root.stopSharingClicked();
                else
                    root.shareScreenClicked();
            }
            icon.source: CurrentCall.isSharing ? JamiResources.share_stop_black_24dp_svg : JamiResources.share_screen_black_24dp_svg
            icon.color: CurrentCall.isSharing ? "red" : "white"
            text: CurrentCall.isSharing ? JamiStrings.stopSharing : JamiStrings.shareScreen
            property real size: 34
            property var menuAction: shareMenuAction
            enabled: CurrentAccount.videoEnabled_Video && !CurrentCall.isSIP
            onEnabledChanged: CallOverlayModel.setEnabled(this, shareAction.enabled)
        },
        Action {
            id: raiseHandAction
            onTriggered: CallAdapter.raiseHand("", "", !CallAdapter.isHandRaised())
            checkable: true
            icon.source: JamiResources.hand_black_24dp_svg
            icon.color: checked ? JamiTheme.raiseHandColor : "white"
            text: checked ? JamiStrings.lowerHand : JamiStrings.raiseHand
            checked: CurrentCall.isHandRaised
            property real size: 34
            enabled: CurrentCall.isConference
            onEnabledChanged: CallOverlayModel.setEnabled(this, raiseHandAction.enabled)
        },
        Action {
            id: layoutAction
            onTriggered: {
                if (!CurrentCall.isGrid)
                    CallAdapter.showGridConferenceLayout();
            }
            checkable: true
            icon.source: JamiResources.mosaic_black_24dp_svg
            icon.color: "white"
            text: JamiStrings.layoutSettings
            property real size: 28
            property var menuAction: layoutMenuAction
        },
        Action {
            id: recordAction
            onTriggered: root.recordCallClicked()
            checkable: true
            icon.source: JamiResources.record_black_24dp_svg
            icon.color: checked ? "red" : "white"
            text: !checked ? JamiStrings.startRec : JamiStrings.stopRec
            property bool blinksWhenChecked: true
            property real size: 28
            checked: CurrentCall.isRecordingLocally
            onCheckedChanged: function (checked) {
                CallOverlayModel.setUrgentCount(recordAction, checked ? -1 : 0);
            }
        },
        Action {
            id: pluginsAction
            onTriggered: root.pluginsClicked()
            icon.source: JamiResources.plugins_24dp_svg
            icon.color: "white"
            text: JamiStrings.viewPlugin
            enabled: PluginAdapter.callMediaHandlersListCount
            onEnabledChanged: CallOverlayModel.setEnabled(this, pluginsAction.enabled)
        },
        Action {
            id: swarmDetailsAction
            onTriggered: root.swarmDetailsClicked()
            icon.source: JamiResources.swarm_details_panel_svg
            icon.color: "white"
            text: JamiStrings.details
            enabled: {
                if (CurrentCall.isSIP)
                    return true;
                if (!CurrentConversation.isTemporary && !CurrentConversation.isSwarm)
                    return false;
                if (CurrentConversation.isRequest || CurrentConversation.needsSyncing)
                    return false;
                return true;
            }
            onEnabledChanged: CallOverlayModel.setEnabled(this, swarmDetailsAction.enabled)
        }
    ]

    property var overflowItemCount

    Component.onCompleted: {
        CallOverlayModel.clearControls();

        // centered controls
        CallOverlayModel.addPrimaryControl(muteAudioAction, muteAudioAction.enabled);
        CallOverlayModel.addPrimaryControl(hangupAction, hangupAction.enabled);
        CallOverlayModel.addPrimaryControl(muteVideoAction, muteVideoAction.enabled);

        // overflow controls
        CallOverlayModel.addSecondaryControl(audioOutputAction, audioOutputAction.enabled);
        CallOverlayModel.addSecondaryControl(raiseHandAction, raiseHandAction.enabled);
        CallOverlayModel.addSecondaryControl(addPersonAction, addPersonAction.enabled);
        CallOverlayModel.addSecondaryControl(resumePauseCallAction, resumePauseCallAction.enabled);
        CallOverlayModel.addSecondaryControl(inputPanelSIPAction, inputPanelSIPAction.enabled);
        CallOverlayModel.addSecondaryControl(callTransferAction, callTransferAction.enabled);
        CallOverlayModel.addSecondaryControl(chatAction, chatAction.enabled);
        CallOverlayModel.addSecondaryControl(shareAction, shareAction.enabled);
        CallOverlayModel.addSecondaryControl(layoutAction, layoutAction.enabled);
        CallOverlayModel.addSecondaryControl(recordAction, recordAction.enabled);
        CallOverlayModel.addSecondaryControl(pluginsAction, pluginsAction.enabled);
        CallOverlayModel.addSecondaryControl(swarmDetailsAction, swarmDetailsAction.enabled);
        overflowItemCount = CallOverlayModel.secondaryModel().rowCount();
    }

    Item {
        id: centralControls
        anchors.centerIn: parent
        width: childrenRect.width
        height: root.height

        RowLayout {
            spacing: 0

            ListView {
                id: itemListView

                property bool centeredGroup: true

                orientation: ListView.Horizontal
                implicitWidth: contentWidth
                height: root.height
                interactive: false

                model: SortFilterProxyModel {
                    sourceModel: root.visible ? CallOverlayModel.primaryModel() : null
                    filters: ValueFilter {
                        roleName: "Enabled"
                        value: true
                    }
                }
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

        //put in top
        z: 1

        RowLayout {
            spacing: itemSpacing

            ListView {
                id: overflowItemListView

                orientation: ListView.Horizontal
                implicitWidth: contentWidth
                implicitHeight: overflowRect.height

                interactive: false
                spacing: itemSpacing

                property int overflowIndex: {
                    var maxItems = Math.floor((overflowRect.remainingSpace) / (root.height + itemSpacing)) - 2;
                    var idx = Math.min(overflowItemCount, maxItems);
                    idx = Math.max(0, idx);
                    if (CallOverlayModel.overflowModel().rowCount() > 0 || CallOverlayModel.overflowHiddenModel().rowCount() > 0) {
                        var visibleIdx = CallOverlayModel.overflowModel().mapToSource(CallOverlayModel.overflowModel().index(idx, 0)).row;
                        var hiddenIdx = CallOverlayModel.overflowHiddenModel().mapToSource(CallOverlayModel.overflowHiddenModel().index(idx - CallOverlayModel.overflowModel().rowCount(), 0)).row;
                        if (visibleIdx >= 0 || hiddenIdx >= 0)
                            idx = Math.max(visibleIdx, hiddenIdx);
                    }
                    return idx;
                }
                property int nOverflowItems: overflowItemCount - overflowIndex
                onNOverflowItemsChanged: {
                    var diff = overflowItemListView.count - nOverflowItems;
                    var effectiveOverflowIndex = overflowIndex;
                    if (effectiveOverflowIndex === overflowItemCount - 2)
                        effectiveOverflowIndex += diff;
                    CallOverlayModel.overflowIndex = effectiveOverflowIndex;
                }

                model: root.visible ? CallOverlayModel.overflowModel() : null
                delegate: buttonDelegate
            }

            ComboBox {
                id: overflowButton

                visible: CallOverlayModel.overflowIndex < overflowItemCount - 2
                width: root.height
                height: width

                model: root.visible ? CallOverlayModel.overflowHiddenModel() : null

                delegate: buttonDelegate

                indicator: null

                contentItem: ResponsiveImage {
                    color: "white"
                    source: JamiResources.more_vert_24dp_svg
                    anchors.fill: parent
                    anchors.margins: 17
                }

                background: HalfPill {
                    implicitWidth: root.height
                    implicitHeight: implicitWidth
                    radius: type === HalfPill.None ? 0 : 5
                    color: overflowButton.down ? "#c4777777" : overflowButton.hovered ? "#c4444444" : "#c4272727"
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

                Item {
                    implicitHeight: (overflowButton.width + itemSpacing) * urgentOverflowListView.count
                    width: overflowButton.width
                    anchors.bottom: parent.top
                    anchors.bottomMargin: itemSpacing
                    visible: !overflowButton.popup.visible
                    JamiListView {
                        id: urgentOverflowListView

                        spacing: itemSpacing
                        anchors.fill: parent
                        model: !overflowButton.popup.visible ? CallOverlayModel.overflowVisibleModel() : null

                        delegate: buttonDelegate

                        add: Transition {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1.0
                                duration: 80
                            }
                            NumberAnimation {
                                property: "scale"
                                from: 0
                                to: 1.0
                                duration: 80
                            }
                        }
                    }
                }

                popup: Popup {
                    y: overflowButton.height + itemSpacing
                    width: overflowButton.width
                    implicitHeight: Math.min(root.parentHeight - itemSpacing, (overflowButton.width + itemSpacing) * overflowHiddenListView.count)
                    padding: 0

                    contentItem: JamiListView {
                        id: overflowHiddenListView
                        spacing: itemSpacing
                        implicitHeight: Math.min(contentHeight, parent.height)
                        interactive: true
                        model: overflowButton.popup.visible ? overflowButton.delegateModel : null
                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }
    }
}
