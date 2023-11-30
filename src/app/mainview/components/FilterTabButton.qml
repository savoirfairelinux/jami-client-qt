/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

    property var backgroundColor: JamiTheme.backgroundColor
    property var hoverColor: JamiTheme.backgroundColor
    property var textColor: JamiTheme.textColor
    property var textColorHovered: JamiTheme.textColorHovered
    property var underlineColor: textColor
    property var underlineColorHovered: textColorHovered
    property real borderWidth: 2
    property real bottomMargin: 1
    property bool underlineContentOnly: false
    property var fontSize: JamiTheme.filterItemFontSize

    signal selected

    hoverEnabled: true
    onClicked: selected()

    Rectangle {
        id: contentRect

        anchors.fill: root

        color: root.hovered ? root.hoverColor : root.backgroundColor

        RowLayout {
            id: informations
            anchors.horizontalCenter: contentRect.horizontalCenter
            anchors.verticalCenter: contentRect.verticalCenter

            Text {
                id: label

                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.bottomMargin: root.bottomMargin

                font.pointSize: fontSize
                color: {
                    if (!root.down && root.hovered)
                        return root.textColorHovered;
                    return root.textColor;
                }
                opacity: root.down ? 1.0 : 0.5
            }

            BadgeNotifier {
                id: badge
                size: 20
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
        }
    }

    Rectangle {
        width: underlineContentOnly ? informations.width + JamiTheme.menuBorderPreferredHeight : contentRect.width
        anchors.horizontalCenter: contentRect.horizontalCenter
        anchors.bottom: contentRect.bottom
        height: borderWidth
        color: {
            if (!root.down && root.hovered)
                return underlineColorHovered;
            if (!root.down)
                return "transparent";
            return root.underlineColor;
        }
    }

    Shortcut {
        id: accelerator
        context: Qt.ApplicationShortcut
        enabled: contentRect.visible
        onActivated: selected()
    }
}
