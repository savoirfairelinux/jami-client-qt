/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import QtQuick

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../js/contactpickercreation.js" as ContactPickerCreation
import "../js/selectscreenwindowcreation.js" as SelectScreenWindowCreation
import "../js/screenrubberbandcreation.js" as ScreenRubberBandCreation
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

import "../../commoncomponents"

Item {
    id: root

    property bool isPaused
    property bool isAudioOnly
    property bool isAudioMuted
    property bool isVideoMuted
    property bool isRecording
    property bool remoteRecording
    property bool isSIP
    property bool isModerator
    property bool isConference
    property bool isGrid
    property bool participantsSide: UtilsAdapter.getAppValue(Settings.ParticipantsSide)
    property bool localHandRaised
    property bool sharingActive: AvAdapter.isSharing()
    property string callId: ""

    signal chatButtonClicked
    signal fullScreenClicked

    function setRecording(localIsRecording) {
        callViewContextMenu.localIsRecording = localIsRecording
        mainOverlay.recordingVisible = localIsRecording
                || callViewContextMenu.peerIsRecording
    }

    function updateUI(isPaused, isAudioOnly, isAudioMuted, isSIP, isGrid) {
        if (isPaused !== undefined) {
            root.isPaused = isPaused
            root.isAudioOnly = isAudioOnly
            root.isAudioMuted = isAudioMuted
            callViewContextMenu.isVideoMuted = root.isVideoMuted
            root.isSIP = isSIP
            root.isGrid = isGrid
            root.localHandRaised = CallAdapter.isHandRaised()
        }
        root.isRecording = CallAdapter.isRecordingThisCall()
        root.isModerator = CallAdapter.isModerator()
    }

    function showOnHoldImage(visible) {
        onHoldImage.visible = visible
    }

    function closeContextMenuAndRelatedWindows() {
        ContactPickerCreation.closeContactPicker()
        sipInputPanel.close()
        SelectScreenWindowCreation.destroySelectScreenWindow()
        ScreenRubberBandCreation.destroyScreenRubberBandWindow()
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
            label += " " + ((peers.length > 1) ? JamiStrings.areRecording : JamiStrings.isRecording)
        }

        mainOverlay.remoteRecordingLabel = state ? label : JamiStrings.peerStoppedRecording
        root.remoteRecording = state
        callOverlayRectMouseArea.entered()
    }

    function resetRemoteRecording() {
        mainOverlay.remoteRecordingLabel = ""
        root.remoteRecording = false
    }

    SipInputPanel {
        id: sipInputPanel

        x: root.width / 2 - sipInputPanel.width / 2
        y: root.height / 2 - sipInputPanel.height / 2
    }

    JamiFileDialog {
        id: jamiFileDialog

        mode: JamiFileDialog.Mode.OpenFile

        onAccepted: {
            AvAdapter.shareFile(jamiFileDialog.file)
        }
    }

    ResponsiveImage {
        id: onHoldImage

        anchors.verticalCenter: root.verticalCenter
        anchors.horizontalCenter: root.horizontalCenter

        width: 200
        height: 200

        visible: false

        source: JamiResources.ic_pause_white_100px_svg
    }

    function openContactPicker(type) {
        ContactPickerCreation.openContactPicker(type, root)
    }

    function openShareScreen() {
        if (Qt.application.screens.length === 1) {
            AvAdapter.shareEntireScreen(0)
        } else {
            SelectScreenWindowCreation.createSelectScreenWindowObject(appWindow)
            SelectScreenWindowCreation.showSelectScreenWindow(callPreviewId, false)
        }
    }

    function openShareWindow() {
        AvAdapter.getListWindows()
        if (AvAdapter.windowsNames.length >= 1) {
            SelectScreenWindowCreation.createSelectScreenWindowObject(appWindow)
            SelectScreenWindowCreation.showSelectScreenWindow(callPreviewId, true)
        }
    }

    function openShareScreenArea() {
        if (Qt.platform.os !== "windows") {
            AvAdapter.shareScreenArea(0, 0, 0, 0)
        } else {
            ScreenRubberBandCreation.createScreenRubberBandWindowObject()
            ScreenRubberBandCreation.showScreenRubberBandWindow()
        }
    }

    function openPluginsMenu() {
        PluginHandlerPickerCreation.createPluginHandlerPickerObjects(root, true)
        PluginHandlerPickerCreation.openPluginHandlerPicker()
    }

    function recordClicked() {
        CallAdapter.recordThisCallToggle()
        updateUI()
    }

    MainOverlay {
        id: mainOverlay

        anchors.fill: parent
        isRecording: root.isRecording
        remoteRecording: root.remoteRecording

        Connections {
            target: mainOverlay.callActionBar
            function onChatClicked() { root.chatButtonClicked() }
            function onAddToConferenceClicked() { openContactPicker(ContactList.CONFERENCE) }
            function onTransferClicked() { openContactPicker(ContactList.TRANSFER) }
            function onResumePauseCallClicked() { CallAdapter.holdThisCallToggle() }
            function onShowInputPanelClicked() { sipInputPanel.open() }
            function onShareScreenClicked() { openShareScreen() }
            function onShareWindowClicked() { openShareWindow() }
            function onStopSharingClicked() { AvAdapter.stopSharing() }
            function onShareScreenAreaClicked() { openShareScreenArea() }
            function onRecordCallClicked() { recordClicked() }
            function onShareFileClicked() { jamiFileDialog.open() }
            function onPluginsClicked() { openPluginsMenu() }
            function onFullScreenClicked() { root.fullScreenClicked() }
        }
    }

    CallViewContextMenu {
        id: callViewContextMenu

        isSIP: root.isSIP
        isPaused: root.isPaused
        isRecording: root.isRecording

        onTransferCallButtonClicked: openContactPicker(ContactList.TRANSFER)
        onPluginItemClicked: openPluginsMenu()
        onRecordCallClicked: root.recordClicked()
        onOpenSelectionWindow: {
            SelectScreenWindowCreation.createSelectScreenWindowObject()
            SelectScreenWindowCreation.showSelectScreenWindow(callPreviewId, windowSelection)
        }
    }
}
