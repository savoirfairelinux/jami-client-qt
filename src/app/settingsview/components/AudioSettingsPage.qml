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

SettingsPageBase {
    id: root
    enum Setting {
        AUDIOINPUT,
        AUDIOOUTPUT,
        RINGTONEDEVICE,
        AUDIOMANAGER
    }

    property int itemWidth: 188

    title: JamiStrings.audio

    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsCategoryAudioVideoSpacing
        width: contentFlickableWidth

        function populateAudioSettings() {
            inputComboBoxSetting.modelIndex = inputComboBoxSetting.comboModel.getCurrentIndex();
            outputComboBoxSetting.modelIndex = outputComboBoxSetting.comboModel.getCurrentIndex();
            ringtoneComboBoxSetting.modelIndex = ringtoneComboBoxSetting.comboModel.getCurrentIndex();
            if (audioManagerComboBoxSetting.comboModel.rowCount() > 0) {
                audioManagerComboBoxSetting.modelIndex = audioManagerComboBoxSetting.comboModel.getCurrentSettingIndex();
            }
            audioManagerComboBoxSetting.visible = audioManagerComboBoxSetting.comboModel.rowCount() > 0;
        }

        Connections {
            target: UtilsAdapter

            function onChangeLanguage() {
                inputAudioModel.reset();
                outputAudioModel.reset();
                ringtoneAudioModel.reset();
            }
        }
        SettingsComboBox {
            id: inputComboBoxSetting
            Layout.fillWidth: true
            fontPointSize: JamiTheme.settingsFontSize
            labelText: JamiStrings.microphone
            role: "DeviceName"
            tipText: JamiStrings.selectAudioInputDevice
            widthOfComboBox: itemWidth

            onActivated: {
                AvAdapter.stopAudioMeter();
                AVModel.setInputDevice(modelIndex);
                AvAdapter.startAudioMeter();
            }

            comboModel: AudioDeviceModel {
                id: inputAudioModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Record
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: JamiTheme.preferredFieldHeight

            Text {
                Layout.fillWidth: true
                color: JamiTheme.textColor
                elide: Text.ElideRight
                font.kerning: true
                font.pointSize: JamiTheme.settingsFontSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.soundTest
                verticalAlignment: Text.AlignVCenter
            }

            // the audio level meter
            LevelMeter {
                id: audioInputMeter
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: itemWidth
                from: 0
                indeterminate: false
                to: 100
            }
        }
        SettingsComboBox {
            id: outputComboBoxSetting
            Layout.fillWidth: true
            fontPointSize: JamiTheme.settingsFontSize
            labelText: JamiStrings.outputDevice
            role: "DeviceName"
            tipText: JamiStrings.selectAudioOutputDevice
            widthOfComboBox: itemWidth

            onActivated: {
                AvAdapter.stopAudioMeter();
                AVModel.setOutputDevice(modelIndex);
                AvAdapter.startAudioMeter();
            }

            comboModel: AudioDeviceModel {
                id: outputAudioModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Playback
            }
        }
        SettingsComboBox {
            id: ringtoneComboBoxSetting
            Layout.fillWidth: true
            fontPointSize: JamiTheme.settingsFontSize
            labelText: JamiStrings.ringtoneDevice
            role: "DeviceName"
            tipText: JamiStrings.selectRingtoneOutputDevice
            widthOfComboBox: itemWidth

            onActivated: {
                AvAdapter.stopAudioMeter();
                AVModel.setRingtoneDevice(modelIndex);
                AvAdapter.startAudioMeter();
            }

            comboModel: AudioDeviceModel {
                id: ringtoneAudioModel
                lrcInstance: LRCInstance
                type: AudioDeviceModel.Type.Ringtone
            }
        }
        SettingsComboBox {
            id: audioManagerComboBoxSetting
            Layout.fillWidth: true
            fontPointSize: JamiTheme.settingsFontSize
            labelText: JamiStrings.audioManager
            role: "ID_UTF8"
            widthOfComboBox: itemWidth

            Component.onCompleted: currentAccountEnableColumnLayout.populateAudioSettings()
            onActivated: {
                AvAdapter.stopAudioMeter();
                var selectedAudioManager = comboModel.data(comboModel.index(modelIndex, 0), AudioManagerListModel.AudioManagerID);
                AVModel.setAudioManager(selectedAudioManager);
                AvAdapter.startAudioMeter();
                currentAccountEnableColumnLayout.populateAudioSettings();
            }

            comboModel: AudioManagerListModel {
                lrcInstance: LRCInstance
            }
        }
    }
}
