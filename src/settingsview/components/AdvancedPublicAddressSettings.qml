/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.14
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.14
import QtQuick.Controls.Styles 1.4
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import Qt.labs.platform 1.1
import "../../commoncomponents"
import "../../constant"

ColumnLayout {
    id: root

    property int itemWidth

    function updatePublicAddressAccountInfos() {
        checkBoxCustomAddressPort.checked = SettingsAdapter.getAccountConfig_PublishedSameAsLocal()
        lineEditSIPCustomAddress.textField = SettingsAdapter.getAccountConfig_PublishedAddress()
        customPortSIPSpinBox.value = SettingsAdapter.getAccountConfig_PublishedPort()
    }

    Text {
        Layout.fillWidth: true

        font.pointSize: JamiTheme.headerFontSize
        font.kerning: true

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter

        text: qsTr("Public Address")
        elide: Text.ElideRight
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        ToggleSwitch {
            id: checkBoxCustomAddressPort

            labelText: qsTr("Use Custom Address/Port")
            fontPointSize: JamiTheme.settingsFontSize

            onSwitchToggled: {
                SettingsAdapter.setUseCustomAddressAndPort(checked)
                lineEditSIPCustomAddress.setEnabled(checked)
                customPortSIPSpinBox.enabled = checked
            }
        }

        SettingsMaterialLineEdit {
            id: lineEditSIPCustomAddress

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            itemWidth: root.itemWidth
            titleField: qsTr("Address")

            onEditFinished: SettingsAdapter.lineEditSIPCustomAddressLineEditTextChanged(textField)
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                Layout.rightMargin: JamiTheme.preferredMarginSize / 2

                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                text: qsTr("Port")
                elide: Text.ElideRight
            }

            SpinBox {
                id: customPortSIPSpinBox

                Layout.preferredWidth: itemWidth
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.alignment: Qt.AlignCenter

                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                from: 0
                to: 65535
                stepSize: 1

                up.indicator.width: (width < 200) ? (width / 5) : 40
                down.indicator.width: (width < 200) ? (width / 5) : 40

                onValueModified: {
                    SettingsAdapter.customPortSIPSpinBoxValueChanged(value)
                }
            }
        }
    }
}