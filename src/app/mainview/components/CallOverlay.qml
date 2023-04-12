/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    property bool participantsSide: UtilsAdapter.getAppValue(Settings.ParticipantsSide)

    signal chatButtonClicked
    signal closeClicked
    function closeContextMenuAndRelatedWindows() {
        sipInputPanel.close();
        ScreenRubberBandCreation.destroyScreenRubberBandWindow();
        PluginHandlerPickerCreation.closePluginHandlerPicker();
        root.closeClicked();
        callInformationOverlay.close();
    }
    signal fullScreenClicked

    // x, y position does not need to be translated
    // since they all fill the call page
    function openCallViewContextMenuInPos(x, y, hoveredOverlayUri, hoveredOverlaySinkId, hoveredOverVideoMuted, isOnLocal) {
        callViewContextMenu.x = root.width - x >= callViewContextMenu.width ? x : root.width - callViewContextMenu.width;
        callViewContextMenu.y = root.height - y >= callViewContextMenu.height ? y : root.height - callViewContextMenu.height;
        callViewContextMenu.hoveredOverlayUri = hoveredOverlayUri;
        callViewContextMenu.hoveredOverlaySinkId = hoveredOverlaySinkId;
        callViewContextMenu.hoveredOverVideoMuted = hoveredOverVideoMuted;
        callViewContextMenu.isOnLocal = isOnLocal;
        callViewContextMenu.open();
    }
    function openContactPicker(type) {
        ContactPickerCreation.presentContactPickerPopup(type, root);
    }
    function openPluginsMenu() {
        PluginHandlerPickerCreation.createPluginHandlerPickerObjects(root, true);
        PluginHandlerPickerCreation.openPluginHandlerPicker();
    }
    function openShareFileDialog() {
        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                "fileMode": JamiFileDialog.OpenFile,
                "nameFilters": [JamiStrings.allFiles]
            });
        dlg.fileAccepted.connect(function (file) {
                AvAdapter.shareFile(file);
            });
    }
    function openShareScreen() {
        if (Qt.application.screens.length === 1) {
            AvAdapter.shareEntireScreen(0);
        } else {
            SelectScreenWindowCreation.presentSelectScreenWindow(appWindow, false);
        }
    }
    function openShareScreenArea() {
        if (Qt.platform.os !== "windows") {
            AvAdapter.shareScreenArea(0, 0, 0, 0);
        } else {
            ScreenRubberBandCreation.createScreenRubberBandWindowObject();
            ScreenRubberBandCreation.showScreenRubberBandWindow();
        }
    }
    function openShareWindow() {
        AvAdapter.getListWindows();
        if (AvAdapter.windowsNames.length >= 1) {
            SelectScreenWindowCreation.presentSelectScreenWindow(appWindow, true);
        }
    }
    signal swarmDetailsClicked

    onVisibleChanged: {
        callViewContextMenu.close();
    }

    DropArea {
        anchors.fill: parent

        onDropped: function (drop) {
            AvAdapter.shareFile(drop.urls);
        }
    }
    SipInputPanel {
        id: sipInputPanel
        x: root.width / 2 - sipInputPanel.width / 2
        y: root.height / 2 - sipInputPanel.height / 2
    }
    CallInformationOverlay {
        id: callInformationOverlay
        advancedList: CallAdapter.callInformationList
        fps: AvAdapter.renderersInfoList
        visible: false

        Component.onDestruction: {
            CallAdapter.stopTimerInformation();
        }
    }
    ResponsiveImage {
        id: onHoldImage
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter
        height: 200
        source: JamiResources.ic_pause_white_100px_svg
        visible: CurrentCall.isPaused
        width: 200
    }
    MainOverlay {
        id: mainOverlay
        anchors.fill: parent

        Connections {
            target: mainOverlay.callActionBar

            function onAddToConferenceClicked() {
                openContactPicker(ContactList.CONFERENCE);
            }
            function onChatClicked() {
                root.chatButtonClicked();
            }
            function onFullScreenClicked() {
                root.fullScreenClicked();
            }
            function onPluginsClicked() {
                openPluginsMenu();
            }
            function onRecordCallClicked() {
                CallAdapter.recordThisCallToggle();
            }
            function onResumePauseCallClicked() {
                CallAdapter.holdThisCallToggle();
            }
            function onShareFileClicked() {
                openShareFileDialog();
            }
            function onShareScreenAreaClicked() {
                openShareScreenArea();
            }
            function onShareScreenClicked() {
                openShareScreen();
            }
            function onShareWindowClicked() {
                openShareWindow();
            }
            function onShowInputPanelClicked() {
                sipInputPanel.open();
            }
            function onStopSharingClicked() {
                AvAdapter.stopSharing(CurrentCall.sharingSource);
            }
            function onSwarmDetailsClicked() {
                root.swarmDetailsClicked();
            }
            function onTransferClicked() {
                openContactPicker(ContactList.TRANSFER);
            }
        }
    }
    CallViewContextMenu {
        id: callViewContextMenu
        onScreenshotButtonHoveredChanged: {
            participantsLayer.screenshotButtonHovered = screenshotButtonHovered;
        }
        onScreenshotTaken: {
            toastManager.instantiateToast();
        }
    }
}
