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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick
import Jami as JamiStyle
import net.jami.Constants 1.1

// General menu item.
// Can control top, bottom, left, right border width.
// Use onClicked slot to simulate item click event.
// Can have image icon at the left of the text.
JamiStyle.MenuItem {
    id: root

    property string itemName: ""
    property bool bold: false
    property alias iconSource: root.icon.source
    property bool canTrigger: true
    property bool dangerous: false
    property string content: ""
    property BaseContextMenu parentMenu
    property int itemRealWidth: implicitWidth
    property alias isActif: root.enabled

    text: itemName
    font.pointSize: JamiTheme.textFontSize
    font.bold: bold
    palette.text: dangerous ? JamiTheme.redColor : JamiTheme.textColor
    icon.color: JamiTheme.textColor

    onReleased: Qt.callLater(() => parentMenu && parentMenu.close())
}
