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
    property string labelText: ""
    property string descText: ""
    property int widthOfSwitch: 50
    property int heightOfSwitch: 10
    property int heightOfLayout: 30
    property int fontPointSize: JamiTheme.headerFontSize

    property string tooltipText: ""

    property alias toggleSwitch: switchOfLayout
    property alias checked: switchOfLayout.checked

    signal switchToggled

    RowLayout{

        ColumnLayout {
            id: toggleLayout
            Layout.preferredHeight: toggleLayout.implicitHeight  // description.visible ? toggleLayout.implicitHeight : heightOfLayout
            spacing: 5

            Text {
                id: title
                Layout.fillWidth: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                visible: labelText !== ""
                text: root.labelText
                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                font.kerning: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                color: JamiTheme.textColor
            }

            Text {
                id: description
                Layout.fillWidth: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                visible: descText !== ""
                text: root.descText
                font.pixelSize: JamiTheme.settingToggleDescrpitonPixelSize
                font.kerning: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                color: JamiTheme.textColor
            }
        }

        JamiSwitch {
            id: switchOfLayout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Layout.preferredWidth: widthOfSwitch
            Layout.preferredHeight: heightOfSwitch

            hoverEnabled: true
            toolTipText: tooltipText

            Accessible.role: Accessible.Button
            Accessible.name: root.labelText
            Accessible.description: root.tooltipText

            onToggled: switchToggled()
        }

        TapHandler {
            target: parent
            enabled: parent.visible
            onTapped: function onTapped(eventPoint) {
                // switchToggled should be emitted as onToggled is not called (because it's only called if the user click on the switch)
                switchOfLayout.toggle()
                switchToggled()
            }
        }
    }
}
