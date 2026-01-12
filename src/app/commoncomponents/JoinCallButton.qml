/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1

Item {
    id: root

    property alias source: button.source
    property alias toolTipText: button.toolTipText
    property alias normalColor: button.normalColor
    property alias hoveredColor: button.hoveredColor
    property alias imageColor: button.imageColor

    signal clicked

    property bool isVideo: false
    property bool roundedRight: isVideo

    implicitWidth: height

    PushButton {
        id: button
        anchors.fill: parent

        radius: 0
        activeFocusOnTab: true
        property bool focusOnChild: true

        normalColor: JamiTheme.buttonCallLightGreen
        hoveredColor: JamiTheme.buttonCallDarkGreen
        imageColor: hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.blackColor

        onClicked: root.clicked()

        layer.enabled: root.roundedRight
        layer.effect: OpacityMask {
            maskSource: maskRect
        }
    }

    Rectangle {
        id: maskRect
        visible: false
        radius: 10
        width: root.width
        height: root.height
        Rectangle {
            width: parent.width / 2
            height: parent.height
        }
    }
}
