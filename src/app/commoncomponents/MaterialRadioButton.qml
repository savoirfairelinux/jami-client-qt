/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import net.jami.Models 1.1

RadioButton {
    id: root
    property string bgColor: ""
    property string color: JamiTheme.textColor

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            root.checked = true;
        }
    }

    contentItem: Text {
        color: root.color
        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        leftPadding: root.indicator.width + root.spacing
        text: root.text
        verticalAlignment: Text.AlignVCenter
    }
    indicator: Rectangle {
        id: rect
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: root.bgColor
        implicitHeight: 20
        implicitWidth: 20
        radius: 10

        border {
            id: border
            color: JamiTheme.buttonTintedBlue
            width: 1
        }
        Rectangle {
            id: innerRect
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            color: JamiTheme.buttonTintedBlue
            height: 10
            radius: 10
            visible: checked || hovered
            width: 10

            HoverHandler {
                target: parent
            }

            Behavior on visible  {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                    from: 0
                }
            }
        }
    }
}
