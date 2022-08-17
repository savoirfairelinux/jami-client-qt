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

import "../js/contactpickercreation.js" as ContactPickerCreation
import "../js/selectscreenwindowcreation.js" as SelectScreenWindowCreation
import "../js/screenrubberbandcreation.js" as ScreenRubberBandCreation
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

import "../../commoncomponents"

Item {
    id: root

    property string callId: CurrentCall.id
    property bool isAudioOnly: CurrentCall.isAudioOnly
    property bool isAudioMuted: CurrentCall.isAudioMuted
    property bool isVideoMuted: CurrentCall.isVideoMuted
    property bool remoteRecording: CurrentCall.isRecordingRemotely
    property bool isSIP: CurrentCall.isSIP
    property bool isModerator: CurrentCall.isModerator
    property bool isConference: CurrentCall.isConference
    property bool isGrid: CurrentCall.isGrid
    property bool localHandRaised: CurrentCall.isHandRaised
    property bool sharingActive: CurrentCall.isSharing
    property bool isRecording: CurrentCall.isRecordingLocally

    signal chatButtonClicked
    signal fullScreenClicked

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

        visible: CurrentCall.isPaused

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
            function onRecordCallClicked() { CallAdapter.recordThisCallToggle() }
            function onShareFileClicked() { jamiFileDialog.open() }
            function onPluginsClicked() { openPluginsMenu() }
            function onFullScreenClicked() { root.fullScreenClicked() }
        }
    }

    CallViewContextMenu {
        id: callViewContextMenu

        onTransferCallButtonClicked: openContactPicker(ContactList.TRANSFER)
        onPluginItemClicked: openPluginsMenu()
        onRecordCallClicked: CallAdapter.recordThisCallToggle()
        onOpenSelectionWindow: {
            SelectScreenWindowCreation.createSelectScreenWindowObject()
            SelectScreenWindowCreation.showSelectScreenWindow(callPreviewId, windowSelection)
        }
    }
}
