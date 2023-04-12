/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

// Assumed to be attached to Flickable
ScrollBar {
    id: root
    property bool attachedFlickableMoving: false
    property alias handleColor: scrollBarRect.color

    active: {
        if (root.orientation === Qt.Horizontal)
            return visible;
        else
            return hovered || pressed || attachedFlickableMoving;
    }
    bottomPadding: 2
    hoverEnabled: true
    leftPadding: root.orientation === Qt.Horizontal ? 2 : 0
    orientation: Qt.Vertical
    rightPadding: 2
    topPadding: root.orientation === Qt.Vertical ? 2 : 0

    background: Rectangle {
        color: JamiTheme.transparentColor
        implicitHeight: scrollBarRect.implicitHeight
        implicitWidth: scrollBarRect.implicitWidth
        radius: width / 2
    }
    contentItem: Rectangle {
        id: scrollBarRect
        color: pressed ? Qt.darker(JamiTheme.scrollBarHandleColor, 2.0) : JamiTheme.scrollBarHandleColor
        implicitHeight: JamiTheme.scrollBarHandleSize
        implicitWidth: JamiTheme.scrollBarHandleSize
        opacity: 0
        radius: width / 2

        states: State {
            name: "active"
            when: root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1.0)

            PropertyChanges {
                opacity: 1
                target: root.contentItem
            }
        }
        transitions: Transition {
            from: "active"

            SequentialAnimation {
                PauseAnimation {
                    duration: JamiTheme.longFadeDuration
                }
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                    property: "opacity"
                    target: root.contentItem
                    to: 0.0
                }
            }
        }
    }
}
