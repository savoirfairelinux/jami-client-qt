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

    height: 400
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

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12

        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 35

            Searchbar {
                id: contactPickerContactSearchBar

                Layout.fillWidth: true
                Layout.preferredHeight: 35
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                placeHolderText: JamiStrings.shareWith

                onSearchBarTextChanged: function (text) {
                    shareConvProxyModel.filterRole = shareConvProxyModel.roleForName("Title");
                    shareConvProxyModel.filterPattern = text;
                }
            }

            NewIconButton {
                id: shareMessageButton

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.send_black_24dp_svg
                toolTipText: JamiStrings.share

                visible: true

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

        JamiListView {
            id: contactPickerListView

            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.bottomMargin: JamiTheme.preferredMarginSize
            Layout.topMargin: 5

            model: shareConvProxyModel

            delegate: ConversationPickerItemDelegate {
                id: conversationDelegate
            }
        }

        Rectangle {
            id: messageinputBackground

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(messageInput.contentHeight + 8, 100)
            Layout.maximumHeight: 100

            color: JamiTheme.transparentColor
            radius: JamiTheme.shareMessageMenuMessageInputRadius
            border.color: JamiTheme.chatViewFooterRectangleBorderColor
            border.width: 2
            clip: true

            Flickable {
                id: messageInputContainer

                anchors.fill: parent
                anchors.rightMargin: 6
                anchors.bottomMargin: 2

                flickableDirection: Flickable.VerticalFlick
                contentHeight: messageInput.implicitHeight
                contentWidth: messageInput.width

                ScrollBar.vertical: JamiScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                TextArea {
                    id: messageInput

                    width: messageInputContainer.width

                    verticalAlignment: Text.AlignVCenter

                    placeholderText: JamiStrings.addAComment
                    placeholderTextColor: JamiTheme.messageBarPlaceholderTextColor

                    font.pointSize: JamiTheme.textFontSize + 2

                    color: JamiTheme.textColor

                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                    background: Rectangle {
                        color: JamiTheme.transparentColor
                    }
                }
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
