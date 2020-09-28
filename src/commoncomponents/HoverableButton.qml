/*
 * Copyright (C) 2020 by Savoir-faire Linux
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
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.15
import QtQuick.Window 2.15
import "../constant"

// HoverableButton contains the following configurable properties:
// 1. Color changes on different button state
// 2. Radius control (rounded)
// 3. Text content or image content
// 4. Can use OnClicked slot to implement some click logic
//
// Note: if use text property directly, buttonTextColor will not work.
Button {
    id: hoverableButton

    checkable: true
    checked: false

    property int fontPointSize: 9

    property string buttonText: ""
    property string buttonTextColor: "black"

    property string backgroundColor: JamiTheme.releaseColor
    property string onPressColor: JamiTheme.pressColor
    property string onReleaseColor: JamiTheme.releaseColor
    property string onEnterColor: JamiTheme.hoverColor
    property string onExitColor: JamiTheme.releaseColor

    property alias radius: hoverableButtonBackground.radius
    property alias source: hoverableButtonImage.source
    property var checkedImage: ""
    property var baseImage: ""
    property var checkedColor: null
    property var baseColor: null
    property alias color: hoverableButton.baseColor
    property string toolTipText: ""

    radius: width

    font.pointSize: fontPointSize

    hoverEnabled: true

    text: "<font color=" + "'" + buttonTextColor + "'>" + buttonText + "</font>"

    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
    ToolTip.visible: hovered && (toolTipText.length > 0)
    ToolTip.text: toolTipText

    background: Rectangle {
        id: hoverableButtonBackground

        color: backgroundColor

        ResponsiveImage {
            id: hoverableButtonImage

            containerWidth: hoverableButton.width
            containerHeight: hoverableButton.height

            baseColor: hoverableButton.baseColor
            baseImage: hoverableButton.baseColor
            checked: hoverableButton.checked
            checkable: hoverableButton.checkable
            checkedColor: hoverableButton.checkedColor
            checkedImage: hoverableButton.checkedImage
        }

//        Image {
//            id: hoverableButtonImage

//            property real pixelDensity: Screen.pixelDensity
//            property int margin: 4
//            property real isSvg: {
//                var match = /[^.]+$/.exec(source)
//                return match.length > 0 && match[0] === 'svg'
//            }

//            anchors.centerIn: hoverableButtonBackground

////            width: buttonImageWidth
////            height: buttonImageHeight

////            width: isSvg ? hoverableButton.width - margin : hoverableButton.width
////            height: isSvg ? hoverableButton.width - margin : hoverableButton.height

//            width: isSvg ? hoverableButton.width - margin : hoverableButton.width
//            height: isSvg ? hoverableButton.width - margin : hoverableButton.height

//            fillMode: Image.PreserveAspectFit
//            mipmap: true
//            asynchronous: true

//            function setSourceSize() {
//                if (isSvg) {
//                    sourceSize.width = width
//                    sourceSize.height = height
//                } else
//                    sourceSize = undefined
//            }

//            onPixelDensityChanged: setSourceSize()
//            Component.onCompleted: setSourceSize()

//            source: {
//                if (checkable && checkedImage)
//                    return hoverableButton.checked ? checkedImage : baseImage
//                else
//                    return ""
//            }

//            layer {
//                enabled: true
//                effect: ColorOverlay {
//                    id: overlay
//                    color: hoverableButton.checked && checkedColor?
//                        checkedColor :
//                        (baseColor? baseColor : "transparent")
//                }
//            }
//        }

        MouseArea {
            anchors.fill: hoverableButtonBackground

            hoverEnabled: hoverableButton.hoverEnabled

            onPressed: {
                hoverableButtonBackground.color = onPressColor
            }
            onReleased: {
                hoverableButtonBackground.color = onReleaseColor
                hoverableButton.toggle()
                hoverableButton.clicked()
            }
            onEntered: {
                console.log("enter")
                hoverableButtonBackground.color = onEnterColor
            }
            onExited: {
                console.log("exit")
                hoverableButtonBackground.color = onExitColor
            }
        }
    }
}
