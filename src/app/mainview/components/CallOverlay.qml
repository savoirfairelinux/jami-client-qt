/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.UI as JUI

Item {
    id: root

    property bool participantsSide: UtilsAdapter.getAppValue(Settings.ParticipantsSide)
    property alias mainOverlayOpacity: mainOverlay.opacity

    signal chatButtonClicked
    signal fullScreenClicked
    signal closeClicked
    signal swarmDetailsClicked

    function closeContextMenuAndRelatedWindows() {
        screenRubberBand.close()
        pluginHandlerPicker.close()
        root.closeClicked();
        callInformationOverlay.close();
    }

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

    DropArea {
        anchors.fill: parent
        onDropped: function (drop) {
            AvAdapter.shareFile(drop.urls);
        }
    }

    ContactPicker {
        id: contactPicker
    }

    SelectScreen {
        id: selectScreen
    }

    ScreenRubberBand {
        id: screenRubberBand
        visible: false
    }

    PluginHandlerPicker {
        id: pluginHandlerPicker
        x: root.width / 2 - pluginHandlerPicker.width / 2
        y: root.height / 2 - pluginHandlerPicker.height / 2
    }

    SipInputPanel {
        id: sipInputPanel

        y: root.height / 2 - sipInputPanel.height / 2

        topRightRadius: 10
        bottomRightRadius: 10

        popupXHidden: root.width
        popupXVisible: root.width - sipInputPanel.width

        shown: false
    }

    CallInformationOverlay {
        id: callInformationOverlay

        visible: false
        advancedList: CallAdapter.callInformationList
        fps: AvAdapter.renderersInfoList

        Component.onDestruction: {
            CallAdapter.stopTimerInformation();
        }
    }

    function openShareFileDialog() {
        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JUI.FileDialog.qml", {
            "fileMode": JUI.FileDialog.OpenFile,
            "nameFilters": [JamiStrings.allFiles]
        });
        dlg.fileAccepted.connect(function (file) {
            AvAdapter.shareFile(file);
        });
    }

    JUI.ResponsiveImage {
        id: holdImage

        anchors.verticalCenter: root.verticalCenter
        anchors.horizontalCenter: root.horizontalCenter

        width: 200
        height: 200

        visible: CurrentCall.isPaused

        source: JamiResources.pause_white_100px_svg
    }

    function openContactPicker(type) {
        contactPicker.type = type
        contactPicker.open()
    }

    function openShareScreen() {
        if (UtilsAdapter.isWayland()) {
            AvAdapter.shareEntireScreenWayland();
        } else if (Qt.application.screens.length === 1) {
            AvAdapter.shareEntireScreen(0);
        } else {
            selectScreen.showWindows = false
            selectScreen.width = 0.75 * appWindow.width
            selectScreen.height = 0.75 * appWindow.height
            selectScreen.x = appWindow.x + (appWindow.width - selectScreen.width) / 2
            selectScreen.y = appWindow.y + (appWindow.height - selectScreen.height) / 2
            selectScreen.show()
        }
    }

    function openShareWindow() {
        if (UtilsAdapter.isWayland()) {
            AvAdapter.shareWindowWayland();
            return;
        }
        AvAdapter.getListWindows();
        if (AvAdapter.windowsNames.length >= 1) {
            selectScreen.showWindows = true
            selectScreen.width = 0.75 * appWindow.width
            selectScreen.height = 0.75 * appWindow.height
            selectScreen.x = appWindow.x + (appWindow.width - selectScreen.width) / 2
            selectScreen.y = appWindow.y + (appWindow.height - selectScreen.height) / 2
            selectScreen.show()
        }
    }

    function openShareScreenArea() {
        if (Qt.platform.os !== "windows") {
            AvAdapter.shareScreenArea(0, 0, 0, 0);
        } else {
            screenRubberBand.show()
            screenRubberBand.setAllScreensGeo()
        }
    }

    function openPluginsMenu() {
        pluginHandlerPicker.isCall = true
        pluginHandlerPicker.open()
    }

    MainOverlay {
        id: mainOverlay

        objectName: "mainOverlay"

        anchors.fill: parent

        Connections {
            target: mainOverlay.callActionBar
            function onChatClicked() {
                root.chatButtonClicked();
            }
            function onAddToConferenceClicked() {
                openContactPicker(ContactList.CONFERENCE);
            }
            function onTransferClicked() {
                openContactPicker(ContactList.TRANSFER);
            }
            function onResumePauseCallClicked() {
                CallAdapter.holdThisCallToggle();
            }
            function onShowInputPanelClicked() {
                sipInputPanel.shown = !sipInputPanel.shown;
            }
            function onShareScreenClicked() {
                openShareScreen();
            }
            function onShareWindowClicked() {
                openShareWindow();
            }
            function onStopSharingClicked() {
                AvAdapter.stopSharing(CurrentCall.sharingSource);
            }
            function onShareScreenAreaClicked() {
                openShareScreenArea();
            }
            function onRecordCallClicked() {
                CallAdapter.recordThisCallToggle();
            }
            function onShareFileClicked() {
                openShareFileDialog();
            }
            function onPluginsClicked() {
                openPluginsMenu();
            }
            function onFullScreenClicked() {
                root.fullScreenClicked();
            }
            function onSwarmDetailsClicked() {
                root.swarmDetailsClicked();
            }
        }
    }

    CallViewContextMenu {
        id: callViewContextMenu

        onScreenshotTaken: {
            toastManager.instantiateToast();
        }
        onScreenshotButtonHoveredChanged: {
            participantsLayer.screenshotButtonHovered = screenshotButtonHovered;
        }
    }
    onVisibleChanged: {
        callViewContextMenu.close();
    }
}
