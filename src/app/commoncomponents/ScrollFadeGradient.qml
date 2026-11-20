/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1

// Fades list items into the background at an edge where more content can be scrolled into view.
Rectangle {
    id: root

    required property Flickable flickable
    property bool atTop: false
    property color baseColor: JamiTheme.globalIslandColor
    readonly property bool shouldShow: flickable !== null && (atTop ? !flickable.atYBeginning : !flickable.atYEnd)

    anchors.top: atTop ? flickable.top : undefined
    anchors.bottom: atTop ? undefined : flickable.bottom
    width: flickable.width
    height: JamiTheme.smartListItemHeight
    z: flickable.z + 1

    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop {
            position: 0.0
            color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.atTop ? 1.0 : 0.0)
        }
        GradientStop {
            position: root.atTop ? 0.25 : 0.75
            color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.75)
        }
        GradientStop {
            position: 1.0
            color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.atTop ? 0.0 : 1.0)
        }
    }

    visible: opacity > 0
    opacity: shouldShow ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }
}
