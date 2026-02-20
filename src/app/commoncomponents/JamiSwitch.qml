/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

Switch {
    id: root

    property alias toolTipText: toolTip.text
    property alias radius: handleBackground.radius

    hoverEnabled: true

    focusPolicy: Qt.StrongFocus
    useSystemFocusVisuals: false

    MaterialToolTip {
        id: toolTip

        parent: root
        visible: hovered && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    indicator: Rectangle {
        id: handleBackground

        implicitWidth: JamiTheme.switchPreferredWidth
        implicitHeight: JamiTheme.switchPreferredHeight

        x: root.leftPadding
        y: parent.height / 2 - height / 2

        radius: JamiTheme.switchIndicatorRadius
        color: JamiTheme.switchBackgroundColor
        border.color: JamiTheme.switchBackgroundBorderColor

        Rectangle {
            id: handle

            x: root.checked ? parent.width - width : 0
            y: parent.height / 2 - height / 2

            width: JamiTheme.switchIndicatorPreferredWidth
            height: JamiTheme.switchPreferredHeight

            radius: JamiTheme.switchIndicatorRadius

            color: root.checked ? JamiTheme.switchHandleCheckedColor : JamiTheme.switchHandleColor
            border.color: JamiTheme.switchHandleBorderColor

            Behavior on color {

                ColorAnimation {
                    easing.type: Easing.OutQuad
                    duration: JamiTheme.shortFadeDuration
                }
            }

            Behavior on x {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            checked = !checked;
            keyEvent.accepted = true;
        }
    }
}
