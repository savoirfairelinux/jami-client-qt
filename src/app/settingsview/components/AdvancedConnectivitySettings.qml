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
    property bool isSIP
    property int itemWidth

    spacing: JamiTheme.settingsCategorySpacing

    Text {
        id: enableAccountTitle
        Layout.alignment: Qt.AlignLeft
        color: JamiTheme.textColor
        font.kerning: true
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        horizontalAlignment: Text.AlignLeft
        text: JamiStrings.connectivity
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    ColumnLayout {
        Layout.fillWidth: true

        ToggleSwitch {
            id: autoRegistrationAfterExpired
            Layout.fillWidth: true
            checked: CurrentAccount.keepAliveEnabled
            labelText: JamiStrings.autoRegistration
            visible: isSIP

            onSwitchToggled: CurrentAccount.keepAliveEnabled = checked
        }
        SettingSpinBox {
            id: registrationExpireTimeoutSpinBox
            bottomValue: 0
            itemWidth: root.itemWidth
            title: JamiStrings.registrationExpirationTime
            topValue: 7 * 24 * 3600
            valueField: CurrentAccount.registrationExpire
            visible: isSIP

            onNewValue: CurrentAccount.registrationExpire = valueField
        }
        SettingSpinBox {
            id: networkInterfaceSpinBox
            bottomValue: 0
            itemWidth: root.itemWidth
            title: JamiStrings.networkInterface
            topValue: 65535
            valueField: CurrentAccount.localPort
            visible: isSIP

            onNewValue: CurrentAccount.localPort = valueField
        }
        ToggleSwitch {
            id: checkBoxUPnP
            Layout.fillWidth: true
            checked: CurrentAccount.upnpEnabled
            labelText: JamiStrings.useUPnP

            onSwitchToggled: CurrentAccount.upnpEnabled = checked
        }
        ToggleSwitch {
            id: checkBoxTurnEnable
            Layout.fillWidth: true
            checked: CurrentAccount.enable_TURN
            labelText: JamiStrings.useTURN

            onSwitchToggled: CurrentAccount.enable_TURN = checked
        }
        SettingsMaterialTextEdit {
            id: lineEditTurnAddress
            Layout.fillWidth: true
            enabled: checkBoxTurnEnable.checked
            itemWidth: root.itemWidth
            staticText: CurrentAccount.server_TURN
            titleField: JamiStrings.turnAdress

            onEditFinished: CurrentAccount.server_TURN = dynamicText
        }
        SettingsMaterialTextEdit {
            id: lineEditTurnUsername
            Layout.fillWidth: true
            enabled: checkBoxTurnEnable.checked
            itemWidth: root.itemWidth
            staticText: CurrentAccount.username_TURN
            titleField: JamiStrings.turnUsername

            onEditFinished: CurrentAccount.username_TURN = dynamicText
        }
        SettingsMaterialTextEdit {
            id: lineEditTurnPassword
            Layout.fillWidth: true
            enabled: checkBoxTurnEnable.checked
            itemWidth: root.itemWidth
            staticText: CurrentAccount.password_TURN
            titleField: JamiStrings.turnPassword

            onEditFinished: CurrentAccount.password_TURN = dynamicText
        }
        SettingsMaterialTextEdit {
            id: lineEditTurnRealmSIP
            Layout.fillWidth: true
            enabled: checkBoxTurnEnable.checked
            itemWidth: root.itemWidth
            staticText: CurrentAccount.realm_TURN
            titleField: JamiStrings.turnRealm

            onEditFinished: CurrentAccount.realm_TURN = dynamicText
        }
        ToggleSwitch {
            id: checkBoxSTUNEnable
            Layout.fillWidth: true
            checked: CurrentAccount.enable_STUN
            labelText: JamiStrings.useSTUN
            visible: isSIP

            onSwitchToggled: CurrentAccount.enable_STUN = checked
        }
        SettingsMaterialTextEdit {
            id: lineEditSTUNAddress
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            enabled: checkBoxSTUNEnable.checked
            itemWidth: root.itemWidth
            staticText: CurrentAccount.server_STUN
            titleField: JamiStrings.stunAdress
            visible: isSIP

            onEditFinished: CurrentAccount.server_STUN = dynamicText
        }
    }
}
