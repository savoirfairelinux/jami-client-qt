/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Sébastien blin <sebastien.blin@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.15

Button {
    id: root

    property alias source: root.icon.source
    property string toolTipText: ""
    property var color: "transparent"
    property var hoveredColor: undefined
    property var pressedColor: undefined
    property var outlined: false
    property string animatedImageSource: ""

    property var preferredWidth: 400
    property var preferredHeight: 36

    font.kerning: true

    icon.source: ""
    icon.height: 18
    icon.width: 18

    hoverEnabled: hoveredColor !== undefined

    contentItem: Item {
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            AnimatedImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16

                width: root.icon.width
                height: root.icon.height

                source: animatedImageSource
                playing: true
                paused: false
                fillMode: Image.PreserveAspectFit
                mipmap: true
                visible: animatedImageSource !== ""
            }

            Image {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16

                width: root.icon.width
                height: root.icon.height

                source: root.icon.source
                layer {
                    enabled: true
                    effect: ColorOverlay {
                        id: overlay
                        color:{
                            if (!outlined)
                                return "white"
                            if (hovered && root.hoveredColor)
                                return root.hoveredColor
                            if (checked && root.pressedColor)
                                return root.pressedColor
                            return root.color
                        }
                    }
                }

                visible: root.icon.source !== ""
            }

            Text {
                text: root.text
                color: {
                    if (!outlined)
                        return "white"
                    if (hovered && root.hoveredColor)
                        return root.hoveredColor
                    if (checked && root.pressedColor)
                        return root.pressedColor
                    return root.color
                }
                font: root.font
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
    ToolTip.visible: hovered && (toolTipText.length > 0)
    ToolTip.text: toolTipText

    background: Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: {
            if (outlined)
                return "transparent"
            if (hovered && root.hoveredColor)
                return root.hoveredColor
            if (checked && root.pressedColor)
                return root.pressedColor
            return root.color
        }
        border.color: {
            if (!outlined)
                return "transparent"
            if (hovered && root.hoveredColor)
                return root.hoveredColor
            if (checked && root.pressedColor)
                return root.pressedColor
            return root.color
        }
        radius: 4
    }
}
