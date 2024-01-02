/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

    property int itemWidth: 188
    title: JamiStrings.audio

    flickableContent: ColumnLayout {
        id: rootLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsCategoryAudioVideoSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        Component.onCompleted: {
            rootLayout.populateAudioSettings();
            AvAdapter.startAudioMeter();
        }

        Connections {
            target: UtilsAdapter

            function onChangeLanguage() {
                inputAudioModel.reset();
                outputAudioModel.reset();
                ringtoneAudioModel.reset();
            }
        }

        function populateAudioSettings() {
            inputComboBoxSetting.modelIndex = inputComboBoxSetting.comboModel.getCurrentIndex();
            outputComboBoxSetting.modelIndex = outputComboBoxSetting.comboModel.getCurrentIndex();
            ringtoneComboBoxSetting.modelIndex = ringtoneComboBoxSetting.comboModel.getCurrentIndex();
            if (audioManagerComboBoxSetting.comboModel.rowCount() > 0) {
                audioManagerComboBoxSetting.modelIndex = audioManagerComboBoxSetting.comboModel.getCurrentSettingIndex();
            }
            audioManagerComboBoxSetting.visible = audioManagerComboBoxSetting.comboModel.rowCount() > 0;
        }

        SettingsComboBox {
            id: inputComboBoxSetting

            Layout.fillWidth: true

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
                AvAdapter.stopAudioMeter();
                AVModel.setInputDevice(modelIndex);
                AvAdapter.startAudioMeter();
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: JamiTheme.preferredFieldHeight

            Text {
                Layout.fillWidth: true

                text: JamiStrings.soundTest
                elide: Text.ElideRight
                color: JamiTheme.textColor
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            // the audio level meter
            LevelMeter {
                id: audioInputMeter

                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: itemWidth

                indeterminate: false
                from: 0
                to: 100
            }
        }

        SettingsComboBox {
            id: outputComboBoxSetting

            Layout.fillWidth: true

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
                AvAdapter.stopAudioMeter();
                AVModel.setOutputDevice(modelIndex);
                AvAdapter.startAudioMeter();
            }
        }

        SettingsComboBox {
            id: ringtoneComboBoxSetting

            Layout.fillWidth: true

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
                AvAdapter.stopAudioMeter();
                AVModel.setRingtoneDevice(modelIndex);
                AvAdapter.startAudioMeter();
            }
        }

        SettingsComboBox {
            id: audioManagerComboBoxSetting

            Layout.fillWidth: true

            labelText: JamiStrings.audioManager
            fontPointSize: JamiTheme.settingsFontSize
            comboModel: AudioManagerListModel {
                lrcInstance: LRCInstance
            }
            widthOfComboBox: itemWidth
            role: "ID_UTF8"

            onActivated: {
                AvAdapter.stopAudioMeter();
                var selectedAudioManager = comboModel.data(comboModel.index(modelIndex, 0), AudioManagerListModel.AudioManagerID);
                AVModel.setAudioManager(selectedAudioManager);
                AvAdapter.startAudioMeter();
                rootLayout.populateAudioSettings();
            }
        }
    }

    enum Setting {
        AUDIOINPUT,
        AUDIOOUTPUT,
        RINGTONEDEVICE,
        AUDIOMANAGER
    }
}
