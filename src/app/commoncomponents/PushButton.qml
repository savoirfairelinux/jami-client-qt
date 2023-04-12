/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import net.jami.Constants 1.1

// PushButton contains the following configurable properties:
// - colored states
// - radius
// - minimal support for text
// - animation duration
// TODO: allow transparent background tinted text/icon
AbstractButton {
    id: root
    property alias alignement: textContent.horizontalAlignment
    property alias border: background.border

    // Text properties
    property alias buttonText: textContent.text
    property alias buttonTextColor: textContent.color
    property bool buttonTextEnableElide: false
    property alias buttonTextFont: textContent.font
    property alias buttonTextHeight: textContent.height
    readonly property alias buttonTextWidth: textContent.width
    property string checkedColor: pressedColor
    property var checkedImageColor: null
    property string checkedImageSource
    // Note the radius will default to preferredSize
    property bool circled: true

    // State transition duration
    property int duration: JamiTheme.shortFadeDuration
    property bool forceHovered: false
    property string hoveredColor: JamiTheme.hoveredButtonColor
    property var imageColor: null
    property alias imageContainerHeight: image.containerHeight

    // Image properties
    property alias imageContainerWidth: image.containerWidth
    property alias imageOffset: image.offset
    property alias imagePadding: image.padding
    property string normalColor: JamiTheme.normalButtonColor
    property string normalImageSource
    property int preferredHeight: 0
    property int preferredLeftMargin: 16
    property int preferredRightMargin: 16

    // Shape will default to a 15px circle
    // but can be sized accordingly.
    property int preferredSize: 30
    property int preferredWidth: 0

    // State colors
    property string pressedColor: JamiTheme.pressedButtonColor
    property alias radius: background.radius
    property alias source: image.source
    property alias textHAlign: textContent.horizontalAlignment
    property alias toolTipText: toolTip.text

    Accessible.description: toolTipText
    Accessible.name: buttonText
    Accessible.role: Accessible.Button
    checkable: false
    checked: false
    focusPolicy: Qt.TabFocus
    height: preferredHeight ? preferredHeight : preferredSize
    hoverEnabled: true
    width: preferredWidth ? preferredWidth : preferredSize

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            clicked();
            keyEvent.accepted = true;
        }
    }

    MaterialToolTip {
        id: toolTip
        delay: Qt.styleHints.mousePressAndHoldInterval
        parent: root
        visible: hovered && (toolTipText.length > 0)
    }
    ResponsiveImage {
        id: image
        anchors.centerIn: textContent.text ? undefined : root
        anchors.left: textContent.text ? root.left : undefined
        anchors.leftMargin: textContent.text ? preferredLeftMargin : 0
        anchors.verticalCenter: root.verticalCenter
        color: {
            if (checked && checkedImageColor)
                return checkedImageColor;
            else if (imageColor)
                return imageColor;
            else
                return JamiTheme.transparentColor;
        }
        containerHeight: preferredHeight ? preferredHeight : preferredSize
        containerWidth: preferredWidth ? preferredWidth : preferredSize
        source: {
            if (checkable && checkedImageSource)
                return checked ? checkedImageSource : normalImageSource;
            else
                return normalImageSource;
        }
    }
    Text {
        id: textContent
        anchors.left: image.status !== Image.Null ? image.right : root.left
        anchors.leftMargin: preferredLeftMargin
        anchors.right: buttonTextEnableElide ? root.right : undefined
        anchors.rightMargin: preferredRightMargin
        anchors.verticalCenter: root.verticalCenter
        color: JamiTheme.primaryForegroundColor
        elide: Qt.ElideRight
        font.kerning: true
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        visible: text ? true : false
    }

    background: Rectangle {
        id: background
        color: normalColor
        radius: circled ? preferredSize : 5

        states: [
            State {
                name: "checked"
                when: checked

                PropertyChanges {
                    color: checkedColor
                    target: background
                }
            },
            State {
                name: "pressed"
                when: pressed

                PropertyChanges {
                    color: pressedColor
                    target: background
                }
            },
            State {
                name: "hovered"
                when: hovered || root.focus

                PropertyChanges {
                    color: hoveredColor
                    target: background
                }
            },
            State {
                name: "forceHovered"
                when: forceHovered || root.focus

                PropertyChanges {
                    color: hoveredColor
                    target: background
                }
            },
            State {
                name: "normal"
                when: !hovered && !checked

                PropertyChanges {
                    color: normalColor
                    target: background
                }
            }
        ]
        transitions: [
            Transition {
                enabled: duration
                reversible: true
                to: "normal"

                ColorAnimation {
                    duration: root.duration
                }
            },
            Transition {
                enabled: duration
                reversible: true
                to: "pressed"

                ColorAnimation {
                    duration: root.duration * 0.5
                }
            },
            Transition {
                enabled: duration
                reversible: true
                to: ""

                ColorAnimation {
                    duration: root.duration
                }
            }
        ]
    }
}
