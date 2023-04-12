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
        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: parent.width
        color: JamiTheme.textColor
        font.kerning: true
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        horizontalAlignment: Text.AlignLeft
        text: JamiStrings.openDHTConfig
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    ColumnLayout {
        Layout.fillWidth: true

        ToggleSwitch {
            id: checkAutoConnectOnLocalNetwork
            Layout.fillWidth: true
            checked: CurrentAccount.peerDiscovery
            labelText: JamiStrings.enablePeerDiscovery
            tooltipText: JamiStrings.tooltipPeerDiscovery
            visible: !root.isSIP

            onSwitchToggled: CurrentAccount.peerDiscovery = checked
        }
        ToggleSwitch {
            id: checkBoxEnableProxy
            Layout.fillWidth: true
            checked: CurrentAccount.proxyEnabled
            labelText: JamiStrings.enableProxy

            onSwitchToggled: CurrentAccount.proxyEnabled = checked
        }
        SettingsMaterialTextEdit {
            id: lineEditProxy
            Layout.fillWidth: true
            enabled: checkBoxEnableProxy.checked
            itemWidth: root.itemWidth
            staticText: CurrentAccount.proxyServer
            titleField: JamiStrings.proxyAddress

            onEditFinished: CurrentAccount.proxyServer = dynamicText
        }
        SettingsMaterialTextEdit {
            id: lineEditBootstrap
            Layout.fillWidth: true
            itemWidth: root.itemWidth
            staticText: CurrentAccount.hostname
            titleField: JamiStrings.bootstrap

            onEditFinished: CurrentAccount.hostname = dynamicText
        }
    }
}
