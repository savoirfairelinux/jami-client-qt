/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls
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
            descText: checked ? JamiStrings.usingProxy + ' ' + CurrentAccount.currentProxyServer : JamiStrings.proxyDisabled
            Layout.fillWidth: true

            checked: CurrentAccount.proxyEnabled

            onSwitchToggled: CurrentAccount.proxyEnabled = checked
        }

        RowLayout {
            id: lineEditProxyServer
            Layout.fillWidth: true

            Text {
                text: JamiStrings.proxyAddress
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                color: JamiTheme.textColor

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }

            NewMaterialTextField {
                id: modalTextEditProxyServer

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: itemWidth// - proxyServerRadioButton.indicator.width - proxyServerRadioButton.spacing - proxyServerRadioButton.horizontalPadding

                placeholderText: JamiStrings.proxyAddress
                textFieldContent: CurrentAccount.proxyServer

                onAccepted: CurrentAccount.proxyServer = modifiedTextFieldContent
            }

            JamiRadioButton {
                id: proxyServerRadioButton
                checked: !CurrentAccount.proxyListEnabled
                leftPadding: 2
                rightPadding: 0
                spacing: 0

                onPressed: CurrentAccount.proxyListEnabled = !CurrentAccount.proxyListEnabled
            }
        }

        RowLayout {
            id: lineEditProxyListURL
            Layout.fillWidth: true

            Text {
                text: JamiStrings.proxyListURL
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }

            ModalTextEdit {
                id: modalTextEditProxyListURL
                TextMetrics {
                    text: modalTextEditProxyListURL.staticText
                    elide: Text.ElideRight
                    elideWidth: itemWidth - 40
                    font.pixelSize: JamiTheme.materialLineEditPixelSize
                }

                visible: true
                focus: visible
                isSettings: true

                Layout.preferredWidth: itemWidth - proxyListURLRadioButton.indicator.width - proxyListURLRadioButton.spacing - proxyListURLRadioButton.horizontalPadding
                staticText: CurrentAccount.dhtProxyListUrl
                placeholderText: JamiStrings.proxyListURL

                onAccepted: CurrentAccount.dhtProxyListUrl = dynamicText
            }
            JamiRadioButton {
                id: proxyListURLRadioButton
                checked: CurrentAccount.proxyListEnabled
                rightPadding: 0
                leftPadding: 2
                spacing: 0

                onPressed: CurrentAccount.proxyListEnabled = !CurrentAccount.proxyListEnabled
            }
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
