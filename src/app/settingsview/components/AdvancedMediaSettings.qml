/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root
    spacing: JamiTheme.settingsCategorySpacing

    Text {

        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

        text: JamiStrings.media
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap

        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true
    }

    ColumnLayout {
        Layout.fillWidth: true

        ToggleSwitch {
            id: videoCheckBox

            labelText: JamiStrings.enableVideo

            checked: CurrentAccount.videoEnabled_Video

            onSwitchToggled: CurrentAccount.videoEnabled_Video = checked
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MediaSettings {
                id: videoSettings

                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: CurrentAccount.videoEnabled_Video

                opacity: enabled ? 1.0 : 0.5

                mediaType: MediaSettings.VIDEO
            }

            MediaSettings {
                id: audioSettings

                Layout.fillWidth: true
                Layout.fillHeight: true

                mediaType: MediaSettings.AUDIO
            }
        }
    }
}
