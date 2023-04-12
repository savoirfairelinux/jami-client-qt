/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
        color: JamiTheme.textColor
        font.kerning: true
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        horizontalAlignment: Text.AlignLeft
        text: JamiStrings.media
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    ColumnLayout {
        Layout.fillWidth: true

        ToggleSwitch {
            id: videoCheckBox
            checked: CurrentAccount.videoEnabled_Video
            labelText: JamiStrings.enableVideo

            onSwitchToggled: CurrentAccount.videoEnabled_Video = checked
        }
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            MediaSettings {
                id: videoSettings
                Layout.fillHeight: true
                Layout.fillWidth: true
                enabled: CurrentAccount.videoEnabled_Video
                mediaType: MediaSettings.VIDEO
                opacity: enabled ? 1.0 : 0.5
            }
            MediaSettings {
                id: audioSettings
                Layout.fillHeight: true
                Layout.fillWidth: true
                mediaType: MediaSettings.AUDIO
            }
        }
    }
}
