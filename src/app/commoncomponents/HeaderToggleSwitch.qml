/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
 * Author: Xavier Jouslin <xavier.jouslindenoray@savoirfairelinux.com>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

RowLayout {
    id: root
    property string labelText: ""
    property int widthOfSwitch: 50
    property int heightOfSwitch: 10

    property string tooltipText: ""

    property alias toggleSwitch: autoupdate
    property alias checked: autoupdate.checked

    signal switchToggled
    Layout.alignment: Qt.AlignRight
    JamiSwitch {
        id: autoupdate
        Layout.alignment: Qt.AlignLeft

        Layout.preferredWidth: widthOfSwitch

        hoverEnabled: true
        toolTipText: tooltipText

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.autoUpdate
        Accessible.description: root.tooltipText

        onToggled: switchToggled()
    }
    Text {
        id: description
        Layout.rightMargin: JamiTheme.preferredMarginSize
        text: JamiStrings.autoUpdate
        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
        visible: labelText !== ""
        font.kerning: true
        wrapMode: Text.WordWrap
        verticalAlignment: Text.AlignVCenter

        color: JamiTheme.textColor
    }
    TapHandler {
        target: parent
        enabled: parent.visible
        onTapped: function onTapped(eventPoint) {
            // switchToggled should be emitted as onToggled is not called (because it's only called if the user click on the switch)
            autoupdate.toggle();
            switchToggled();
        }
    }
}
