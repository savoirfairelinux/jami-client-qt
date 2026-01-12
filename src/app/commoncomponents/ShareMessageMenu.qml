/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import SortFilterProxyModel 0.2
import "contextmenu"
import "../commoncomponents"
import "../mainview/components"

BaseContextMenu {
    id: mainMenu

    height: 330 + Math.min(messageInput.height, textareaMaxHeight)
    width: 400

    required property string msgId
    required property string msgBody
    required property bool isOutgoing
    required property int type
    required property string transferName
    required property Item msgBubble
    required property ListView listView
    required property string author
    required property string formattedTime

    property var selectedUids: []
    property string shareToId: msgId
    property string fileLink: msgBody
    property int textareaMaxHeight: 350
    function xPosition(width) {
        // Use the width at function scope to retrigger property evaluation.
        const listViewWidth = listView.width;
        const parentX = parent.x;
        if (isOutgoing) {
            return parentX - width - 20;
        } else {
            return parentX + 20;
        }
    }

    x: xPosition(width)
    y: parent.y

    function xPositionProvider(width) {
        // Use the width at function scope to retrigger property evaluation.
        const listViewWidth = listView.width;
        if (isOutgoing) {
            return -5 - width;
        } else {
            const rightMargin = listViewWidth - (msgBubble.x + width);
            return width > rightMargin + 35 ? -5 - width : 35;
        }
    }
    function yPositionProvider(height) {
        const topOffset = msgBubble.mapToItem(listView, 0, 0).y;
        const listViewHeight = listView.height;
        const bottomMargin = listViewHeight - height - topOffset;
        if (bottomMargin < 0 || (topOffset < 0 && topOffset + height > 0)) {
            return 30 - height;
        } else {
            return 0;
        }
    }

    SortFilterProxyModel {
        id: shareConvProxyModel

        sourceModel: ConversationsAdapter.convListProxyModel
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    Rectangle {
        id: header

        width: parent.width
        height: 0
    }

    Rectangle {
        id: sendButton

        height: JamiTheme.chatViewFooterButtonSize
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.topMargin: 10
        anchors.top: header.bottom
        color: JamiTheme.transparentColor

        PushButton {
            id: shareMessageButton

            height: JamiTheme.chatViewFooterButtonSize
            width: scale * JamiTheme.chatViewFooterButtonSize
            anchors.right: parent.right

            visible: true

            radius: JamiTheme.chatViewFooterButtonRadius
            preferredSize: JamiTheme.chatViewFooterButtonIconSize - 6
            imageContainerWidth: 25
            imageContainerHeight: 25

            toolTipText: JamiStrings.share

            mirror: UtilsAdapter.isRTL

            source: JamiResources.send_black_24dp_svg

            hoverEnabled: enabled
            normalColor: enabled ? JamiTheme.chatViewFooterSendButtonColor : JamiTheme.chatViewFooterSendButtonDisableColor
            imageColor: enabled ? JamiTheme.chatViewFooterSendButtonImgColor : JamiTheme.chatViewFooterSendButtonImgColorDisable
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: hoveredColor

            opacity: 1
            scale: opacity

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    var selectedContacts = mainMenu.selectedUids;
                    var hasText = messageInput.text && selectedContacts.length > 0;
                    function sendMessageOrFile(uid) {
                        if (Type === 2) {
                            // 2=TEXT and 5=DATA_TRANSFER (any kind of file) defined in interaction.h
                            MessagesAdapter.sendMessageToUid(msgBody, uid);
                        } else {
                            MessagesAdapter.sendFileToUid(fileLink, uid);
                        }
                    }
                    for (var i = 0; i < selectedContacts.length; i++) {
                        var uid = selectedContacts[i];
                        sendMessageOrFile(uid);
                        if (hasText) {
                            MessagesAdapter.sendMessageToUid(messageInput.text, uid);
                        }
                    }
                    messageInput.text = "";
                    mainMenu.destroy();
                }
            }
        }
    }

    Rectangle {
        id: searchConv

        height: 300
        width: parent.width
        anchors.top: header.bottom
        anchors.topMargin: 10

        property int type: ContactList.CONVERSATION

        color: JamiTheme.transparentColor
        ColumnLayout {
            id: contactPickerPopupRectColumnLayout

            anchors.fill: parent
            Searchbar {
                id: contactPickerContactSearchBar

                width: parent.width - 20 - JamiTheme.chatViewFooterButtonSize
                anchors.leftMargin: 10
                Layout.preferredHeight: 35
                placeHolderText: "Share to..."
                onSearchBarTextChanged: function (text) {
                    shareConvProxyModel.filterRole = shareConvProxyModel.roleForName("Title");
                    shareConvProxyModel.filterPattern = text;
                }
            }
            JamiListView {
                id: contactPickerListView

                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredHeight: 255
                Layout.bottomMargin: JamiTheme.preferredMarginSize
                Layout.topMargin: 5

                model: shareConvProxyModel

                delegate: ConversationPickerItemDelegate {
                    id: conversationDelegate
                }
            }
        }
    }

    Flickable {
        id: messageInputContainer

        height: Math.min(contentHeight, mainMenu.textareaMaxHeight)
        width: parent.width - 20
        contentHeight: messageInput.height
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 10
        anchors.top: searchConv.bottom

        flickableDirection: Flickable.VerticalFlick
        clip: true

        ScrollBar.vertical: JamiScrollBar {
            policy: ScrollBar.AsNeeded
        }

        onContentHeightChanged: {
            if (contentHeight > height) {
                contentY = contentHeight - height;
            }
        }

        TextArea {
            id: messageInput

            height: contentHeight + 12
            width: parent.width
            placeholderText: "Add a comment"
            placeholderTextColor: JamiTheme.messageBarPlaceholderTextColor
            font.pointSize: JamiTheme.textFontSize + 2
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap

            background: Rectangle {
                color: JamiTheme.transparentColor
                radius: 5
                border.color: JamiTheme.chatViewFooterRectangleBorderColor
                border.width: 2
            }
        }
    }

    // destroy() and setBindings() are needed to unselect the share icon from SBSMessageBase

    onAboutToHide: {
        mainMenu.destroy();
    }

    Component.onDestruction: {
        parent.setBindings();
    }
}
