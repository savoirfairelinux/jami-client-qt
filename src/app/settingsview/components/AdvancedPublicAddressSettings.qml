/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    property int itemWidth
    spacing: JamiTheme.settingsCategorySpacing

    Text {
        Layout.fillWidth: true

        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter

        text: JamiStrings.publicAddress
        color: JamiTheme.textColor
        elide: Text.ElideRight
    }

    ColumnLayout {
        Layout.fillWidth: true

        ToggleSwitch {
            id: checkBoxAllowIPAutoRewrite

            labelText: JamiStrings.allowIPAutoRewrite

            checked: CurrentAccount.allowIPAutoRewrite

            onSwitchToggled: CurrentAccount.allowIPAutoRewrite = checked
        }

        ToggleSwitch {
            id: checkBoxCustomAddressPort

            labelText: JamiStrings.useCustomAddress

            visible: !checkBoxAllowIPAutoRewrite.checked
            checked: CurrentAccount.publishedSameAsLocal

            onSwitchToggled: CurrentAccount.publishedSameAsLocal = checked
        }

        SettingsMaterialTextEdit {
            id: lineEditSIPCustomAddress

            Layout.fillWidth: true

            visible: !checkBoxAllowIPAutoRewrite.checked
            enabled: checkBoxCustomAddressPort.checked

            itemWidth: root.itemWidth
            titleField: JamiStrings.address

            staticText: CurrentAccount.publishedAddress

            onEditFinished: CurrentAccount.publishedAddress = dynamicText
        }

        SettingSpinBox {
            id: customPortSIPSpinBox

            title: JamiStrings.port
            itemWidth: root.itemWidth
            bottomValue: 0
            topValue: 65535

            visible: !checkBoxAllowIPAutoRewrite.checked
            enabled: checkBoxCustomAddressPort.checked

            valueField: CurrentAccount.publishedPort

            onNewValue: CurrentAccount.publishedPort = valueField
        }
    }
}
