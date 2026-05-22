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
import QtQuick.Controls
import QtQuick.Controls.impl

import net.jami.Constants 1.1

Control {
    id: root

    // The chip will default to the filled version unless
    // outlinedChip is enabled specifically
    property bool filledChip: !outlinedChip
    property bool outlinedChip: false

    property color color: JamiTheme.tintedBlue

    property alias text: chipText.text
    property string iconSource: ""
    signal iconClicked

    property string toolTipText: ""
    property string iconButtonToolTipText: ""

    leftPadding: background.radius
    rightPadding: background.radius - (trailingIconButton.height / 2)
    topPadding: JamiTheme.jamiChipVerticalPadding
    bottomPadding: JamiTheme.jamiChipVerticalPadding

    activeFocusOnTab: true

    scale: root.hovered || root.activeFocus ? JamiTheme.jamiChipHoveredScaleValue : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    contentItem: Row {
        spacing: 2

        Text {
            id: chipText

            anchors.verticalCenter: parent.verticalCenter

            verticalAlignment: Text.AlignVCenter
            color: {
                if (root.filledChip) {
                    return JamiTheme.whiteColor;
                } else if (root.outlinedChip) {
                    if (root.hovered || root.activeFocus) {
                        return JamiTheme.whiteColor;
                    } else {
                        return root.color;
                    }
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        Button {
            id: trailingIconButton

            anchors.verticalCenter: parent.verticalCenter

            padding: 0
            horizontalPadding: 0

            icon.source: root.iconSource
            icon.color: {
                if (root.filledChip) {
                    return JamiTheme.whiteColor;
                } else if (root.outlinedChip) {
                    if (root.hovered || root.activeFocus) {
                        return JamiTheme.whiteColor;
                    } else {
                        return root.color;
                    }
                }
            }
            Behavior on icon.color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }

            scale: trailingIconButton.hovered || trailingIconButton.activeFocus ? JamiTheme.jamiChipIconButtonHoveredScaleValue : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }

            visible: iconSource !== ""

            background: null

            onClicked: root.iconClicked()

            MaterialToolTip {
                id: iconButtonToolTipText

                parent: parent
                text: root.iconButtonToolTipText
                visible: (trailingIconButton.hovered || trailingIconButton.activeFocus) && (text.length > 0)
                delay: Qt.styleHints.mousePressAndHoldInterval
            }

            Accessible.role: Accessible.Button
            Accessible.name: iconButtonToolTipText.text
        }
    }

    background: Rectangle {
        radius: height / 2

        color: {
            if (root.filledChip) {
                return root.color;
            } else if (root.outlinedChip) {
                if (root.hovered || root.activeFocus) {
                    return Qt.rgba(root.color.r, root.color.g, root.color.b, 0.92);
                } else {
                    return Qt.rgba(root.color.r, root.color.g, root.color.b, 0);
                }
            }
        }

        border.color: JamiTheme.tintedBlue
        border.width: root.outlinedChip ? 1 : 0

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    MaterialToolTip {
        id: toolTip

        parent: root
        text: root.toolTipText
        visible: (root.hovered || root.activeFocus) && (root.toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: root.text
}
