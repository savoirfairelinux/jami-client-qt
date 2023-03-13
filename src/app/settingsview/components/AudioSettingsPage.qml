/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
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
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
Rectangle {
    id: root

    property int contentWidth: currentAccountEnableColumnLayout.width
    property int preferredHeight: currentAccountEnableColumnLayout.implicitHeight
    property int preferredColumnWidth : Math.min(root.width / 2 - 50, 350)
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)
    property int itemWidth: 200

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: currentAccountEnableColumnLayout

        anchors.left: root.left
        anchors.top: root.top
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2
        anchors.topMargin: JamiTheme.wizardViewPageBackButtonSize

        enum Setting {
            AUDIOINPUT,
            AUDIOOUTPUT,
            RINGTONEDEVICE,
            AUDIOMANAGER
        }

        Connections {
            target: UtilsAdapter

            function onChangeLanguage() {
                inputAudioModel.reset()
                outputAudioModel.reset()
                ringtoneAudioModel.reset()
            }
        }

        function populateAudioSettings() {
            inputComboBoxSetting.modelIndex = inputComboBoxSetting.comboModel.getCurrentIndex()
            outputComboBoxSetting.modelIndex = outputComboBoxSetting.comboModel.getCurrentIndex()
            ringtoneComboBoxSetting.modelIndex = ringtoneComboBoxSetting.comboModel.getCurrentIndex()
            if(audioManagerComboBoxSetting.comboModel.rowCount() > 0) {
                audioManagerComboBoxSetting.modelIndex =
                        audioManagerComboBoxSetting.comboModel.getCurrentSettingIndex()
            }
            audioManagerComboBoxSetting.visible = audioManagerComboBoxSetting.comboModel.rowCount() > 0
        }

        ElidedTextLabel {
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            eText: JamiStrings.audio
            fontSize: JamiTheme.headerFontSize
            maxWidth: width
        }

        SettingsComboBox {
            id: inputComboBoxSetting

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.leftMargin: JamiTheme.preferredMarginSize

            labelText: JamiStrings.microphone
            fontPointSize: JamiTheme.settingsFontSize
            comboModel: AudioDeviceModel {
                id: inputAudioModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Record
            }
            widthOfComboBox: itemWidth
            tipText: JamiStrings.selectAudioInputDevice
            role: "DeviceName"

            onActivated: {
                AvAdapter.stopAudioMeter()
                AVModel.setInputDevice(modelIndex)
                AvAdapter.startAudioMeter()
            }
        }

        // the audio level meter
        LevelMeter {
            id: audioInputMeter

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: itemWidth * 1.5
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            indeterminate: false
            from: 0
            to: 100
        }

        SettingsComboBox {
            id: outputComboBoxSetting

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.leftMargin: JamiTheme.preferredMarginSize

            labelText: JamiStrings.outputDevice
            fontPointSize: JamiTheme.settingsFontSize
            comboModel: AudioDeviceModel {
                id: outputAudioModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Playback
            }
            widthOfComboBox: itemWidth
            tipText: JamiStrings.selectAudioOutputDevice
            role: "DeviceName"

            onActivated: {
                AvAdapter.stopAudioMeter()
                AVModel.setOutputDevice(modelIndex)
                AvAdapter.startAudioMeter()
            }
        }

        SettingsComboBox {
            id: ringtoneComboBoxSetting

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.leftMargin: JamiTheme.preferredMarginSize

            labelText: JamiStrings.ringtoneDevice
            fontPointSize: JamiTheme.settingsFontSize
            comboModel: AudioDeviceModel {
                id: ringtoneAudioModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Ringtone
            }
            widthOfComboBox: itemWidth
            tipText: JamiStrings.selectRingtoneOutputDevice
            role: "DeviceName"

            onActivated: {
                AvAdapter.stopAudioMeter()
                AVModel.setRingtoneDevice(modelIndex)
                AvAdapter.startAudioMeter()
            }
        }

        SettingsComboBox {
            id: audioManagerComboBoxSetting

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.leftMargin: JamiTheme.preferredMarginSize

            labelText: JamiStrings.audioManager
            fontPointSize: JamiTheme.settingsFontSize
            comboModel: AudioManagerListModel {
                lrcInstance: LRCInstance
            }
            widthOfComboBox: itemWidth
            role: "ID_UTF8"

            onActivated: {
                AvAdapter.stopAudioMeter()
                var selectedAudioManager = comboModel.data(
                            comboModel.index(modelIndex, 0), AudioManagerListModel.AudioManagerID)
                AVModel.setAudioManager(selectedAudioManager)
                AvAdapter.startAudioMeter()
                populateAudioSettings()
            }
        }
    }
}
