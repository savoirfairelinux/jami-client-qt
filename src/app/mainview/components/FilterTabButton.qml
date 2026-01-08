/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import "../../commoncomponents"

TabButton {
    id: root

    property alias labelText: label.text
    property alias acceleratorSequence: accelerator.sequence
    property alias badgeCount: badge.count

    property int fontSize: JamiTheme.filterItemFontSize

    signal selected

    hoverEnabled: true
    onClicked: selected()

    Accessible.name: root.labelText
    Accessible.role: Accessible.Button

    contentItem: RowLayout {
        anchors.centerIn: background

        Text {
            id: label

            Layout.alignment: Qt.AlignCenter

            font.pointSize: fontSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            color: (root.hovered || root.activeFocus) ? JamiTheme.textColorHovered : JamiTheme.textColor
        }

        BadgeNotifier {
            id: badge
            size: 20
        }
    }

    background: Rectangle {
        id: background

        anchors.fill: root
        anchors.margins: 8

        color: (root.down || root.hovered || root.activeFocus) ? JamiTheme.hoveredButtonColor : JamiTheme.globalBackgroundColor
        opacity: (root.down || root.hovered || root.activeFocus) ? 1.0 : 0.0
        radius: height / 2

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    Shortcut {
        id: accelerator
        context: Qt.ApplicationShortcut
        enabled: background.visible
        onActivated: selected()
    }
}
