/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

SettingsPageBase {
    id: root
    property real aspectRatio: 0.75
    property int itemWidth: 266

    title: JamiStrings.video

    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        ColumnLayout {
            id: generalSettings
            spacing: JamiTheme.settingsCategoryAudioVideoSpacing
            width: parent.width

            function startPreviewing(force = false) {
                if (!visible) {
                    return;
                }
                previewWidget.startWithId(VideoDevices.getDefaultDevice(), force);
            }

            Component.onCompleted: {
                flipControl.checked = UtilsAdapter.getAppValue(Settings.FlipSelf);
                hardwareAccelControl.checked = AvAdapter.getHardwareAcceleration();
                if (previewWidget.visible)
                    startPreviewing(true);
            }
            Component.onDestruction: {
                previewWidget.startWithId("");
            }

            Connections {
                target: VideoDevices

                function onDefaultFpsChanged() {
                    generalSettings.startPreviewing(true);
                }
                function onDefaultResChanged() {
                    generalSettings.startPreviewing(true);
                }
                function onDeviceAvailable() {
                    generalSettings.startPreviewing();
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

            // video Preview
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: JamiTheme.preferredMarginSize
                Layout.maximumWidth: 515
                Layout.minimumWidth: 200
                Layout.preferredHeight: width * previewWidget.invAspectRatio
                Layout.preferredWidth: parent.width
                color: JamiTheme.primaryForegroundColor
                visible: VideoDevices.listSize !== 0

                LocalVideo {
                    id: previewWidget
                    anchors.fill: parent
                    flip: flipControl.checked

                    underlayItems: Text {
                        anchors.centerIn: parent
                        color: "white"
                        font.capitalization: Font.AllUppercase
                        font.pointSize: 18
                        text: JamiStrings.noVideo
                    }
                }
            }
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
                currentSelectionText: VideoDevices.defaultName
                enabled: VideoDevices.listSize !== 0
                labelText: JamiStrings.device
                opacity: enabled ? 1.0 : 0.5
                placeholderText: JamiStrings.noVideoDevice
                role: "DeviceName"
                tipText: JamiStrings.selectVideoDevice
                widthOfComboBox: itemWidth

                onActivated: {
                    // TODO: start and stop preview logic in here should be in LRC
                    previewWidget.startWithId("");
                    VideoDevices.setDefaultDevice(filteredDevicesModel.mapToSource(modelIndex));
                    generalSettings.startPreviewing();
                }

                comboModel: SortFilterProxyModel {
                    id: filteredDevicesModel
                    filters: ValueFilter {
                        enabled: deviceSourceModel.count > 1
                        inverted: true
                        roleName: "DeviceName"
                        value: VideoDevices.defaultName
                    }
                    sourceModel: SortFilterProxyModel {
                        id: deviceSourceModel
                        sourceModel: VideoDevices.deviceSourceModel
                    }
                }
            }
            SettingsComboBox {
                id: resolutionComboBoxSetting
                Layout.fillWidth: true
                currentSelectionText: VideoDevices.defaultRes
                enabled: VideoDevices.listSize !== 0
                labelText: JamiStrings.resolution
                opacity: enabled ? 1.0 : 0.5
                role: "Resolution"
                tipText: JamiStrings.selectVideoResolution
                widthOfComboBox: itemWidth

                onActivated: VideoDevices.setDefaultDeviceRes(filteredResModel.mapToSource(modelIndex))

                comboModel: SortFilterProxyModel {
                    id: filteredResModel
                    filters: ValueFilter {
                        enabled: resSourceModel.count > 1
                        inverted: true
                        roleName: "Resolution"
                        value: VideoDevices.defaultRes
                    }
                    sourceModel: SortFilterProxyModel {
                        id: resSourceModel
                        sourceModel: VideoDevices.resSourceModel
                    }
                }
            }
            SettingsComboBox {
                id: fpsComboBoxSetting
                Layout.fillWidth: true
                currentSelectionText: VideoDevices.defaultFps.toString()
                enabled: VideoDevices.listSize !== 0
                labelText: JamiStrings.fps
                opacity: enabled ? 1.0 : 0.5
                role: "FPS"
                tipText: JamiStrings.selectFPS
                widthOfComboBox: itemWidth

                onActivated: VideoDevices.setDefaultDeviceFps(filteredFpsModel.mapToSource(modelIndex))

                comboModel: SortFilterProxyModel {
                    id: filteredFpsModel
                    filters: ValueFilter {
                        enabled: fpsSourceModel.count > 1
                        inverted: true
                        roleName: "FPS"
                        value: VideoDevices.defaultFps
                    }
                    sourceModel: SortFilterProxyModel {
                        id: fpsSourceModel
                        sourceModel: VideoDevices.fpsSourceModel
                    }
                }
            }
            ToggleSwitch {
                id: hardwareAccelControl
                Layout.fillWidth: true
                labelText: JamiStrings.enableHWAccel

                onSwitchToggled: {
                    AvAdapter.setHardwareAcceleration(checked);
                    generalSettings.startPreviewing(true);
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                color: JamiTheme.primaryForegroundColor
                font.kerning: true
                font.pointSize: JamiTheme.settingsFontSize
                horizontalAlignment: Text.AlignHCenter
                text: JamiStrings.previewUnavailable
                verticalAlignment: Text.AlignVCenter
                visible: VideoDevices.listSize === 0
            }
        }
    }
}
