/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../mainview/components"

Popup {
    id: root
    padding: 0
    property list<Action> menuMoreButton

    height: childrenRect.height
    width: childrenRect.width

    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Rectangle {
        id: rect

        color: JamiTheme.primaryBackgroundColor
        border.color: JamiTheme.chatViewFooterRectangleBorderColor
        border.width: 2
        radius: 5
        height: listViewMoreButton.childrenRect.height + 16
        width: listViewMoreButton.childrenRect.width + 16

        ListView {
            id: listViewMoreButton

            anchors.centerIn: parent
            orientation: ListView.Vertical

            spacing: 0

            width: contentItem.childrenRect.width
            height: contentHeight

            model: menuMoreButton

            Rectangle {
                z: -1
                anchors.fill: parent
                color: "transparent"
            }

            onCountChanged: {
                for (var i = 0; i < count; i++) {
                    var item = listViewMoreButton.itemAtIndex(i);
                    item.width = listViewMoreButton.width;
                }
            }

            delegate: ItemDelegate {
                id: control

                text: modelData.toolTip

                contentItem: RowLayout {
                    Rectangle {
                        id: image
                        width: 20
                        height: 20
                        radius: 5
                        color: JamiTheme.transparentColor
                        ResponsiveImage {
                            anchors.fill: parent
                            source: modelData.iconSrc
                            color: control.hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignLeft
                        text: control.text
                        color: JamiTheme.chatViewFooterImgHoverColor
                        font.pixelSize: JamiTheme.chatViewFooterFontSize
                    }
                }
                background: Rectangle {
                    color: control.hovered ? JamiTheme.showMoreButtonOpenColor : JamiTheme.transparentColor
                }

                action: modelData

                onClicked: {
                    root.close();
                }
            }
        }
    }

    DropShadow {
        z: -1

        width: rect.width
        height: rect.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: rect.radius * 4
        color: JamiTheme.shadowColor
        source: rect
        transparentBorder: true
        samples: radius + 1
    }

    background: Rectangle {
        anchors.fill: parent
        color: JamiTheme.transparentColor
        radius: 5
        z: -1
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 0.0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }
    exit: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 1.0
            to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
