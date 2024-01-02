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
    property bool isSIP
    spacing: JamiTheme.settingsCategorySpacing

    Text {
        id: enableAccountTitle

        Layout.alignment: Qt.AlignLeft

        text: JamiStrings.connectivity
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
            id: autoRegistrationAfterExpired

            Layout.fillWidth: true

            visible: isSIP
            labelText: JamiStrings.autoRegistration
            checked: CurrentAccount.keepAliveEnabled
            onSwitchToggled: CurrentAccount.keepAliveEnabled = checked
        }

        SettingSpinBox {
            id: registrationExpireTimeoutSpinBox

            visible: isSIP

            title: JamiStrings.registrationExpirationTime
            itemWidth: root.itemWidth
            bottomValue: 0
            topValue: 7 * 24 * 3600

            valueField: CurrentAccount.registrationExpire
            onNewValue: CurrentAccount.registrationExpire = valueField
        }

        SettingSpinBox {
            id: networkInterfaceSpinBox

            visible: isSIP

            title: JamiStrings.networkInterface
            itemWidth: root.itemWidth
            bottomValue: 0
            topValue: 65535

            valueField: CurrentAccount.localPort
            onNewValue: CurrentAccount.localPort = valueField
        }

        ToggleSwitch {
            id: checkBoxUPnP

            Layout.fillWidth: true

            labelText: JamiStrings.useUPnP
            checked: CurrentAccount.upnpEnabled
            onSwitchToggled: CurrentAccount.upnpEnabled = checked
        }

        ToggleSwitch {
            id: checkBoxTurnEnable

            Layout.fillWidth: true

            labelText: JamiStrings.useTURN
            checked: CurrentAccount.enable_TURN
            onSwitchToggled: CurrentAccount.enable_TURN = checked
        }

        SettingsMaterialTextEdit {
            id: lineEditTurnAddress

            Layout.fillWidth: true

            enabled: checkBoxTurnEnable.checked
            staticText: CurrentAccount.server_TURN
            itemWidth: root.itemWidth
            titleField: JamiStrings.turnAdress

            onEditFinished: CurrentAccount.server_TURN = dynamicText
        }

        SettingsMaterialTextEdit {
            id: lineEditTurnUsername

            Layout.fillWidth: true

            enabled: checkBoxTurnEnable.checked
            staticText: CurrentAccount.username_TURN
            itemWidth: root.itemWidth
            titleField: JamiStrings.turnUsername

            onEditFinished: CurrentAccount.username_TURN = dynamicText
        }

        SettingsMaterialTextEdit {
            id: lineEditTurnPassword

            Layout.fillWidth: true

            enabled: checkBoxTurnEnable.checked
            staticText: CurrentAccount.password_TURN
            itemWidth: root.itemWidth
            titleField: JamiStrings.turnPassword

            onEditFinished: CurrentAccount.password_TURN = dynamicText
            isPassword: true
        }

        SettingsMaterialTextEdit {
            id: lineEditTurnRealmSIP

            Layout.fillWidth: true

            enabled: checkBoxTurnEnable.checked
            staticText: CurrentAccount.realm_TURN
            itemWidth: root.itemWidth
            titleField: JamiStrings.turnRealm

            onEditFinished: CurrentAccount.realm_TURN = dynamicText
        }

        ToggleSwitch {
            id: checkBoxSTUNEnable

            Layout.fillWidth: true

            labelText: JamiStrings.useSTUN
            visible: isSIP
            checked: CurrentAccount.enable_STUN

            onSwitchToggled: CurrentAccount.enable_STUN = checked
        }

        SettingsMaterialTextEdit {
            id: lineEditSTUNAddress

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            enabled: checkBoxSTUNEnable.checked
            visible: isSIP
            staticText: CurrentAccount.server_STUN
            itemWidth: root.itemWidth
            titleField: JamiStrings.stunAdress

            onEditFinished: CurrentAccount.server_STUN = dynamicText
        }
    }
}
