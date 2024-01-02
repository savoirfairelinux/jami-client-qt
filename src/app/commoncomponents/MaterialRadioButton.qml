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
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import net.jami.Models 1.1

RadioButton {
    id: root
    property color backgroundColor: JamiTheme.radioBackgroundColor
    property color borderColor: JamiTheme.radioBorderColor
    property color borderOuterRectangle: "transparent"
    property color checkedColor: JamiTheme.radioBorderColor
    property string iconSource: ""
    property color textColor: JamiTheme.textColor

    height: implicitHeight

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            root.checked = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: JamiTheme.settingsBoxRadius

        border {
            color: borderOuterRectangle
            width: 1
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: JamiTheme.settingsBoxRadius
        visible: checked || hovered

        border {
            color: borderColor
            width: 1
        }

        Behavior on visible  {
            enabled: hovered

            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
                from: 0
            }
        }
    }

    contentItem: RowLayout {
        spacing: 10

        anchors.left: root.indicator.right
        anchors.leftMargin: 10

        ResponsiveImage {
            color: borderColor
            height: JamiTheme.radioImageSize
            source: iconSource
            visible: iconSource !== ""
            width: JamiTheme.radioImageSize
        }

        Text {
            color: textColor
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            text: root.text
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }
    }

    indicator: Rectangle {
        id: indicatorRectangle
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        implicitHeight: 20
        implicitWidth: 20
        radius: 10
        z: 1

        border {
            id: border
            color: borderColor
            width: 1
        }
        Rectangle {
            id: innerRect
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            color: checkedColor
            height: 12
            radius: 10
            visible: checked || hovered
            width: 12

            HoverHandler {
                target: parent
            }

            Behavior on visible  {
                enabled: hovered

                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                    from: 0
                }
            }
        }
    }
}
