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

import net.jami.Constants 1.1

// Assumed to be attached to Flickable
ScrollBar {
    id: root

    property bool attachedFlickableMoving: false

    active: hovered || pressed || attachedFlickableMoving
    hoverEnabled: true
    orientation: Qt.Vertical

    visible: size < 1.0
    opacity: 0

    contentItem: Rectangle {
        id: scrollBarRect

        implicitWidth: 6
        radius: width / 2
        color: pressed ? Qt.darker(JamiTheme.scrollBarHandleColor, 2.0) :
                         JamiTheme.scrollBarHandleColor
    }

    background: Rectangle {
        implicitWidth: scrollBarRect.implicitWidth
        color: JamiTheme.transparentColor
        radius: width / 2
    }

    OpacityAnimator {
        target: root
        from: 0
        to: 1
        duration: JamiTheme.shortFadeDuration * 2
        running: active
    }

    OpacityAnimator {
        target: root
        from: 1
        to: 0
        duration: JamiTheme.shortFadeDuration * 2
        running: !active
    }
}
