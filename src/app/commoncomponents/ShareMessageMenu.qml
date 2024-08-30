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
import "contextmenu"
import "../commoncomponents"
import "../mainview/components"

BaseContextMenu {
    id: mainMenu
    width: 300
    height: 350

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
            return parentX - width - 21;
        } else {
            return parentX + 21;
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

    // VERIFIER LES FONCTIONS DE POSITION
    // OMBRE ADDITIVE SI ON CLIQUE PLUSIEURS FOIS

    TextArea {
        id: messageInput
        width: parent.width - 30 - JamiTheme.chatViewFooterButtonSize
        placeholderText: "Add a comment (optionnal)"
        font.pointSize: JamiTheme.textFontSize + 2
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 20
        anchors.top: parent.top
        height: 45
        topPadding: 15
        topInset: 6
        wrapMode: Text.WordWrap

        background: Rectangle {
            color: "#f0f0f0"
            radius: 10
            border.color: "#cccccc"
            border.width: 1
        }
        onTextChanged: {
            height = messageInput.paintedHeight + 25;
        }
    }

    Rectangle {
        id: sendButton
        anchors.right: parent.right
        anchors.top: messageInput.top
        anchors.rightMargin: 10
        anchors.topMargin: 10
        visible: true

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
        id: contentToShareRect
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.top: messageInput.bottom
        height: childrenRect.height
        color: CurrentConversation.color // isOutgoing ? CurrentConversation.color : JamiTheme.messageInBgColor
        radius: 10
        border.color: "#cccccc"
        border.width: 1
        width: parent.width - 20
        anchors.horizontalCenter: parent.horizontalCenter

        Label {
            id: contentToShare
            visible: type === Interaction.Type.TEXT
            width: parent.width - 20
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.WordWrap
            rightInset: 10
            font.pointSize: JamiTheme.textFontSize + 2
            text: qsTr(msgBody)
            topPadding: 9
            color: "white"
        }
        Label {
            id: fileToShare
            visible: type === Interaction.Type.DATA_TRANSFER
            width: parent.width - 20
            height: 113
            anchors.horizontalCenter: parent.horizontalCenter

            FilesToShareDelegate {
            }

            padding: 5
            background: Rectangle {
                color: "lightblue"
                radius: JamiTheme.primaryRadius
            }
        }
        Component.onCompleted: {
            height = contentToShare.paintedHeight + 20;
        }
    }

    Rectangle {
        id: searchConv
        property int type: ContactList.CONVERSATION
        anchors.top: contentToShareRect.bottom
        anchors.topMargin: 10
        ColumnLayout {
            id: contactPickerPopupRectColumnLayout

            anchors.fill: parent

            Searchbar {
                id: contactPickerContactSearchBar

                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
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
                Layout.preferredHeight: 180
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                model: ConversationsAdapter.convListProxyModel // Same as the main searchbar, to unlink

                delegate: ConversationPickerItemDelegate {
                    id: conversationDelegate
                }
            }
        }
    }
}
