
/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects
import SortFilterProxyModel 0.2
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"
import "../../mainview/components"

BaseModalDialog {
    id: root

    property int itemWidth: 266 * 1.5
    property real aspectRatio: 0.75
    property string mostRecentUri: ""
    title: "Link Device Via QR Code"

    width: itemWidth
    height: itemWidth

    // width: itemWidth * 0.9
    spacing: JamiTheme.settingsCategoryAudioVideoSpacing
    // anchors.left: parent.Center
    // anchors.leftMargin: JamiTheme.preferredSettingsMarginSize


    function startPreviewing(force = false) {
        if (!visible) {
            return;
        }
        previewWidget.startWithId(VideoDevices.getDefaultDevice(), force);
    }

    function shutdownPreview() {
        // TODO
    }

    function shutdownScanner() {
        // TODO
        LinkDeviceModule.stopScanning(CurrentAccount.id);
    }

    Connections {
        target: VideoDevices

        function onDefaultResChanged() {
            root.startPreviewing(true);
        }

        function onDefaultFpsChanged() {
            root.startPreviewing(true);
        }

        function onDeviceAvailable() {
            root.startPreviewing();
        }

        function onDeviceListChanged() {
            var deviceModel = deviceComboBoxSetting.comboModel;
            var resModel = resolutionComboBoxSetting.comboModel;
            var fpsModel = fpsComboBoxSetting.comboModel;
            var resultList = deviceModel.match(deviceModel.index(0, 0), VideoInputDeviceModel.DeviceId, VideoDevices.defaultId);
            deviceComboBoxSetting.modelIndex = resultList.length > 0 ? resultList[0].row : deviceModel.rowCount() ? 0 : -1;
            resultList = resModel.match(resModel.index(0, 0), VideoFormatResolutionModel.Resolution, VideoDevices.defaultRes);
            resolutionComboBoxSetting.modelIndex = resultList.length > 0 ? resultList[0].row : deviceModel.rowCount() ? 0 : -1;
            resultList = fpsModel.match(fpsModel.index(0, 0), VideoFormatFpsModel.FPS, VideoDevices.defaultFps);
            fpsComboBoxSetting.modelIndex = resultList.length > 0 ? resultList[0].row : deviceModel.rowCount() ? 0 : -1;
        }
    }

    Connections {
        target: LinkDeviceModule

        function onPeerDetected(uri) {
            root.mostRecentUri = uri
        }

    }

    Component.onCompleted: {
        flipControl.checked = UtilsAdapter.getAppValue(Settings.FlipSelf);
        startPreviewing(true);
    }

    Component.onDestruction: previewWidget.stop()

    // video preview "finder window"
    RowLayout {
        Control {
            id: videoPreviewRoot

            Layout.minimumHeight: 150
            Layout.minimumWidth: 150
            width: 250
            height: 250
            padding: 8

            background: Rectangle {
                color: "#232323"
                radius: 6
            }

            contentItem: LocalVideo {
                id: previewWidget

                onRendererIdChanged: {
                    console.warn("[LinkDevice] Camera render ID changed.")
                    if (rendererId !== "") {
                        LinkDeviceModule.startScanning(CurrentAccount.id, rendererId);
                    }
                }

                anchors.fill: parent
                flip: flipControl.checked

                underlayItems: Text {
                    anchors.centerIn: parent
                    font.pointSize: 18
                    font.capitalization: Font.AllUppercase
                    color: "white"
                    text: JamiStrings.noVideo
                }

                // visible: VideoDevices.listSize !== 0
                Component.onCompleted: {
                    root.startPreviewing(true);
                    previewWidget.startWithId(VideoDevices.getDefaultDevice());
                }
            }
        }
    }

    JamiPushButton {
        id: settingsButton
        text: qsTr("Show Settings")
        onClicked: settingsDialog.open()
    }

    // feedback for user as to what uri they are connecting to
    RowLayout {
        spacing: 10
        anchors.centerIn: parent

        Label {
            id: uriShower
            text: root.mostRecentUri
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
        }

        Button {
            visible: root.mostRecentUri != ""
            text: qsTr("Proceed")
            onClicked: {
                console.warn("[LinkDevice] Proceeding with auth scheme: %1", root.mostRecentUri)
                // LinkDeviceModule.exportToPeer(CurrentAccount.id, root.mostRecentUri) // KESS moved this to wizard step view
                WizardViewStepModel.exportToPeer(CurrentAccount.id, root.mostRecentUri)
            }
        }
    }

	Dialog {
    	id: settingsDialog
    	title: qsTr("Settings")
    	standardButtons: Dialog.Ok | Dialog.Cancel

        // settings menu for changing camera values
    	contentItem: ColumnLayout {
        	spacing: 10

        	ToggleSwitch {
                id: flipControl

                Layout.fillWidth: true
                labelText: JamiStrings.mirrorLocalVideo

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.FlipSelf, checked);
                    CurrentCall.flipSelf = UtilsAdapter.getAppValue(Settings.FlipSelf);
                }
            }

            SettingsComboBox {
                id: deviceComboBoxSetting

                Layout.fillWidth: true

                enabled: VideoDevices.listSize !== 0
                opacity: enabled ? 1.0 : 0.5

                widthOfComboBox: itemWidth

                labelText: JamiStrings.device
                tipText: JamiStrings.selectVideoDevice
                placeholderText: JamiStrings.noVideoDevice
                currentSelectionText: VideoDevices.defaultName

                comboModel: SortFilterProxyModel {
                    id: filteredDevicesModel
                    sourceModel: SortFilterProxyModel {
                        id: deviceSourceModel
                        sourceModel: VideoDevices.deviceSourceModel
                    }
                    filters: ValueFilter {
                        roleName: "DeviceName"
                        value: VideoDevices.defaultName
                        inverted: true
                        enabled: deviceSourceModel.count > 1
                    }
                }
                role: "DeviceName"

                // Component.onCompleted: {
                onActivated: {
                    // TODO: start and stop preview logic in here should be in LRC
                    previewWidget.startWithId("");
                    VideoDevices.setDefaultDevice(filteredDevicesModel.mapToSource(modelIndex));
                    previewWidget.startWithId(VideoDevices.getDefaultDevice());
                    root.startPreviewing(true);
                }
            }
        }
	}
}
