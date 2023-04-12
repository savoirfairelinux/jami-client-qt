/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

    hoverEnabled: true

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            checked = !checked;
            keyEvent.accepted = true;
        }
    }

    MaterialToolTip {
        id: toolTip
        delay: Qt.styleHints.mousePressAndHoldInterval
        parent: root
        visible: hovered && (toolTipText.length > 0)
    }

    indicator: Rectangle {
        id: handleBackground
        border.color: handleBackground.color
        color: JamiTheme.switchBackgroundColor
        implicitHeight: JamiTheme.switchPreferredHeight
        implicitWidth: JamiTheme.switchPreferredWidth
        radius: JamiTheme.switchIndicatorRadius
        x: root.leftPadding
        y: parent.height / 2 - height / 2

        Rectangle {
            id: handle
            border.color: JamiTheme.switchHandleBorderColor
            color: root.checked ? JamiTheme.switchHandleCheckedColor : JamiTheme.switchHandleColor
            height: JamiTheme.switchPreferredHeight
            radius: JamiTheme.switchIndicatorRadius
            width: JamiTheme.switchIndicatorPreferredWidth
            x: root.checked ? parent.width - width : 0
            y: parent.height / 2 - height / 2
        }
    }
}
