/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import net.jami.Constants 1.1

Flickable {
    id: root
    property bool attachedFlickableMoving: root.moving
    property alias horizontalHandleColor: horizontalScrollBar.handleColor
    property alias verticalHandleColor: verticalScrollBar.handleColor

    clip: true
    maximumFlickVelocity: 1024

    Keys.onDownPressed: verticalScrollBar.increase()
    Keys.onLeftPressed: horizontalScrollBar.decrease()
    Keys.onRightPressed: horizontalScrollBar.increase()
    Keys.onUpPressed: verticalScrollBar.decrease()

    ScrollBar.horizontal: JamiScrollBar {
        id: horizontalScrollBar
        attachedFlickableMoving: root.attachedFlickableMoving
        orientation: Qt.Horizontal
    }
    ScrollBar.vertical: JamiScrollBar {
        id: verticalScrollBar
        attachedFlickableMoving: root.attachedFlickableMoving
    }
}
