/*
 * Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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

    property int itemWidth: 250
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
                rootLayout.resetDeviceModels();
                rootLayout.resetDeviceIndices();
            }
        }

        function resetDeviceModels() {
            inputComboBoxSetting.model.reset();
            outputComboBoxSetting.model.reset();
            ringtoneComboBoxSetting.model.reset();
        }

        function resetDeviceIndices() {
            inputComboBoxSetting.currentIndex = inputComboBoxSetting.model.getCurrentIndex();
            outputComboBoxSetting.currentIndex = outputComboBoxSetting.model.getCurrentIndex();
            ringtoneComboBoxSetting.currentIndex = ringtoneComboBoxSetting.model.getCurrentIndex();
        }

        Connections {
            target: AvAdapter

            function onAudioDeviceListChanged(inputs, outputs) {
                rootLayout.resetDeviceModels();
                rootLayout.resetDeviceIndices();
            }
        }

        function populateAudioSettings() {
            rootLayout.resetDeviceIndices();
            if (audioManagerComboBoxSetting.model.rowCount() > 0) {
                audioManagerComboBoxSetting.currentIndex = audioManagerComboBoxSetting.model.getCurrentSettingIndex();
            }
            audioManagerComboBoxSetting.visible = audioManagerComboBoxSetting.model.rowCount() > 0;
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: JamiTheme.preferredFieldHeight

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                wrapMode: Text.WordWrap
                color: JamiTheme.textColor
                text: JamiStrings.microphone
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            AudioDeviceComboBox {
                id: inputComboBoxSetting

                affectedAudioComponent: JamiStrings.microphone
                audioDeviceModelType: AudioDeviceModel.Type.Record

                width: itemWidth
                height: JamiTheme.preferredFieldHeight
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

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: JamiTheme.preferredFieldHeight

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                wrapMode: Text.WordWrap
                color: JamiTheme.textColor
                text: JamiStrings.outputDevice
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            AudioDeviceComboBox {
                id: outputComboBoxSetting

                width: itemWidth
                height: JamiTheme.preferredFieldHeight

                affectedAudioComponent: JamiStrings.outputDevice
                audioDeviceModelType: AudioDeviceModel.Type.Playback
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: JamiTheme.preferredFieldHeight

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                wrapMode: Text.WordWrap
                color: JamiTheme.textColor
                text: JamiStrings.ringtoneDevice
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            AudioDeviceComboBox {
                id: ringtoneComboBoxSetting

                width: itemWidth
                height: JamiTheme.preferredFieldHeight

                affectedAudioComponent: JamiStrings.ringtoneDevice
                audioDeviceModelType: AudioDeviceModel.Type.Ringtone
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: JamiTheme.preferredFieldHeight

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                wrapMode: Text.WordWrap
                color: JamiTheme.textColor
                text: JamiStrings.audioManager
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            JamiComboBox {
                id: audioManagerComboBoxSetting

                width: itemWidth
                height: JamiTheme.preferredFieldHeight

                accessibilityName: JamiStrings.audioManager
                accessibilityDescription: JamiStrings.audioManagerDescription
                comboBoxPointSize: JamiTheme.settingsFontSize

                textRole: "ID_UTF8"
                model: AudioManagerListModel {
                    lrcInstance: LRCInstance
                }
                onActivated: {
                    AvAdapter.stopAudioMeter();
                    var selectedAudioManager = comboModel.data(comboModel.index(modelIndex, 0), AudioManagerListModel.AudioManagerID);
                    AVModel.setAudioManager(selectedAudioManager);
                    AvAdapter.startAudioMeter();
                    rootLayout.populateAudioSettings();
                }
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
