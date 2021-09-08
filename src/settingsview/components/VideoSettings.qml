/*
 * Copyright (C) 2020 by Savoir-faire Linux
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ColumnLayout {
    id: root

    property real aspectRatio: 0.75
    property bool previewAvailable: false
    property int itemWidth

    function startPreviewing(force = false) {
        if (root.visible) {
            AvAdapter.startPreviewing(force)
            previewAvailable = true
        }
    }

    function updatePreviewRatio() {
        var resolution = CurrentDevice.videoDefaultDeviceRes
        if (resolution.length !== 0) {
            var resVec = resolution.split("x")
            var ratio = resVec[1] / resVec[0]
            if (ratio) {
                aspectRatio = ratio
            } else {
                console.error("Could not scale recording video preview")
            }
        }

    }

    onVisibleChanged: {
        if (visible) {
            hardwareAccelControl.checked = AvAdapter.getHardwareAcceleration()
            updatePreviewRatio()
            if (previewWidget.visible)
                startPreviewing(true)
        }
    }

    Connections {
        target: CurrentDevice

        function onVideoDefaultDeviceResChanged() {
            updatePreviewRatio()
        }

        function onVideoDeviceAvailable() {
            startPreviewing()
        }

        function onVideoDeviceListChanged() {
            var deviceModel = deviceComboBoxSetting.comboModel
            var resModel = resolutionComboBoxSetting.comboModel
            var fpsModel = fpsComboBoxSetting.comboModel

            var resultList = deviceModel.match(deviceModel.index(0, 0),
                                               VideoInputDeviceModel.DeviceId,
                                               CurrentDevice.videoDefaultDeviceId)
            deviceComboBoxSetting.modelIndex = resultList.length > 0 ?
                        resultList[0].row : deviceModel.rowCount() ? 0 : -1

            resultList = resModel.match(resModel.index(0, 0),
                                        VideoFormatResolutionModel.Resolution,
                                        CurrentDevice.videoDefaultDeviceRes)
            resolutionComboBoxSetting.modelIndex = resultList.length > 0 ?
                        resultList[0].row : deviceModel.rowCount() ? 0 : -1

            resultList = fpsModel.match(fpsModel.index(0, 0),
                                        VideoFormatFpsModel.FPS,
                                        CurrentDevice.videoDefaultDeviceFps)
            fpsComboBoxSetting.modelIndex = resultList.length > 0 ?
                        resultList[0].row : deviceModel.rowCount() ? 0 : -1
        }
    }

    ElidedTextLabel {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        eText: JamiStrings.video
        fontSize: JamiTheme.headerFontSize
        maxWidth: itemWidth * 2
    }

    SettingsComboBox {
        id: deviceComboBoxSetting

        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.leftMargin: JamiTheme.preferredMarginSize

        enabled: CurrentDevice.videoDeviceListSize !== 0

        fontPointSize: JamiTheme.settingsFontSize
        widthOfComboBox: itemWidth

        labelText: JamiStrings.device
        tipText: JamiStrings.selectVideoDevice
        placeholderText: JamiStrings.noVideoDevice
        currentSelectionText: CurrentDevice.videoDefaultDeviceName
        comboModel: CurrentDevice.videoDeviceFilterModel()
        role: "DeviceName"

        onActivated: {
            // TODO: start and stop preview logic in here should be in LRC
            AvAdapter.stopPreviewing()
            CurrentDevice.setVideoDefaultDevice(modelIndex)
            startPreviewing()
        }
    }

    SettingsComboBox {
        id: resolutionComboBoxSetting

        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.leftMargin: JamiTheme.preferredMarginSize

        enabled: CurrentDevice.videoDeviceListSize !== 0

        widthOfComboBox: itemWidth
        fontPointSize: JamiTheme.settingsFontSize

        labelText: JamiStrings.resolution
        currentSelectionText: CurrentDevice.videoDefaultDeviceRes
        tipText: JamiStrings.selectVideoResolution
        comboModel: CurrentDevice.videoResFilterModel()
        role: "Resolution"

        onActivated: CurrentDevice.setVideoDefaultDeviceRes(modelIndex)
    }

    SettingsComboBox {
        id: fpsComboBoxSetting

        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.leftMargin: JamiTheme.preferredMarginSize

        enabled: CurrentDevice.videoDeviceListSize !== 0

        widthOfComboBox: itemWidth
        fontPointSize: JamiTheme.settingsFontSize

        tipText: JamiStrings.selectFPS
        labelText: JamiStrings.fps
        currentSelectionText: CurrentDevice.videoDefaultDeviceFps.toString()
        comboModel: CurrentDevice.videoFpsFilterModel()
        role: "FPS"

        onActivated: CurrentDevice.setVideoDefaultDeviceFps(modelIndex)
    }

    ToggleSwitch {
        id: hardwareAccelControl

        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        labelText: JamiStrings.enableHWAccel
        fontPointSize: JamiTheme.settingsFontSize

        onSwitchToggled: {
            AvAdapter.setHardwareAcceleration(checked)
            startPreviewing(true)
        }
    }

    // video Preview
    Rectangle {
        id: rectBox

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: width * aspectRatio

        Layout.minimumWidth: 200
        Layout.maximumWidth: 400
        Layout.preferredWidth: itemWidth * 2
        Layout.bottomMargin: JamiTheme.preferredMarginSize

        color: JamiTheme.primaryForegroundColor

        PreviewRenderer {
            id: previewWidget

            anchors.fill: rectBox

            lrcInstance: LRCInstance

            visible: CurrentDevice.videoDeviceListSize !== 0
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: rectBox
            }
        }
    }

    Label {
        // TODO: proper use of previewAvailable
        visible: !previewAvailable

        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.bottomMargin: JamiTheme.preferredMarginSize

        text: JamiStrings.previewUnavailable
        font.pointSize: JamiTheme.settingsFontSize
        font.kerning: true

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
