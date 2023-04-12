/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
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
        color: JamiTheme.textColor
        font.kerning: true
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        horizontalAlignment: Text.AlignLeft
        text: JamiStrings.sdpSettingsTitle
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.settingsFontSize
            text: JamiStrings.sdpSettingsSubtitle
            wrapMode: Text.WordWrap
        }
        SettingSpinBox {
            id: audioRTPMinPortSpinBox
            bottomValue: 0
            itemWidth: root.itemWidth
            title: JamiStrings.audioRTPMinPort
            topValue: audioRTPMaxPortSpinBox.valueField - 1
            valueField: CurrentAccount.audioPortMin_Audio

            onNewValue: CurrentAccount.audioPortMin_Audio = valueField
        }
        SettingSpinBox {
            id: audioRTPMaxPortSpinBox
            bottomValue: audioRTPMinPortSpinBox.valueField + 1
            itemWidth: root.itemWidth
            title: JamiStrings.audioRTPMaxPort
            topValue: 65535
            valueField: CurrentAccount.audioPortMax_Audio

            onNewValue: CurrentAccount.audioPortMax_Audio = valueField
        }
        SettingSpinBox {
            id: videoRTPMinPortSpinBox
            bottomValue: 0
            itemWidth: root.itemWidth
            title: JamiStrings.videoRTPMinPort
            topValue: videoRTPMaxPortSpinBox.valueField - 1
            valueField: CurrentAccount.videoPortMin_Video

            onNewValue: CurrentAccount.videoPortMin_Video = valueField
        }
        SettingSpinBox {
            id: videoRTPMaxPortSpinBox
            bottomValue: videoRTPMinPortSpinBox.valueField + 1
            itemWidth: root.itemWidth
            title: JamiStrings.videoRTPMaxPort
            topValue: 65535
            valueField: CurrentAccount.videoPortMax_Video

            onNewValue: CurrentAccount.videoPortMax_Video = valueField
        }
    }
}
