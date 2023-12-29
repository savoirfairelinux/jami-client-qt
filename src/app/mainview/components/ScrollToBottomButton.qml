/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import "../../commoncomponents"

Control {
    id: root

    signal clicked

    height: 46
    width: 46

    padding: 11

    states: State {
        id: activeState

        name: "active"
        when: root.visible
    }

    transitions: [
        Transition {
            to: "active"
            NumberAnimation {
                target: root
                duration: JamiTheme.shortFadeDuration
                property: "opacity"
                from: 0.0
                to: 1.0
            }
        },
        Transition {
            from: "active"
            NumberAnimation {
                target: root
                duration: JamiTheme.shortFadeDuration
                property: "opacity"
                from: 1.0
                to: 0.0
            }
        }
    ]

    contentItem: ResponsiveImage {
        id: arrowDropDown

        anchors.centerIn: parent

        color: JamiTheme.darkTheme ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
        source: JamiResources.expand_more_24dp_svg
    }

    background: Rectangle {
        radius: 5
        color: JamiTheme.messageInBgColor

        MouseArea {
            anchors.fill: parent
            cursorShape: root.opacity ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: root.clicked()
        }

        layer {
            enabled: true
            effect: DropShadow {
                z: -1
                horizontalOffset: 1.0
                verticalOffset: 1.0
                radius: 6.0
                color: "#29000000"
                transparentBorder: true
                samples: radius + 1
            }
        }
    }
}
