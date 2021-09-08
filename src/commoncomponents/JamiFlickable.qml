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

import QtQuick
import QtQuick.Controls

Flickable {
    id: root

    maximumFlickVelocity: 1024
    clip: true

    ScrollBar.vertical: JamiScrollBar {
        id: verticalScrollBar

        parent: root.parent
        attachedFlickableMoving: root.moving
        anchors.right: root.right
        anchors.top: root.top
        anchors.bottom: parent.bottom
        anchors.margins: 2
    }
}
