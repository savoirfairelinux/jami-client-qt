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
    signal fullScreenClicked
    signal closeClicked
    signal swarmDetailsClicked

    function closeContextMenuAndRelatedWindows() {
        sipInputPanel.close();
        ScreenRubberBandCreation.destroyScreenRubberBandWindow();
        PluginHandlerPickerCreation.closePluginHandlerPicker();
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

    SipInputPanel {
        id: sipInputPanel

        x: root.width / 2 - sipInputPanel.width / 2
        y: root.height / 2 - sipInputPanel.height / 2
    }

    CallInformationOverlay {
        id: callInformationOverlay

        visible: false

        // Position just below the overlay title.
        y: {
            var title = JamiQmlUtils.findChildByName(mainOverlay, "overlayUpperPartRect");
            return title ? title.y + title.height : 0;
        }

        advancedList: CallAdapter.callInformationList
        fps: AvAdapter.renderersInfoList

        Component.onDestruction: CallAdapter.stopTimerInformation()
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
        ContactPickerCreation.presentContactPickerPopup(type, root);
    }

    function openShareScreen() {
        if (Qt.application.screens.length === 1) {
            AvAdapter.shareEntireScreen(0);
        } else {
            SelectScreenWindowCreation.presentSelectScreenWindow(appWindow, false);
        }
    }

    function openShareWindow() {
        AvAdapter.getListWindows();
        if (AvAdapter.windowsNames.length >= 1) {
            SelectScreenWindowCreation.presentSelectScreenWindow(appWindow, true);
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

    function openPluginsMenu() {
        PluginHandlerPickerCreation.createPluginHandlerPickerObjects(root, true);
        PluginHandlerPickerCreation.openPluginHandlerPicker();
    }

    MainOverlay {
        id: mainOverlay

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
                sipInputPanel.open();
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
