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
    width: preferredSize
    height: preferredSize

    property int fontPointSize: 9
    property alias source: image.source
    property string buttonText
    property string buttonTextColor: JamiTheme.primaryForegroundColor
    property string toolTipText: ""

    property string pressedColor: JamiTheme.pressedButtonColor
    property string hoveredColor: JamiTheme.hoveredButtonColor
    property string normalColor: JamiTheme.normalButtonColor

    property string normalImageSource

    property var checkedColor: null
    property string checkedImageSource

    property var baseColor: null
    property alias radius: background.radius

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

        color: {
            if (pressed) return pressedColor
            else if (hovered) return hoveredColor
            else return normalColor
        }

        ResponsiveImage {
            id: image

            containerWidth: root.width
            containerHeight: root.height

            source: {
                if (checkable && checkedImageSource)
                    return checked ? checkedImageSource : normalImageSource
                else
                    return ""
            }

            layer {
                enabled: true
                effect: ColorOverlay {
                    id: overlay
                    color: {
                        if (checked && checkedColor) return checkedColor
                        else if (baseColor) return baseColor
                        else return JamiTheme.transparentColor
                    }
                }
            }
        }
    }
}
