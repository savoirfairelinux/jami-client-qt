/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root
    property alias checked: switchOfLayout.checked
    property string descText: ""
    property int heightOfSwitch: 10
    property string labelText: ""
    property alias toggleSwitch: switchOfLayout
    property string tooltipText: ""
    property int widthOfSwitch: 50

    signal switchToggled

    ColumnLayout {
        id: toggleLayout
        Layout.alignment: Qt.AlignVCenter
        spacing: 5

        Text {
            id: title
            Layout.fillWidth: true
            Layout.rightMargin: JamiTheme.preferredMarginSize
            color: JamiTheme.textColor
            font.kerning: true
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            horizontalAlignment: Text.AlignLeft
            text: root.labelText
            verticalAlignment: Text.AlignVCenter
            visible: labelText !== ""
            wrapMode: Text.WordWrap
        }
        Text {
            id: description
            Layout.fillWidth: true
            Layout.rightMargin: JamiTheme.preferredMarginSize
            color: JamiTheme.textColor
            font.kerning: true
            font.pixelSize: JamiTheme.settingToggleDescrpitonPixelSize
            horizontalAlignment: Text.AlignLeft
            text: root.descText
            verticalAlignment: Text.AlignVCenter
            visible: descText !== ""
            wrapMode: Text.WordWrap
        }
    }
    JamiSwitch {
        id: switchOfLayout
        Accessible.description: root.tooltipText
        Accessible.name: root.labelText
        Accessible.role: Accessible.Button
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        Layout.preferredWidth: widthOfSwitch
        hoverEnabled: true
        toolTipText: tooltipText

        onToggled: switchToggled()
    }
    TapHandler {
        enabled: parent.visible
        target: parent

        onTapped: function onTapped(eventPoint) {
            // switchToggled should be emitted as onToggled is not called (because it's only called if the user click on the switch)
            switchOfLayout.toggle();
            switchToggled();
        }
    }
}
