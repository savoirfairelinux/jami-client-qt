/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

JamiComboBox {
    id: root

    // Need to specify audio device correlation
    // i.e. does it concern microphone, output device, input device, etc..
    required property string affectedAudioComponent
    required property var audioDeviceModelType

    accessibilityName: affectedAudioComponent
    accessibilityDescription: JamiStrings.affectedAudioComponentDescription.arg(accessibilityName)
    comboBoxPointSize: JamiTheme.settingsFontSize

    textRole: "DeviceName"
    model: AudioDeviceModel {
        id: audioModel
        lrcInstance: LRCInstance
        type: audioDeviceModelType
    }
    onActivated: {
        AvAdapter.stopAudioMeter();
        if (audioModel.type === AudioDeviceModel.Type.Record)
            AVModel.setInputDevice(currentIndex);
        else if (audioModel.type === AudioDeviceModel.Type.Playback)
            AVModel.setOutputDevice(currentIndex);
        else if (audioModel.type === AudioDeviceModel.Type.Ringtone)
            AVModel.setRingtoneDevice(currentIndex);
        AvAdapter.startAudioMeter();
    }
}
