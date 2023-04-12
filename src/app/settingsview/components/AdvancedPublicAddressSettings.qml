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
        color: JamiTheme.textColor
        elide: Text.ElideRight
        font.kerning: true
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        horizontalAlignment: Text.AlignLeft
        text: JamiStrings.publicAddress
        verticalAlignment: Text.AlignVCenter
    }
    ColumnLayout {
        Layout.fillWidth: true

        ToggleSwitch {
            id: checkBoxAllowIPAutoRewrite
            checked: CurrentAccount.allowIPAutoRewrite
            labelText: JamiStrings.allowIPAutoRewrite

            onSwitchToggled: CurrentAccount.allowIPAutoRewrite = checked
        }
        ToggleSwitch {
            id: checkBoxCustomAddressPort
            checked: CurrentAccount.publishedSameAsLocal
            labelText: JamiStrings.useCustomAddress
            visible: !checkBoxAllowIPAutoRewrite.checked

            onSwitchToggled: CurrentAccount.publishedSameAsLocal = checked
        }
        SettingsMaterialTextEdit {
            id: lineEditSIPCustomAddress
            Layout.fillWidth: true
            enabled: checkBoxCustomAddressPort.checked
            itemWidth: root.itemWidth
            staticText: CurrentAccount.publishedAddress
            titleField: JamiStrings.address
            visible: !checkBoxAllowIPAutoRewrite.checked

            onEditFinished: CurrentAccount.publishedAddress = dynamicText
        }
        SettingSpinBox {
            id: customPortSIPSpinBox
            bottomValue: 0
            enabled: checkBoxCustomAddressPort.checked
            itemWidth: root.itemWidth
            title: JamiStrings.port
            topValue: 65535
            valueField: CurrentAccount.publishedPort
            visible: !checkBoxAllowIPAutoRewrite.checked

            onNewValue: CurrentAccount.publishedPort = valueField
        }
    }
}
