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
    property bool isSIP

    function updateConnectivityAccountInfos() {
        checkAutoConnectOnLocalNetwork.checked = SettingsAdapter.getAccountConfig_PeerDiscovery()
        registrationExpireTimeoutSpinBox.value = SettingsAdapter.getAccountConfig_Registration_Expire()
        networkInterfaceSpinBox.value = SettingsAdapter.getAccountConfig_Localport()
        checkBoxUPnP.checked = SettingsAdapter.getAccountConfig_UpnpEnabled()
        checkBoxTurnEnable.checked = SettingsAdapter.getAccountConfig_TURN_Enabled()
        lineEditTurnAddress.textField = SettingsAdapter.getAccountConfig_TURN_Server()
        lineEditTurnUsername.textField = SettingsAdapter.getAccountConfig_TURN_Username()
        lineEditTurnPassword.textField = SettingsAdapter.getAccountConfig_TURN_Password()
        checkBoxSTUNEnable.checked = SettingsAdapter.getAccountConfig_STUN_Enabled()
        lineEditSTUNAddress.textField = SettingsAdapter.getAccountConfig_STUN_Server()
        lineEditTurnRealmSIP.textField = SettingsAdapter.getAccountConfig_TURN_Realm()
        lineEditTurnRealmSIP.setEnabled(SettingsAdapter.getAccountConfig_TURN_Enabled())
        lineEditSTUNAddress.setEnabled(SettingsAdapter.getAccountConfig_STUN_Enabled())

    }

    ElidedTextLabel {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        eText: qsTr("Connectivity")
        fontSize: JamiTheme.headerFontSize
        maxWidth: width
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        ToggleSwitch {
            id: checkAutoConnectOnLocalNetwork
            visible: !root.isSIP

            Layout.fillWidth: true

            labelText: qsTr("Auto Connect On Local Network")
            fontPointSize: JamiTheme.settingsFontSize

            onSwitchToggled: {
                SettingsAdapter.setAutoConnectOnLocalNetwork(checked)
            }
        }

        RowLayout{
            visible: isSIP
            
            Text {
                Layout.fillWidth: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                text: qsTr("Registration Expire Timeout (seconds)")
                elide: Text.ElideRight
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                verticalAlignment: Text.AlignVCenter
            }

            SpinBox {
                id: registrationExpireTimeoutSpinBox

                Layout.preferredWidth: itemWidth
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.alignment: Qt.AlignCenter

                font.pointSize: JamiTheme.buttonFontSize
                font.kerning: true

                from: 0
                to: 3000
                stepSize: 1

                up.indicator.width: (width < 200) ? (width / 5) : 40
                down.indicator.width: (width < 200) ? (width / 5) : 40

                onValueModified: {
                   SettingsAdapter.registrationTimeoutSpinBoxValueChanged(value)
                }
            }
        }

        RowLayout{
            visible: isSIP

            Text {
                Layout.fillWidth: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                text: qsTr("Newtwork interface")
                elide: Text.ElideRight
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                verticalAlignment: Text.AlignVCenter
            }

            SpinBox {
                id: networkInterfaceSpinBox

                Layout.preferredWidth: itemWidth
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.alignment: Qt.AlignCenter

                font.pointSize: JamiTheme.buttonFontSize
                font.kerning: true

                from: 0
                to: 65536
                stepSize: 1

                up.indicator.width: (width < 200) ? (width / 5) : 40
                down.indicator.width: (width < 200) ? (width / 5) : 40

                onValueModified: {
                   SettingsAdapter.networkInterfaceSpinBoxValueChanged(value)
                }
            }
        }

        ToggleSwitch {
            id: checkBoxUPnP

            Layout.fillWidth: true

            labelText: qsTr("Use UPnP")
            fontPointSize: JamiTheme.settingsFontSize

            onSwitchToggled: SettingsAdapter.setUseUPnP(checked)
        }

        ToggleSwitch {
            id: checkBoxTurnEnable

            Layout.fillWidth: true

            labelText: qsTr("Use TURN")
            fontPointSize: JamiTheme.settingsFontSize

            onSwitchToggled: {
                SettingsAdapter.setUseTURN(checked)
                if (isSIP) {
                    lineEditTurnAddress.setEnabled(checked)
                    lineEditTurnUsername.setEnabled(checked)
                    lineEditTurnPassword.setEnabled(checked)
                    lineEditTurnRealmSIP.setEnabled(checked)
                }
            }
        }

        SettingsMaterialLineEdit {
            id: lineEditTurnAddress

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            itemWidth: root.itemWidth
            titleField: qsTr("TURN Address")
            onEditFinished: SettingsAdapter.setTURNAddress(textField)
        }

        SettingsMaterialLineEdit {
            id: lineEditTurnUsername

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            itemWidth: root.itemWidth
            titleField: qsTr("TURN Username")
            onEditFinished: SettingsAdapter.setTURNUsername(textField)
        }

        SettingsMaterialLineEdit {
            id: lineEditTurnPassword

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            itemWidth: root.itemWidth
            titleField: qsTr("TURN Password")
            onEditFinished: SettingsAdapter.setTURNPassword(textField)
        }

        SettingsMaterialLineEdit {
            id: lineEditTurnRealmSIP
            visible: isSIP

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            itemWidth: root.itemWidth
            titleField: qsTr("TURN Realm")
            onEditFinished: SettingsAdapter.setTURNRealm(textField)
        }

        ToggleSwitch {
            id: checkBoxSTUNEnable

            Layout.fillWidth: true

            labelText: qsTr("Use STUN")
            fontPointSize: JamiTheme.settingsFontSize

            onSwitchToggled: {
                SettingsAdapter.setUseSTUN(checked)
                lineEditSTUNAddress.enabled = checked
            }
        }

        SettingsMaterialLineEdit {
            id: lineEditSTUNAddress

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            itemWidth: root.itemWidth
            titleField: qsTr("STUN Address")
            onEditFinished: SettingsAdapter.setSTUNAddress(textField)
        }
    }
}