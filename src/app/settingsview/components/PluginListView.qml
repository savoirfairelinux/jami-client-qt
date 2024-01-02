/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
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
    property int count: pluginLoader.item !== undefined ? pluginLoader.item.count : 0
    property bool isAutoUpdate: PluginAdapter.isAutoUpdaterEnabled()
    property int currentIndex: {
        if (pluginLoader.item !== undefined) {
            return -1;
        } else {
            if (pluginListView.currentIndex === 0) {
                return -1;
            }
            return pluginListView.currentIndex;
        }
    }
    visible: count
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
                text: JamiStrings.installed
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
                color: JamiTheme.textColor

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignBottom
            }
            HeaderToggleSwitch {
                labelText: "auto update"
                tooltipText: "auto update"
                checked: isAutoUpdate
                onSwitchToggled: {
                    isAutoUpdate = !isAutoUpdate;
                    PluginAdapter.setAutoUpdate(isAutoUpdate);
                }
            }
            MaterialButton {
                id: disableAll
                radius: JamiTheme.chatViewHeaderButtonRadius
                buttontextHeightMargin: 10.0
                TextMetrics {
                    id: disableTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: JamiStrings.disableAll
                }
                secondary: true
                preferredWidth: disableTextSize.width + 2
                text: JamiStrings.disableAll
                fontSize: JamiTheme.wizardViewButtonFontPixelSize
                onClicked: PluginListModel.disableAllPlugins()
            }
        }
        Loader {
            id: pluginLoader
            Layout.fillWidth: true
            Layout.preferredHeight: pluginLoader.item.contentHeight
            Layout.topMargin: 10
            active: true
            asynchronous: true

            sourceComponent: ListView {
                id: pluginListView
                clip: true
                model: PluginListModel
                spacing: 10
                currentIndex: -1
                onCurrentIndexChanged: {
                    root.currentIndex = currentIndex;
                }
                delegate: PluginItemDelegate {
                    id: pluginItemDelegate
                    width: pluginLoader.width
                    implicitHeight: 50

                    pluginName: PluginName
                    pluginPath: PluginId
                    pluginIcon: PluginIcon
                    pluginStatus: Status
                    isLoaded: IsLoaded
                    pluginId: Id
                    HoverHandler {
                        id: pluginHover
                        target: parent
                        enabled: true
                    }
                }
                Connections {
                    target: pluginPreferencesView
                    function onClosed() {
                        pluginListView.currentIndex = -1;
                    }
                }
            }
        }
    }
}
