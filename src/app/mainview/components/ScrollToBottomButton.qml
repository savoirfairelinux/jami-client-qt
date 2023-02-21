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
import Qt5Compat.GraphicalEffects

import net.jami.Constants 1.1
import net.jami.Adapters 1.1


import "../../commoncomponents"

Control {
    id: root

    property alias activeStateTrigger: activeState.when

    signal clicked

    height: jumpToLatestText.contentHeight + 15
    width: jumpToLatestText.contentWidth + arrowDropDown.width + 50

    opacity: 0

    states: State {
        id: activeState

        name: "active"
        PropertyChanges {
            target: root
            opacity: 1
        }
    }

    transitions: [
        Transition {
            to: "active"
            NumberAnimation {
                target: root
                duration: JamiTheme.shortFadeDuration
                property: "opacity"
            }
        },
        Transition {
            from: "active"
            NumberAnimation {
                target: root
                duration: JamiTheme.shortFadeDuration
                property: "opacity"
                to: 0.0
            }
        }
    ]

    contentItem: Item {
        Item {
            anchors.centerIn: parent

            height: jumpToLatestText.contentHeight
            width: jumpToLatestText.contentWidth + arrowDropDown.width + 3

            Text {
                id: jumpToLatestText

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                font.weight: Font.Bold
                font.pointSize: JamiTheme.textFontSize + 2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: JamiStrings.jumpToLatest
                color: UtilsAdapter.luma(CurrentConversation.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark


            }

            ResponsiveImage {
                id: arrowDropDown

                anchors.right: jumpToLatestText.left
                anchors.rightMargin: 3
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0

                containerWidth: jumpToLatestText.contentHeight
                containerHeight: jumpToLatestText.contentHeight
                rotation: -90

                color: UtilsAdapter.luma(CurrentConversation.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                source: JamiResources.back_24dp_svg
            }
        }
    }

    background: Rectangle {
        radius: 20
        color: CurrentConversation.color

        MouseArea {
            anchors.fill: parent
            cursorShape: root.opacity ? Qt.PointingHandCursor :
                                        Qt.ArrowCursor

            onClicked: root.clicked()
        }

        layer {
            enabled: true
            effect: DropShadow {
                z: -1
                horizontalOffset: 3.0
                verticalOffset: 3.0
                radius: 8.0
                color: JamiTheme.shadowColor
                transparentBorder: true
            }
        }
    }
}
