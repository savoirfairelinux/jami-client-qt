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
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import net.jami.Models 1.1

RadioButton {
    id: root

    property string iconSource: ""
    property color borderColor: JamiTheme.radioBorderColor
    property color checkedColor: JamiTheme.radioBorderColor
    property color backgroundColor: JamiTheme.radioBackgroundColor
    property color textColor: JamiTheme.textColor
    property color borderOuterRectangle: "transparent"

    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: JamiTheme.settingsBoxRadius
        border {
            width: 1
            color: borderOuterRectangle
        }
    }

    indicator: Rectangle {
        id: indicatorRectangle
        z: 1
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 18
        color: "transparent"

        border {
            id: border
            color: borderColor
            width: 1
        }

        implicitWidth: 20
        implicitHeight: 20
        radius: JamiTheme.settingsBoxRadius

        Rectangle {
            id: innerRect

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            radius: JamiTheme.settingsBoxRadius
            visible: checked || hovered

            Behavior on visible  {
                enabled: hovered
                NumberAnimation {
                    from: 0
                    duration: JamiTheme.shortFadeDuration
                }
            }

            color: checkedColor

            HoverHandler {
                target: parent
            }
        }
    }

    contentItem: RowLayout {

        anchors.fill: parent
        anchors.leftMargin: 55
        anchors.rightMargin: 5
        spacing: 10

        ResponsiveImage {
            visible: iconSource !== ""
            source: iconSource
            width: JamiTheme.radioImageSize
            height: JamiTheme.radioImageSize
            color: borderColor
        }

        Text {
            text: root.text
            color: textColor
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            root.checked = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: JamiTheme.settingsBoxRadius
        color: "transparent"
        visible: checked || hovered

        border {
            width: 1
            color: borderColor
        }

        Behavior on visible  {
            enabled: hovered
            NumberAnimation {
                from: 0
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}
