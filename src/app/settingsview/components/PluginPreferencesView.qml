/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos   <aline.gondimsantos@savoirfairelinux.com>
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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    color: "transparent"
    visible: false

    ColumnLayout {
        anchors.bottomMargin: 10
        anchors.left: root.left
        anchors.right: root.right

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 34
            height: 64

            background: Rectangle {
                Image {
                    anchors.centerIn: parent
                    height: 64
                    mipmap: true
                    source: pluginIcon === "" ? JamiResources.plugins_24dp_svg : "file:" + pluginIcon
                    sourceSize: Qt.size(256, 256)
                    width: 64
                }
            }
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.headerFontSize
            height: JamiTheme.preferredFieldHeight
            horizontalAlignment: Text.AlignHCenter
            text: "%1\n%2".arg(pluginName).arg(JamiStrings.pluginPreferences)
            verticalAlignment: Text.AlignVCenter
        }
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                color: JamiTheme.textColor
                elide: Text.ElideRight
                font.kerning: true
                font.pointSize: JamiTheme.headerFontSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.generalSettingsTitle
                verticalAlignment: Text.AlignVCenter
            }
            PushButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.preferredWidth: JamiTheme.preferredFieldHeight
                imageColor: JamiTheme.textColor
                preferredSize: 32
                source: pluginGeneralSettingsView.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
                toolTipText: JamiStrings.tipGeneralPluginSettingsDisplay

                onClicked: {
                    pluginGeneralSettingsView.visible = !pluginGeneralSettingsView.visible;
                }
            }
        }
        PluginPreferencesListView {
            id: pluginGeneralSettingsView
            Layout.fillWidth: true
            visible: false
        }
        RowLayout {
            Layout.fillWidth: true
            visible: pluginAccountSettingsView.count > 0

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                color: JamiTheme.textColor
                elide: Text.ElideRight
                font.kerning: true
                font.pointSize: JamiTheme.headerFontSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.accountSettingsMenuTitle
                verticalAlignment: Text.AlignVCenter
            }
            PushButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.preferredWidth: JamiTheme.preferredFieldHeight
                imageColor: JamiTheme.textColor
                preferredSize: 32
                source: pluginAccountSettingsView.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
                toolTipText: JamiStrings.tipAccountPluginSettingsDisplay

                onClicked: {
                    pluginAccountSettingsView.visible = !pluginAccountSettingsView.visible;
                }
            }
        }
        PluginPreferencesListView {
            id: pluginAccountSettingsView
            Layout.fillWidth: true
            accountId: LRCInstance.currentAccountId
            visible: false
        }
        MaterialButton {
            id: uninstallButton
            Layout.alignment: Qt.AlignCenter
            buttontextHeightMargin: JamiTheme.buttontextHeightMargin
            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            iconSource: JamiResources.delete_24dp_svg
            preferredWidth: JamiTheme.preferredFieldWidth
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            text: JamiStrings.uninstall
            toolTipText: JamiStrings.pluginUninstallConfirmation.arg(pluginName)

            onClicked: viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                    "title": JamiStrings.uninstallPlugin,
                    "infoText": JamiStrings.pluginUninstallConfirmation.arg(pluginName),
                    "buttonTitles": [JamiStrings.optionOk, JamiStrings.optionCancel],
                    "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue, SimpleMessageDialog.ButtonStyle.TintedBlack],
                    "buttonCallBacks": [function () {
                            pluginPreferencesView.visible = false;
                            PluginModel.uninstallPlugin(pluginId);
                            installedPluginsModel.removePlugin(index);
                        }]
                })
        }
        Rectangle {
            Layout.bottomMargin: 10
            Layout.fillWidth: true
            border.color: JamiTheme.separationLine
            border.width: 1
            color: "transparent"
            height: 2
        }
    }
}
