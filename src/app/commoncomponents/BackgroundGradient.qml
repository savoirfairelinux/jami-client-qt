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
import net.jami.Adapters 1.1

/* This gradient rectangle is used to give faded effect for messages
  when in an active conversation. It should be applied to both the ChatView
  and the SidePanel.
*/

Rectangle {
    id: gradientRect

    // Use the MainView's base color and opacity which includes existing
    // behavior-based animations.
    property color baseColor: JamiQmlUtils.mainViewRectObj.baseColor

    opacity: JamiQmlUtils.mainViewRectObj.tintOpacity

    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop {
            position: 0.0
            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                           gradientRect.baseColor.b, 1.0)
        }
        GradientStop {
            position: (JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding) / gradientRect.height
            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                           gradientRect.baseColor.b, 0.8)
        }
        GradientStop {
            position: 1.0
            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                           gradientRect.baseColor.b, 0.0)
        }
    }

    // To block mouse events for messages behind the gradient
    MouseArea {
        anchors.fill: parent
    }
}
