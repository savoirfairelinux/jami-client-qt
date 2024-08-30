/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Alexandre Eberhardt <alexandre.eberhardt@savoirfairelinux.com>
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
    width: 400
    height: 325 + messageInput.height

    required property string msgId
    required property string msgBody
    required property bool isOutgoing
    required property int type
    required property string transferName
    required property Item msgBubble
    required property ListView listView
    required property string author
    required property string formattedTime

    property string textToSend: "message shared from " + author + "sent at " + formattedTime + " : " + msgBody
    property var selectedUids: []
    property var shareToId: msgId
    property var fileLink: msgBody
    function xPosition(width) {
        // Use the width at function scope to retrigger property evaluation.
        const listViewWidth = listView.width;
        const parentX = parent.x;
        if (isOutgoing) {
            return parentX - width + 10;
        } else {
            return parentX - 10;
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
    }

    // VERIFIER LES FONCTIONS DE POSITION
    Rectangle {
        id: header
        width: parent.width
        height: 0
    }

    Rectangle {
        id: sendButton

        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.topMargin: 10
        anchors.top: header.bottom
        visible: true
        height: JamiTheme.chatViewFooterButtonSize

        PushButton {
            id: shareMessageButton

            objectName: "shareMessageButton"
            anchors.right: parent.right

            visible: true

            hoverEnabled: enabled

            width: scale * JamiTheme.chatViewFooterButtonSize
            height: JamiTheme.chatViewFooterButtonSize

            radius: JamiTheme.chatViewFooterButtonRadius
            preferredSize: JamiTheme.chatViewFooterButtonIconSize - 6
            imageContainerWidth: 25
            imageContainerHeight: 25

            toolTipText: JamiStrings.share

            mirror: UtilsAdapter.isRTL

            source: JamiResources.send_black_24dp_svg

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
                    if (messageInput.text && selectedContacts.length > 0) {
                        for (var j = 0; j < selectedContacts.length; j++) {
                            if (Type === 2)
                                MessagesAdapter.sendMessageToUid(msgBody, selectedContacts[j]);
                            else
                                MessagesAdapter.sendFileToUid(fileLink, selectedContacts[j]);
                            MessagesAdapter.sendMessageToUid(messageInput.text, selectedContacts[j]);
                        }
                        messageInput.text = "";
                    } else if (selectedContacts.length > 0) {
                        for (var l = 0; l < selectedContacts.length; l++) {
                            if (Type === 2)
                                MessagesAdapter.sendMessageToUid(msgBody, selectedContacts[l]);
                            else
                                MessagesAdapter.sendFileToUid(fileLink, selectedContacts[l]);
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: searchConv
        property int type: ContactList.CONVERSATION
        anchors.top: header.bottom
        anchors.topMargin: 10
        width: parent.width
        height: 300
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
                    //ConversationsAdapter.ignoreFiltering(root.highlighted); // pas sur
                    ConversationsAdapter.setFilter(text);
                }
            }

            JamiListView {
                id: contactPickerListView
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredHeight: 255
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                model: shareConvProxyModel

                delegate: ConversationPickerItemDelegate {
                    id: conversationDelegate
                }
            }
        }
    }

    TextArea {
        id: messageInput
        width: parent.width - 20
        placeholderText: "Add a comment (optionnal)"
        font.pointSize: JamiTheme.textFontSize + 2
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 5
        anchors.top: searchConv.bottom
        height: 35
        topPadding: 7
        wrapMode: Text.WordWrap

        background: Rectangle {
            color: JamiTheme.transparentColor
            radius: 5
            border.color: JamiTheme.chatViewFooterRectangleBorderColor
            border.width: 2
        }
        onTextChanged: {
            height = messageInput.paintedHeight + 25;
        }
    }

    onAboutToHide: {
        mainMenu.destroy();
    }

    Component.onDestruction: {
        parent.bind();
    }
}
