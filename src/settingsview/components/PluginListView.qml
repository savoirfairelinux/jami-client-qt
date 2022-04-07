/*
 * Copyright (C) 2019-2022 Savoir-faire Linux Inc.
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

    visible: false
    color: JamiTheme.secondaryBackgroundColor

    JamiFileDialog {
        id: pluginPathDialog

        mode: JamiFileDialog.OpenFile
        title: JamiStrings.selectPluginInstall
        folder: StandardPaths.writableLocation(StandardPaths.DownloadLocation)

        nameFilters: [qsTr("Plugin Files") + " (*.jpl)", qsTr(
                "All files") + " (*)"]

        onAccepted: {
            var url = UtilsAdapter.getAbsPath(file.toString())
            PluginModel.installPlugin(url, true)
            installedPluginsModel.addPlugin()
        }
    }

    ColumnLayout {
        anchors.left: root.left
        anchors.right: root.right
        anchors.bottomMargin: 20

        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 25

            text: qsTr("Installed plugins")
            font.pointSize: JamiTheme.headerFontSize
            font.kerning: true
            color: JamiTheme.textColor

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        MaterialButton {
            id: installButton

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize / 2

            preferredWidth: JamiTheme.preferredFieldWidth
            preferredHeight: JamiTheme.preferredFieldHeight

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            outlined: true
            toolTipText: JamiStrings.addNewPlugin

            iconSource: JamiResources.round_add_24dp_svg

            text: JamiStrings.installPlugin

            onClicked: pluginPathDialog.open()
        }

        ListView {
            id: pluginList

            Layout.fillWidth: true
            Layout.minimumHeight: 0
            Layout.bottomMargin: 10
            Layout.preferredHeight: childrenRect.height

            model: PluginListModel {
                id: installedPluginsModel

                lrcInstance: LRCInstance
                onLrcInstanceChanged: {
                    this.reset()
                }
            }

            delegate: PluginItemDelegate {
                id: pluginItemDelegate

                width: pluginList.width
                implicitHeight: 40

                pluginName: PluginName
                pluginId: PluginId
                pluginIcon: PluginIcon
                isLoaded: IsLoaded
                activeId: root.activePlugin

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onSettingsClicked: {
                    root.activePlugin = root.activePlugin === pluginId ? "" : pluginId
                }
            }
        }
    }
}
