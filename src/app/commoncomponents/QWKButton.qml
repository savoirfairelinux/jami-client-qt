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

import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Button {
    id: control

    width: height * 0.9156626506024096
    leftInset: 0
    topInset: 0
    rightInset: 0
    bottomInset: 0
    padding: 0

    function calculateLuminance(color) {
        return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
    }

    property alias source: image.source
    contentItem: Item {
        Image {
            id: image
            anchors.centerIn: parent
            mipmap: true
            width: 12
            height: 12
            layer.enabled: true
            layer.effect: ColorOverlay {
                color: {
                    // We may force this color to be white, when the background is dark.
                    var backgroundIsDark = calculateLuminance(control.background.color) > 0.25;
                    // This includes when we are in a call (which has a dark background).
                    backgroundIsDark = backgroundIsDark || CurrentConversation.hasCall;
                    return backgroundIsDark ? "white" : JamiTheme.primaryForegroundColor;
                }
            }
        }
    }

    property color baseColor: {
        // Avoid transparent if the background is dark i.e. in a call.
        if (CurrentConversation.hasCall)
            return Qt.rgba(1, 1, 1, 0.5);
        return JamiTheme.darkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.15);
    }
    readonly property color pressedColor: {
        const darker = Qt.darker(baseColor, 1.3);
        return Qt.rgba(darker.r, darker.g, darker.b, baseColor.a * 1.3);
    }
    background: Rectangle {
        color: {
            if (!control.enabled)
                return "gray";
            if (control.pressed)
                return control.pressedColor;
            if (control.hovered)
                return control.baseColor;
            return "transparent";
        }
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
