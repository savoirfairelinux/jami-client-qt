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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root
    property string handlerIcon: ""
    property string handlerId: ""
    property string handlerName: ""
    property bool isLoaded: false
    property string pluginId: ""

    signal btnLoadHandlerToggled
    signal openPreferences

    RowLayout {
        anchors.fill: parent

        Label {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.leftMargin: 8
            width: 30

            background: Rectangle {
                color: "transparent"

                Image {
                    anchors.centerIn: parent
                    height: 30
                    mipmap: true
                    source: "file:" + handlerIcon
                    width: 30
                }
            }
        }
        Label {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.leftMargin: 8
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.settingsFontSize
            text: handlerName === "" ? handlerId : handlerName
        }
        Switch {
            id: loadSwitch
            property bool isHovering: false

            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 8
            ToolTip.text: {
                return JamiStrings.onOff;
            }
            ToolTip.visible: hovered
            checked: isLoaded
            height: 30
            width: 30

            onClicked: {
                btnLoadHandlerToggled();
            }

            background: Rectangle {
                id: switchBackground
                color: "transparent"

                MouseArea {
                    id: btnMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        loadSwitch.isHovering = true;
                    }
                    onExited: {
                        loadSwitch.isHovering = false;
                    }
                    onPressed: {
                    }
                    onReleased: {
                        loadSwitch.clicked();
                    }
                }
            }
        }
        PushButton {
            id: btnPreferencesPluginHandler
            Layout.alignment: Qt.AlingVCenter | Qt.AlignRight
            Layout.rightMargin: 8
            imageColor: JamiTheme.textColor
            normalColor: JamiTheme.primaryBackgroundColor
            source: JamiResources.round_settings_24dp_svg
            toolTipText: root.pluginId

            onClicked: openPreferences()
        }
    }
}
