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
import QtQuick.Layouts
import net.jami.Constants 1.1
import "../"
import net.jami.Adapters 1.1

// General menu item.
// Can control top, bottom, left, right border width.
// Use onClicked slot to simulate item click event.
// Can have image icon at the left of the text.
MenuItem {
    id: menuItem

    property var modelList: undefined
    property string itemName: ""
    property var iconSource: undefined
    property string iconColor: ""
    property bool canTrigger: true
    property bool hasIcon: true
    property bool addMenuSeparatorAfter: false
    property bool autoTextSizeAdjustment: true
    property bool dangerous: false
    property BaseContextMenu parentMenu
    property string messageId

    signal addMoreEmoji

    property int itemPreferredWidth: 207
    property int itemRealWidth: itemPreferredWidth
    property int itemPreferredHeight: JamiTheme.menuItemsPreferredHeight
    property int leftBorderWidth: JamiTheme.menuItemsCommonBorderWidth
    property int rightBorderWidth: JamiTheme.menuItemsCommonBorderWidth

    property int itemImageLeftMargin: 18

    signal clicked

    width: itemRealWidth

    contentItem: Item {
        id: menuItemContentRect

        anchors.fill: parent

        RowLayout {
            spacing: 0

            anchors.fill: menuItemContentRect

            Rectangle {
                id: contextMenuItemImage
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.leftMargin: itemImageLeftMargin
                height: 36
                width: 36
                color: emojiReplied.includes(modelList[0]) ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor
                radius: 5
                Behavior on color  {
                    ColorAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: modelList[0]
                    font.pointSize: JamiTheme.emojiBubbleSize
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        contextMenuItemImage.color = JamiTheme.hoveredButtonColor;
                    }
                    onExited: {
                        contextMenuItemImage.color = emojiReplied.includes(modelList[0]) ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor;
                    }
                    onClicked: {
                        if (emojiReplied.includes(modelList[0])) {
                            MessagesAdapter.removeEmojiReaction(CurrentConversation.id, modelList[0], msgId);
                        } else {
                            MessagesAdapter.addEmojiReaction(CurrentConversation.id, modelList[0], msgId);
                        }
                        close();
                    }
                }
            }

            Rectangle {
                id: contextMenuItemImage2
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.leftMargin: itemImageLeftMargin / 2
                height: 36
                width: 36
                color: emojiReplied.includes(modelList[1]) ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor
                radius: 5
                Behavior on color  {
                    ColorAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: modelList[1]
                    font.pointSize: JamiTheme.emojiBubbleSize
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        contextMenuItemImage2.color = JamiTheme.hoveredButtonColor;
                    }
                    onExited: {
                        contextMenuItemImage2.color = emojiReplied.includes(modelList[1]) ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor;
                    }
                    onClicked: {
                        if (emojiReplied.includes(modelList[1])) {
                            MessagesAdapter.removeEmojiReaction(CurrentConversation.id, modelList[1], msgId);
                        } else {
                            MessagesAdapter.addEmojiReaction(CurrentConversation.id, modelList[1], msgId);
                        }
                        close();
                    }
                }
            }

            Rectangle {
                id: contextMenuItemImage3
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.leftMargin: itemImageLeftMargin / 2
                height: 36
                width: 36
                color: emojiReplied.includes(modelList[2]) ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor
                radius: 5
                Behavior on color  {
                    ColorAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: modelList[2]
                    font.pointSize: JamiTheme.emojiBubbleSize
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        contextMenuItemImage3.color = JamiTheme.hoveredButtonColor;
                    }
                    onExited: {
                        contextMenuItemImage3.color = emojiReplied.includes(modelList[2]) ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor;
                    }
                    onClicked: {
                        if (emojiReplied.includes(modelList[2])) {
                            MessagesAdapter.removeEmojiReaction(CurrentConversation.id, modelList[2], msgId);
                        } else {
                            MessagesAdapter.addEmojiReaction(CurrentConversation.id, modelList[2], msgId);
                        }
                        close();
                    }
                }
            }

            PushButton {
                id: contextMenuItemImage4
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.leftMargin: itemImageLeftMargin / 2
                Layout.rightMargin: itemImageLeftMargin
                height: 36
                width: 36
                imageColor: hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor
                normalColor: JamiTheme.primaryBackgroundColor
                radius: 5
                source: iconSource
                onClicked: {
                    root.addMoreEmoji();
                }
            }
        }
    }

    highlighted: true

    background: Rectangle {
        id: contextMenuBackgroundRect

        anchors.fill: parent
        anchors.leftMargin: leftBorderWidth
        anchors.rightMargin: rightBorderWidth

        color: JamiTheme.primaryBackgroundColor

        implicitWidth: itemRealWidth
        implicitHeight: itemPreferredHeight

        border.width: 0

        CustomBorder {
            commonBorder: false
            lBorderwidth: leftBorderWidth
            rBorderwidth: rightBorderWidth
            tBorderwidth: 0
            bBorderwidth: 0
            borderColor: JamiTheme.primaryBackgroundColor
        }
    }
}
