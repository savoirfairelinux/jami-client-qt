/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    property int itemWidth
    spacing: JamiTheme.settingsCategorySpacing + 2

    Text {

        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView, root.width - 2 * JamiTheme.preferredSettingsMarginSize)

        text: JamiStrings.sdpSettingsTitle
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap

        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: JamiStrings.sdpSettingsSubtitle
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true
            wrapMode: Text.WordWrap
            color: JamiTheme.textColor
        }

        SettingSpinBox {
            id: audioRTPMinPortSpinBox

            title: JamiStrings.audioRTPMinPort
            itemWidth: root.itemWidth
            bottomValue: 0
            topValue: audioRTPMaxPortSpinBox.valueField - 1

            valueField: CurrentAccount.audioPortMin_Audio

            onNewValue: CurrentAccount.audioPortMin_Audio = valueField
        }

        SettingSpinBox {
            id: audioRTPMaxPortSpinBox

            title: JamiStrings.audioRTPMaxPort
            itemWidth: root.itemWidth
            bottomValue: audioRTPMinPortSpinBox.valueField + 1
            topValue: 65535

            valueField: CurrentAccount.audioPortMax_Audio

            onNewValue: CurrentAccount.audioPortMax_Audio = valueField
        }

        SettingSpinBox {
            id: videoRTPMinPortSpinBox

            title: JamiStrings.videoRTPMinPort
            itemWidth: root.itemWidth
            bottomValue: 0
            topValue: videoRTPMaxPortSpinBox.valueField - 1

            valueField: CurrentAccount.videoPortMin_Video

            onNewValue: CurrentAccount.videoPortMin_Video = valueField
        }

        SettingSpinBox {
            id: videoRTPMaxPortSpinBox

            title: JamiStrings.videoRTPMaxPort
            itemWidth: root.itemWidth
            bottomValue: videoRTPMinPortSpinBox.valueField + 1
            topValue: 65535

            valueField: CurrentAccount.videoPortMax_Video

            onNewValue: CurrentAccount.videoPortMax_Video = valueField
        }
    }
}
