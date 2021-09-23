/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    color: "transparent"

    visible: false

    property int effectiveHeight: visible ? implicitHeight : 0

    ColumnLayout {
        anchors.left: root.left
        anchors.right: root.right
        anchors.bottomMargin: 10

        Label{
            Layout.topMargin: 34
            Layout.alignment: Qt.AlignHCenter
            height: 64
            background: Rectangle {
                Image {
                    anchors.centerIn: parent
                    source: pluginIcon === "" ? JamiResources.plugins_24dp_svg : "file:" + pluginIcon
                    sourceSize: Qt.size(256, 256)
                    height: 64
                    width: 64
                    mipmap: true
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            height: JamiTheme.preferredFieldHeight

            text: "%1\n%2".arg(pluginName).arg(JamiStrings.pluginPreferences)
            font.pointSize: JamiTheme.headerFontSize
            font.kerning: true
            color: JamiTheme.textColor

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                font.pointSize: JamiTheme.headerFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: JamiTheme.textColor

                text: qsTr("General")
                elide: Text.ElideRight
            }

            PushButton {
                Layout.preferredWidth: JamiTheme.preferredFieldHeight
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.alignment: Qt.AlignHCenter

                imageColor: JamiTheme.textColor
                toolTipText: JamiStrings.tipGeneralPluginSettingsDisplay

                preferredSize: 32
                source: pluginGeneralSettingsView.visible ?
                            JamiResources.expand_less_24dp_svg :
                            JamiResources.expand_more_24dp_svg

                onClicked: {
                    pluginGeneralSettingsView.visible = !pluginGeneralSettingsView.visible
                }
            }
        }

        PluginPreferencesListView {
            id: pluginGeneralSettingsView
            visible: false
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            visible: pluginAccountSettingsView.count > 0

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                font.pointSize: JamiTheme.headerFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: JamiTheme.textColor

                text: qsTr("Account")
                elide: Text.ElideRight
            }

            PushButton {
                Layout.preferredWidth: JamiTheme.preferredFieldHeight
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.alignment: Qt.AlignHCenter

                imageColor: JamiTheme.textColor
                toolTipText: JamiStrings.tipAccountPluginSettingsDisplay

                preferredSize: 32
                source: pluginAccountSettingsView.visible ?
                            JamiResources.expand_less_24dp_svg :
                            JamiResources.expand_more_24dp_svg

                onClicked: {
                    pluginAccountSettingsView.visible = !pluginAccountSettingsView.visible
                }
            }
        }

        PluginPreferencesListView {
            id: pluginAccountSettingsView
            visible: false
            Layout.fillWidth: true
            accountId: LRCInstance.currentAccountId
        }

        MaterialButton {
            id: uninstallButton

            Layout.alignment: Qt.AlignCenter

            preferredWidth: JamiTheme.preferredFieldWidth
            preferredHeight: JamiTheme.preferredFieldHeight

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            outlined: true
            visible: pluginPreferencesView.visible
            toolTipText: JamiStrings.pluginUninstallConfirmation
            iconSource: JamiResources.delete_24dp_svg

            text: JamiStrings.uninstall

            onClicked: {
                msgDialog.buttonCallBacks = [function () {
                    pluginPreferencesView.visible = false
                    PluginModel.uninstallPlugin(pluginId)
                    installedPluginsModel.removePlugin(index)
                }]
                msgDialog.openWithParameters(JamiStrings.uninstallPlugin,
                                             JamiStrings.pluginUninstallConfirmation.arg(pluginName))
            }
        }

        Rectangle {
            Layout.bottomMargin: 10
            height: 2
            Layout.fillWidth: true
            color: "transparent"
            border.width: 1
            border.color: JamiTheme.separationLine
        }
    }
}
