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

    property int itemWidth: 266
    property real aspectRatio: 0.75

    signal navigateToMainView
    signal navigateToNewWizardView
    title: JamiStrings.video

    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize


        ColumnLayout {
            id: generalSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            function startPreviewing(force = false) {
                if (!visible) {
                    return
                }
                previewWidget.startWithId(VideoDevices.getDefaultDevice(), force)
            }

            onVisibleChanged: {
                flipControl.checked = UtilsAdapter.getAppValue(Settings.FlipSelf)
                if (visible) {
                    hardwareAccelControl.checked = AvAdapter.getHardwareAcceleration()
                    if (previewWidget.visible)
                        startPreviewing(true)
                } else {
                    previewWidget.startWithId("")
                }
            }

            Connections {
                target: VideoDevices

                function onDefaultResChanged() {
                    startPreviewing(true)
                }

                function onDefaultFpsChanged() {
                    startPreviewing(true)
                }

                function onDeviceAvailable() {
                    startPreviewing()
                }

                function onDeviceListChanged() {
                    var deviceModel = deviceComboBoxSetting.comboModel
                    var resModel = resolutionComboBoxSetting.comboModel
                    var fpsModel = fpsComboBoxSetting.comboModel

                    var resultList = deviceModel.match(deviceModel.index(0, 0),
                                                    VideoInputDeviceModel.DeviceId,
                                                    VideoDevices.defaultId)
                    deviceComboBoxSetting.modelIndex = resultList.length > 0 ?
                                resultList[0].row : deviceModel.rowCount() ? 0 : -1

                    resultList = resModel.match(resModel.index(0, 0),
                                                VideoFormatResolutionModel.Resolution,
                                                VideoDevices.defaultRes)
                    resolutionComboBoxSetting.modelIndex = resultList.length > 0 ?
                                resultList[0].row : deviceModel.rowCount() ? 0 : -1

                    resultList = fpsModel.match(fpsModel.index(0, 0),
                                                VideoFormatFpsModel.FPS,
                                                VideoDevices.defaultFps)
                    fpsComboBoxSetting.modelIndex = resultList.length > 0 ?
                                resultList[0].row : deviceModel.rowCount() ? 0 : -1
                }
            }

            // video Preview
            Rectangle {
                visible: VideoDevices.listSize !== 0

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: width * previewWidget.invAspectRatio

                Layout.minimumWidth: 200
                Layout.maximumWidth: 515
                Layout.preferredWidth: parent.width
                Layout.bottomMargin: JamiTheme.preferredMarginSize
                Layout.topMargin: JamiTheme.preferredSettingsContentMarginSize

                color: JamiTheme.primaryForegroundColor

                LocalVideo {
                    id: previewWidget

                    anchors.fill: parent
                    flip: flipControl.checked

                    underlayItems: Text {
                        anchors.centerIn: parent
                        font.pointSize: 18
                        font.capitalization: Font.AllUppercase
                        color: "white"
                        text: JamiStrings.noVideo
                    }
                }
            }

            ToggleSwitch {
                id: flipControl

                Layout.fillWidth: true

                labelText: JamiStrings.mirrorLocalVideo
                fontPointSize: JamiTheme.settingsFontSize

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.FlipSelf, checked)
                    CurrentCall.flipSelf = UtilsAdapter.getAppValue(Settings.FlipSelf)
                }
            }

            SettingsComboBox {
                id: deviceComboBoxSetting

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                enabled: VideoDevices.listSize !== 0
                opacity: enabled ? 1.0 : 0.5

                fontPointSize: JamiTheme.settingsFontSize
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

                onActivated: {
                    // TODO: start and stop preview logic in here should be in LRC
                    previewWidget.startWithId("")
                    VideoDevices.setDefaultDevice(
                                filteredDevicesModel.mapToSource(modelIndex))
                    startPreviewing()
                }
            }

            SettingsComboBox {
                id: resolutionComboBoxSetting

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                enabled: VideoDevices.listSize !== 0
                opacity: enabled ? 1.0 : 0.5

                widthOfComboBox: itemWidth
                fontPointSize: JamiTheme.settingsFontSize

                labelText: JamiStrings.resolution
                currentSelectionText: VideoDevices.defaultRes
                tipText: JamiStrings.selectVideoResolution

                comboModel: SortFilterProxyModel {
                    id: filteredResModel
                    sourceModel: SortFilterProxyModel {
                        id: resSourceModel
                        sourceModel: VideoDevices.resSourceModel
                    }
                    filters: ValueFilter {
                        roleName: "Resolution"
                        value: VideoDevices.defaultRes
                        inverted: true
                        enabled: resSourceModel.count > 1
                    }
                }
                role: "Resolution"

                onActivated: VideoDevices.setDefaultDeviceRes(
                                filteredResModel.mapToSource(modelIndex))
            }

            SettingsComboBox {
                id: fpsComboBoxSetting

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                enabled: VideoDevices.listSize !== 0
                opacity: enabled ? 1.0 : 0.5

                widthOfComboBox: itemWidth
                fontPointSize: JamiTheme.settingsFontSize

                tipText: JamiStrings.selectFPS
                labelText: JamiStrings.fps
                currentSelectionText: VideoDevices.defaultFps.toString()
                comboModel: SortFilterProxyModel {
                    id: filteredFpsModel
                    sourceModel: SortFilterProxyModel {
                        id: fpsSourceModel
                        sourceModel: VideoDevices.fpsSourceModel
                    }
                    filters: ValueFilter {
                        roleName: "FPS"
                        value: VideoDevices.defaultFps
                        inverted: true
                        enabled: fpsSourceModel.count > 1
                    }
                }
                role: "FPS"

                onActivated: VideoDevices.setDefaultDeviceFps(
                                filteredFpsModel.mapToSource(modelIndex))
            }

            ToggleSwitch {
                id: hardwareAccelControl

                Layout.fillWidth: true

                labelText: JamiStrings.enableHWAccel
                fontPointSize: JamiTheme.settingsFontSize

                onSwitchToggled: {
                    AvAdapter.setHardwareAcceleration(checked)
                    startPreviewing(true)
                }
            }



            Text {
                visible: VideoDevices.listSize === 0

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.bottomMargin: JamiTheme.preferredSettingsBottomMarginSize

                text: JamiStrings.previewUnavailable
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                color: JamiTheme.primaryForegroundColor

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            /* TO DO
            MaterialButton {
                id: defaultSettings

                TextMetrics{
                    id: defaultSettingsTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: defaultSettings.text
                }

                secondary: true

                Layout.topMargin: JamiTheme.settingsBlockSpacing

                text: JamiStrings.defaultSettings
                preferredWidth: defaultSettingsTextSize.width + 2*JamiTheme.buttontextWizzardPadding
                preferredHeight: JamiTheme.preferredButtonSettingsHeight

            }*/

        }
    }
}