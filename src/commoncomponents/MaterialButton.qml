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
import QtQuick.Layouts 1.14

import net.jami.Constants 1.0

Button {
    id: root

    property bool outlined: false
    property alias toolTipText: toolTip.text
    property alias iconSource: icon.source_
    property alias animatedIconSource: icon.animatedSource_
    property real iconSize: 18
    property var color: JamiTheme.buttonTintedBlue
    property var hoveredColor: JamiTheme.buttonTintedBlueHovered
    property var pressedColor: JamiTheme.buttonTintedBluePressed
    property var keysNavigationFocusColor: Qt.darker(hoveredColor, 2)

    property var preferredWidth
    Binding on width {
        when: root.preferredWidth !== undefined
        value: root.preferredWidth
    }
    Binding on Layout.preferredWidth {
        when: root.preferredWidth !== undefined
        value: width
    }

    property real preferredHeight: 36
    height: preferredHeight
    Layout.preferredHeight: height

    focusPolicy: Qt.TabFocus
    padding: 8

    MaterialToolTip {
        id: toolTip

        parent: root
        visible: hovered && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    property string contentColorProvider: {
        if (!root.outlined)
            return "white"
        if (root.hovered)
            return root.hoveredColor
        if (root.down)
            return root.pressedColor
        return root.color
    }

    contentItem: Item {
        id: item

        Binding on implicitWidth {
            when: root.preferredWidth === undefined
            value: item.childrenRect.width
        }
        implicitHeight: childrenRect.height
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            Binding on width {
                when: root.preferredWidth !== undefined
                value: root.availableWidth
            }
            spacing: Math.min(4, root.padding) + 4

            Component {
                id: iconComponent

                ResponsiveImage {
                    source: source_
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize
                    color: contentColorProvider
                }
            }

            Component {
                id: animatedIconComponent

                AnimatedImage {
                    source: animatedSource_
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize
                    width: iconSize
                    height: iconSize
                    playing: true
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
            }

            Loader {
                id: icon

                property string source_
                property string animatedSource_

                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: JamiTheme.preferredMarginSize / 2
                sourceComponent: animatedSource_.length === 0 ?
                                     iconComponent :
                                     animatedIconComponent
            }

            Text {
                // this right margin will make the text visually
                // centered within button
                Layout.rightMargin: root.preferredWidth !== undefined ?
                           iconSize + JamiTheme.preferredMarginSize +
                                        parent.spacing + root.padding :
                           0
                Layout.alignment: Qt.AlignHCenter
                text: root.text
                font: root.font
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: contentColorProvider
            }
        }
    }

    background: Rectangle {
        anchors.fill: parent
        color: {
            if (root.outlined)
                return "transparent"
            if (root.hovered)
                return root.hoveredColor
            if (root.down)
                return root.pressedColor
            return root.focus ?
                        root.keysNavigationFocusColor :
                        root.color
        }
        border.color: {
            if (!root.outlined)
                return "transparent"
            if (root.hovered)
                return root.hoveredColor
            if (root.down)
                return root.pressedColor
            return root.focus ?
                        root.keysNavigationFocusColor :
                        root.color
        }
        radius: JamiTheme.primaryRadius
    }

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.matches(StandardKey.InsertParagraphSeparator)) {
            clicked()
            keyEvent.accepted = true
        }
    }
}
