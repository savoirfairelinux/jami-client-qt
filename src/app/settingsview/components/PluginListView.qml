/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Sanots  <aline.gondimsantos@savoirfairelinux.com>
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
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    property alias count: pluginList.count
    property string activePlugin: ""

    visible: false
    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        anchors.left: root.left
        anchors.right: root.right
        anchors.bottomMargin: 20
        RowLayout {
            Layout.preferredHeight: JamiTheme.settingsHeaderpreferredHeight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: 25

                text: JamiStrings.installed
                font.pointSize: JamiTheme.headerFontSize
                font.kerning: true
                color: JamiTheme.textColor

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
            HeaderToggleSwitch {
                labelText: "auto update"
                tooltipText: "auto update"
                checked: true
                onSwitchToggled: {
                }
            }
            MaterialButton {
                id: disableAll

                TextMetrics {
                    id: disableTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: JamiStrings.disableAll
                }
                secondary: true
                preferredWidth: disableTextSize.width + JamiTheme.buttontextWizzardPadding
                text: JamiStrings.disableAll
                fontSize: JamiTheme.wizardViewButtonFontPixelSize
                onClicked: PluginListModel.disableAllPlugins()
            }
        }
        ListView {
            id: pluginList
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            Layout.topMargin: 10
            clip: true

            model: PluginListModel

            delegate: PluginItemDelegate {
                id: pluginItemDelegate

                width: pluginList.width
                implicitHeight: 50

                pluginName: PluginName
                pluginId: PluginId
                pluginIcon: PluginIcon
                isLoaded: IsLoaded
                activeId: root.activePlugin

                background: Rectangle {
                    anchors.fill: parent
                    color: "transpa rent"
                }

                onSettingsClicked: {
                    root.activePlugin = root.activePlugin === pluginId ? "" : pluginId;
                }
            }
        }
    }
}
