/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Popup {
    id: popup
    width: textComponent.contentWidth + 40 < popup.maxWidth - 20 ? textComponent.contentWidth + 40 : popup.maxWidth - 20
    height: textComponent.contentHeight + 40 < 350 ? textComponent.contentHeight + 40 : 350
    property string text: ""
    property int maxWidth: 0
    x: -1 * (popup.width - 20)

    Rectangle {
        anchors.fill: parent
        color: JamiTheme.transparentColor

        Flickable {
            anchors.fill: parent
            contentHeight: textComponent.contentHeight + 10
            contentWidth: textComponent.contentWidth + 20
            clip: true
            ScrollBar.vertical: JamiScrollBar {
                active: contentHeight > height
            }
            ScrollBar.horizontal: JamiScrollBar {
                active: contentWidth > width
            }
            contentX: 10
            contentY: 10

            Text {
                id: textComponent
                width: popup.maxWidth - 20
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                text: popup.text
                color: JamiTheme.textColor
            }
        }
    }

    background: Rectangle {
        anchors.fill: parent
        color: JamiTheme.backgroundColor
        radius: 5
    }
}
