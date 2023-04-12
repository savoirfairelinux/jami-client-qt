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
    property string activePlugin: ""

    color: JamiTheme.secondaryBackgroundColor
    visible: false

    ColumnLayout {
        anchors.bottomMargin: 20
        anchors.left: root.left
        anchors.right: root.right

        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 25
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.headerFontSize
            horizontalAlignment: Text.AlignLeft
            text: JamiStrings.installedPlugins
            verticalAlignment: Text.AlignVCenter
        }
        MaterialButton {
            id: installButton
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize / 2
            buttontextHeightMargin: JamiTheme.buttontextHeightMargin
            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            iconSource: JamiResources.round_add_24dp_svg
            preferredWidth: JamiTheme.preferredFieldWidth
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            text: JamiStrings.installPlugin
            toolTipText: JamiStrings.addNewPlugin

            onClicked: {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                        "title": JamiStrings.selectPluginInstall,
                        "fileMode": JamiFileDialog.OpenFile,
                        "folder": StandardPaths.writableLocation(StandardPaths.DownloadLocation),
                        "nameFilters": [JamiStrings.pluginFiles, JamiStrings.allFiles]
                    });
                dlg.fileAccepted.connect(function (file) {
                        var url = UtilsAdapter.getAbsPath(file.toString());
                        PluginModel.installPlugin(url, true);
                        installedPluginsModel.addPlugin();
                    });
            }
        }
        ListView {
            id: pluginList
            Layout.bottomMargin: 10
            Layout.fillWidth: true
            Layout.minimumHeight: 0
            Layout.preferredHeight: childrenRect.height
            clip: true

            delegate: PluginItemDelegate {
                id: pluginItemDelegate
                activeId: root.activePlugin
                implicitHeight: 50
                isLoaded: IsLoaded
                pluginIcon: PluginIcon
                pluginId: PluginId
                pluginName: PluginName
                width: pluginList.width

                onSettingsClicked: {
                    root.activePlugin = root.activePlugin === pluginId ? "" : pluginId;
                }

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }
            }
            model: PluginListModel {
                id: installedPluginsModel
                lrcInstance: LRCInstance

                onLrcInstanceChanged: {
                    this.reset();
                }
            }
        }
    }
}
