/*
 * Copyright (C) 2019-2025 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import net.jami.Models 1.1

ListView {
    id: root

    property alias verticalScrollBar: verticalScrollBar
    property bool isKeyNavigationEnabled: false

    layer.mipmap: false
    clip: true
    maximumFlickVelocity: 1024

    ScrollBar.vertical: JamiScrollBar {
        id: verticalScrollBar

        attachedFlickableMoving: root.moving
    }

    // HACK: remove after migration to Qt 6.7+
    boundsBehavior: Flickable.StopAtBounds

    Keys.onUpPressed: {
        if (isKeyNavigationEnabled) {
            if (currentIndex > 0) {
                decrementCurrentIndex()
                positionViewAtIndex(currentIndex, ListView.Contain)
            }
        } else {
            verticalScrollBar.decrease()
        }
    }

    Keys.onDownPressed: {
        if (isKeyNavigationEnabled) {
            if (currentIndex < count - 1) {
                incrementCurrentIndex()
                positionViewAtIndex(currentIndex, ListView.Contain)
            }
        } else {
            verticalScrollBar.increase()
        }
    }
}
