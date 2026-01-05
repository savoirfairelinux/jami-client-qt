/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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

/* NOTE: This is a high-level imlpementation of the icon button.
 *      Use the standard fixed icon button size (small, medium, large)
 *      as found in JamiTheme. If using a custom size, add a comment
 *      explaining why.
 */
Button {
    id: root

    property int iconSize
    property string iconSource
    property string toolTipText: ""

    // The icon property is defined within the contentIcon of
    // the Button component
    icon.width: iconSize
    icon.height: iconSize
    icon.color: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
    icon.source: iconSource

    Behavior on icon.color {
        ColorAnimation {
            duration: 200
        }
    }

    background: Rectangle {
        width: icon.width + (iconSize / 8)
        height: icon.height + (iconSize / 8)

        radius: width / 2
        anchors.centerIn: contentItem

        color: root.hovered ? JamiTheme.hoveredButtonColor : JamiTheme.transparentColor
    }

    MaterialToolTip {
        parent: root
        visible: root.hovered && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }
}
