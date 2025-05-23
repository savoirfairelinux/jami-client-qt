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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    property int itemWidth
    spacing: JamiTheme.settingsCategorySpacing

    Text {

        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: parent.width
        text: JamiStrings.openDHTConfig
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap

        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true
    }

    ColumnLayout {
        Layout.fillWidth: true

         SettingSpinBox {
            id: dhtPortUsed

            visible: !root.isSIP

            title: JamiStrings.dhtPortUsed
            itemWidth: root.itemWidth
            bottomValue: 0
            topValue: 65535

            valueField: CurrentAccount.dhtPort
            onNewValue: CurrentAccount.dhtPort = valueField
        }

        ToggleSwitch {
            id: checkAutoConnectOnLocalNetwork
            visible: !root.isSIP

            Layout.fillWidth: true

            labelText: JamiStrings.enablePeerDiscovery
            tooltipText: JamiStrings.tooltipPeerDiscovery

            checked: CurrentAccount.peerDiscovery

            onSwitchToggled: CurrentAccount.peerDiscovery = checked
        }

        ToggleSwitch {
            id: checkBoxEnableProxy

            labelText: JamiStrings.enableProxy
            Layout.fillWidth: true

            checked: CurrentAccount.proxyEnabled

            onSwitchToggled: CurrentAccount.proxyEnabled = checked
        }

        SettingsMaterialTextEdit {
            id: lineEditProxy

            Layout.fillWidth: true

            enabled: checkBoxEnableProxy.checked

            staticText: CurrentAccount.proxyServer

            itemWidth: root.itemWidth
            titleField: JamiStrings.proxyAddress

            onEditFinished: CurrentAccount.proxyServer = dynamicText
        }

        SettingsMaterialTextEdit {
            id: lineEditBootstrap

            Layout.fillWidth: true

            staticText: CurrentAccount.hostname

            itemWidth: root.itemWidth
            titleField: JamiStrings.bootstrap

            onEditFinished: CurrentAccount.hostname = dynamicText
        }
    }
}
