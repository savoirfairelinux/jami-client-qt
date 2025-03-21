/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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

    // Shape will default to a 15px circle
    // but can be sized accordingly.
    property int preferredSize: 30
    property int preferredHeight: 0
    property int preferredWidth: 0
    property int preferredLeftMargin: 16
    property int preferredRightMargin: 16
    // Note the radius will default to preferredSize
    property bool circled: true
    property alias radius: background.radius
    property alias border: background.border

    // Text properties
    property alias buttonText: textContent.text
    property alias buttonTextHeight: textContent.height
    readonly property alias buttonTextWidth: textContent.width
    property alias buttonTextFont: textContent.font
    property alias buttonTextColor: textContent.color
    property alias textHAlign: textContent.horizontalAlignment
    property bool buttonTextEnableElide: false
    property alias alignement: textContent.horizontalAlignment
    property alias toolTipText: toolTip.text
    property alias hasShortcut: toolTip.hasShortcut
    property alias shortcutKey: toolTip.shortcutKey
    property int buttonTextFontSize: 12

    // State colors
    property string pressedColor: JamiTheme.pressedButtonColor
    property string hoveredColor: JamiTheme.hoveredButtonColor
    property string normalColor: JamiTheme.normalButtonColor
    property string checkedColor: pressedColor

    // State transition duration
    property int duration: JamiTheme.shortFadeDuration

    // Image properties
    property alias imageContainerWidth: image.containerWidth
    property alias imageContainerHeight: image.containerHeight
    property alias source: image.source
    property var imageColor: null
    property string normalImageSource
    property var checkedImageColor: null
    property string checkedImageSource
    property alias imagePadding: image.padding
    property alias imageOffset: image.offset

    property alias mirror: image.mirror

    width: preferredWidth ? preferredWidth : preferredSize
    height: preferredHeight ? preferredHeight : preferredSize

    checkable: false
    checked: false
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    property bool forceHovered: false

    Accessible.role: Accessible.Button
    Accessible.name: buttonText
    Accessible.description: toolTipText

    MaterialToolTip {
        id: toolTip

        parent: root
        visible: hovered && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    ResponsiveImage {
        id: image

        anchors.centerIn: textContent.text ? undefined : root
        anchors.left: textContent.text ? root.left : undefined
        anchors.leftMargin: textContent.text ? preferredLeftMargin : 0
        anchors.verticalCenter: root.verticalCenter

        containerWidth: preferredWidth ? preferredWidth : preferredSize
        containerHeight: preferredHeight ? preferredHeight : preferredSize

        source: {
            if (checkable && checkedImageSource)
                return checked ? checkedImageSource : normalImageSource;
            else
                return normalImageSource;
        }

        color: {
            if (checked && checkedImageColor)
                return checkedImageColor;
            else if (imageColor)
                return imageColor;
            else
                return JamiTheme.transparentColor;
        }
    }

    Text {
        id: textContent

        anchors.left: image.status !== Image.Null ? image.right : root.left
        anchors.leftMargin: preferredLeftMargin
        anchors.verticalCenter: root.verticalCenter

        anchors.right: buttonTextEnableElide ? root.right : undefined
        anchors.rightMargin: preferredRightMargin

        visible: text ? true : false

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        color: JamiTheme.primaryForegroundColor
        font.kerning: true
        font.pixelSize: buttonTextFontSize
        elide: Qt.ElideRight
    }

    background: Rectangle {
        id: background

        radius: circled ? preferredSize : 5
        color: normalColor

        states: [
            State {
                name: "checked"
                when: checked
                PropertyChanges {
                    target: background
                    color: checkedColor
                }
            },
            State {
                name: "pressed"
                when: pressed
                PropertyChanges {
                    target: background
                    color: pressedColor
                }
            },
            State {
                name: "hovered"
                when: hovered
                PropertyChanges {
                    target: background
                    color: hoveredColor
                }
            },
            State {
                name: "forceHovered"
                when: forceHovered
                PropertyChanges {
                    target: background
                    color: hoveredColor
                }
            },
            State {
                name: "normal"
                when: !hovered && !checked
                PropertyChanges {
                    target: background
                    color: normalColor
                }
            }
        ]

        transitions: [
            Transition {
                to: "normal"
                reversible: true
                enabled: duration
                ColorAnimation {
                    duration: root.duration
                }
            },
            Transition {
                to: "pressed"
                reversible: true
                enabled: duration
                ColorAnimation {
                    duration: root.duration * 0.5
                }
            },
            Transition {
                to: ""
                reversible: true
                enabled: duration
                ColorAnimation {
                    duration: root.duration
                }
            }
        ]
    }

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            clicked();
            keyEvent.accepted = true;
        }
    }
}
