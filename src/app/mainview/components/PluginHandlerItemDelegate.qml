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
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    property string handlerName: ""
    property string handlerId: ""
    property string handlerIcon: ""
    property bool isLoaded: false
    property string pluginId: ""

    signal btnLoadHandlerToggled
    signal openPreferences

    padding: 0
    leftPadding: root.background.radius - btnPreferencesPluginHandler.iconSize / 2
    rightPadding: root.background.radius - btnPreferencesPluginHandler.iconSize / 2

    contentItem: RowLayout {

        anchors.verticalCenter: root.verticalCenter

        spacing: 8

        Image {
            Layout.maximumHeight: btnPreferencesPluginHandler.implicitBackgroundHeight
            Layout.maximumWidth: btnPreferencesPluginHandler.implicitBackgroundWidth
            Layout.alignment: Qt.AlignVCenter

            width: btnPreferencesPluginHandler.implicitBackgroundWidth
            height: btnPreferencesPluginHandler.implicitBackgroundHeight

            source: "file:" + handlerIcon
            mipmap: true
        }

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: handlerName === "" ? handlerId : handlerName
            color: JamiTheme.textColor

            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true
        }

        JamiSwitch {
            id: loadSwitch

            Layout.alignment: Qt.AlignVCenter

            checked: isLoaded
            toolTipText: JamiStrings.onOff

            onToggled: root.btnLoadHandlerToggled();
        }

        NewIconButton {
            id: btnPreferencesPluginHandler

            Layout.alignment: Qt.AlignVCenter

            iconSource: JamiResources.settings_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            toolTipText: root.pluginId

            onClicked: {
                root.openPreferences()
            }
        }
    }

    background: Rectangle {
        radius: height / 2

        color: root.hovered ? JamiTheme.smartListHoveredColor : JamiTheme.globalIslandColor

        Behavior on color {

            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    onClicked: root.btnLoadHandlerToggled()
}
