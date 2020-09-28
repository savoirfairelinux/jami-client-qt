/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Andreas Tracyk <andreas.traczyk@savoirfairelinux.com>
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
import "../constant"

//
// HoverableButton contains the following configurable properties:
// 1. colored states
// 2. radius
// 3. text or image content
//
// Note: if the text property is used directly,
// the buttonTextColor will not work
//
AbstractButton {
    id: root

    property int preferredSize: 30
    property alias imagePadding: image.padding
    property alias imageOffset: image.offset

    property int fontPointSize: 9
    property alias source: image.source
    property string buttonText
    property string buttonTextColor: JamiTheme.primaryForegroundColor
    property string toolTipText: ""

    property string pressedColor: JamiTheme.pressedButtonColor
    property string hoveredColor: JamiTheme.hoveredButtonColor
    property string normalColor: JamiTheme.normalButtonColor

    property var imageColor: null
    property string normalImageSource

    property var checkedColor: null
    property string checkedImageSource

    property alias radius: background.radius

    property int duration: 100

    width: preferredSize
    height: preferredSize

    checkable: true
    checked: false
    hoverEnabled: true

    font.pointSize: fontPointSize
    text: "<font color=" + "'" + buttonTextColor + "'>" + buttonText + "</font>"

    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
    ToolTip.visible: hovered && (toolTipText.length > 0)
    ToolTip.text: toolTipText

    background: Rectangle {
        id: background

        radius: root.width

        states: [
            State {
                name: "pressed"; when: pressed
                PropertyChanges { target: background; color: pressedColor }
                PropertyChanges { target: image; offset: Qt.point(0, 0.5) }
            },
            State {
                name: "hovered"; when: hovered
                PropertyChanges { target: background; color: hoveredColor }
            },
            State {
                name: "normal"; when: !hovered
                PropertyChanges { target: background; color: normalColor }
            }
        ]

        transitions: [
            Transition {
                to: "normal"; reversible: true
                ColorAnimation { duration: root.duration }
            },
            Transition {
                to: "pressed"; reversible: true
                ParallelAnimation {
                    ColorAnimation { duration: root.duration }
                    NumberAnimation { duration: root.duration * 0.5 }
                }
            },
            Transition {
                to: ""; reversible: true
                ColorAnimation { duration: root.duration }
            }
        ]

        ResponsiveImage {
            id: image

            containerWidth: root.width
            containerHeight: root.height

            anchors.centerIn: parent

            source: {
                if (checkable && checkedImageSource)
                    return checked ? checkedImageSource : normalImageSource
                else
                    return ""
            }

            layer {
                enabled: imageColor || checkedColor
                effect: ColorOverlay {
                    id: overlay
                    color: {
                        if (checked && checkedColor) return checkedColor
                        else if (imageColor) return imageColor
                        else return JamiTheme.transparentColor
                    }
                }
            }
        }
    }
}
