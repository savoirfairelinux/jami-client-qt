/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ItemDelegate {
    id: root

    property string accountId: ""
    property string pluginName : ""
    property string pluginId: ""
    property string pluginIcon: ""
    property bool isLoaded: false
    height: pluginListPreferencesView.visible ? implicitHeight + pluginListPreferencesView.effectiveHeight : implicitHeight

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight

            Label {
                id: pluginImage
                Layout.leftMargin: 8
                Layout.topMargin: 8
                Layout.alignment: Qt.AlignLeft | Qt.AlingVCenter
                width: JamiTheme.preferredFieldHeight
                Layout.fillHeight: true

                background: Rectangle {
                    color: "transparent"
                    Image {
                        anchors.centerIn: parent
                        source: "file:" + pluginIcon
                        sourceSize: Qt.size(256, 256)
                        mipmap: true
                        width: JamiTheme.preferredFieldHeight
                        height: JamiTheme.preferredFieldHeight
                    }
                }
            }

            Label {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 8
                color: JamiTheme.textColor

                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                text: pluginName === "" ? pluginId : pluginName
                verticalAlignment: Text.AlignVCenter
            }

            Switch {
                id: loadSwitch
                Layout.fillHeight: true
                property bool isHovering: false
                Layout.topMargin: 8
                Layout.rightMargin: 8
                width: 20
                visible: accountId ? false : true

                ToolTip.visible: hovered
                ToolTip.text: qsTr("Load/Unload")

                checked: isLoaded
                onClicked: {
                    if (isLoaded)
                        PluginModel.unloadPlugin(pluginId)
                    else
                        PluginModel.loadPlugin(pluginId)
                    installedPluginsModel.pluginChanged(index)
                }

                background: Rectangle {
                    id: switchBackground

                    color: "transparent"
                    MouseArea {
                        id: btnMouseArea
                        hoverEnabled: true
                        onReleased: {
                            loadSwitch.clicked()
                        }
                        onEntered: {
                            loadSwitch.isHovering = true
                        }
                        onExited: {
                            loadSwitch.isHovering = false
                        }
                    }
                }
            }

            PushButton {
                id: btnPreferencesPlugin

                Layout.alignment: Qt.AlingVCenter | Qt.AlignRight
                Layout.topMargin: 8
                Layout.rightMargin: 8

                source: JamiResources.round_settings_24dp_svg
                normalColor: JamiTheme.primaryBackgroundColor
                imageColor: JamiTheme.textColor
                toolTipText: JamiStrings.showHidePrefs

                onClicked: pluginListPreferencesView.visible = !pluginListPreferencesView.visible
            }
        }

        PluginListPreferencesView {
            id: pluginListPreferencesView

            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: effectiveHeight
        }
    }
}
