/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root
    property string activeId: ""
    property bool isLoaded: false
    property string pluginIcon: ""
    property string pluginId: ""
    property string pluginName: ""

    height: pluginPreferencesView.visible ? implicitHeight + pluginPreferencesView.childrenRect.height : implicitHeight

    signal settingsClicked

    onActiveIdChanged: pluginPreferencesView.visible = activeId != pluginId ? false : !pluginPreferencesView.visible

    ColumnLayout {
        width: parent.width

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight

            Label {
                id: pluginImage
                Layout.alignment: Qt.AlignLeft | Qt.AlingVCenter
                Layout.fillHeight: true
                Layout.leftMargin: 8
                Layout.topMargin: 8
                width: JamiTheme.preferredFieldHeight

                background: Rectangle {
                    color: "transparent"

                    Image {
                        anchors.centerIn: parent
                        height: JamiTheme.preferredFieldHeight
                        mipmap: true
                        source: "file:" + pluginIcon
                        sourceSize: Qt.size(256, 256)
                        width: JamiTheme.preferredFieldHeight
                    }
                }
            }
            Label {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.topMargin: 8
                color: JamiTheme.textColor
                font.kerning: true
                font.pointSize: JamiTheme.settingsFontSize
                text: pluginName === "" ? pluginId : pluginName
                verticalAlignment: Text.AlignVCenter
            }
            ToggleSwitch {
                id: loadSwitch
                property bool isHovering: false

                Layout.fillHeight: true
                Layout.rightMargin: 8
                Layout.topMargin: 8
                checked: isLoaded
                tooltipText: JamiStrings.loadUnload
                width: 20

                onSwitchToggled: {
                    if (isLoaded)
                        PluginModel.unloadPlugin(pluginId);
                    else
                        PluginModel.loadPlugin(pluginId);
                    installedPluginsModel.pluginChanged(index);
                }
            }
            PushButton {
                id: btnPreferencesPlugin
                Layout.alignment: Qt.AlingVCenter | Qt.AlignRight
                Layout.rightMargin: 8
                Layout.topMargin: 8
                imageColor: JamiTheme.textColor
                normalColor: JamiTheme.primaryBackgroundColor
                source: JamiResources.round_settings_24dp_svg
                toolTipText: JamiStrings.showHidePrefs

                onClicked: settingsClicked()
            }
        }
        PluginPreferencesView {
            id: pluginPreferencesView
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: pluginPreferencesView.childrenRect.height
            Layout.rightMargin: JamiTheme.preferredMarginSize
        }
    }
}
