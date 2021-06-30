/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14

import net.jami.Constants 1.0

import "../commoncomponents/contextmenu"

Flickable {
    id: textAreaFlick

    property alias text: textArea.text

    LineEditContextMenu {
        id: textAreaContextMenu

        lineEditObj: textArea
    }

    boundsBehavior: Flickable.StopAtBounds

    contentWidth: textArea.paintedWidth
    contentHeight: textArea.paintedHeight
    clip: true

    function ensureVisible(r) {
        if (contentX >= r.x)
            contentX = r.x
        else if (contentX + width <= r.x + r.width)
            contentX = r.x + r.width - width
        if (contentY >= r.y)
            contentY = r.y
        else if (contentY + height <= r.y + r.height)
            contentY = r.y + r.height - height
    }

    TextArea {
        id: textArea

        width: textAreaFlick.width

        padding: 0

        font.pointSize: JamiTheme.textFontSize

        color: JamiTheme.textColor
        wrapMode: TextEdit.Wrap
        overwriteMode: true
        selectByMouse: true
        selectionColor: JamiTheme.placeHolderTextFontColor
        placeholderTextColor: JamiTheme.placeHolderTextFontColor

        cursorDelegate: Rectangle {
            visible: textArea.cursorVisible
            color: JamiTheme.textColor
            width: 1
        }
        background: Rectangle {
            anchors.fill: parent

            border.width: 0
            color: JamiTheme.primaryBackgroundColor
        }

        onReleased: {
            if (event.button == Qt.RightButton)
                textAreaContextMenu.openMenuAt(event)
        }

        onCursorRectangleChanged: textAreaFlick.ensureVisible(cursorRectangle)
    }
}
