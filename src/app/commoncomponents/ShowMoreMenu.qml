/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import Qt5Compat.GraphicalEffects
import QtQuick.Controls
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import "contextmenu"

BaseContextMenu {
    id: root

    required property var emojiReactions
    property var emojiReplied: emojiReactions.ownEmojis

    required property string msgId
    required property string msgBody
    required property bool isOutgoing
    required property int type
    required property string transferName
    required property Item msgBubble
    required property ListView listView

    property string location: msgBody
    property bool closeWithoutAnimation: false
    property var emojiPicker

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

    signal addMoreEmoji
    onAddMoreEmoji: {
        JamiQmlUtils.updateMessageBarButtonsPoints();
        openEmojiPicker();
    }

    function openEmojiPicker() {
        var component = WITH_WEBENGINE ? Qt.createComponent("qrc:/webengine/emojipicker/EmojiPicker.qml") : Qt.createComponent("qrc:/nowebengine/EmojiPicker.qml");
        emojiPicker = component.createObject(root.parent, {
                "listView": listView
            });
        emojiPicker.emojiIsPicked.connect(function (content) {
                if (emojiReplied.includes(content)) {
                    MessagesAdapter.removeEmojiReaction(CurrentConversation.id, content, msgId);
                } else {
                    MessagesAdapter.addEmojiReaction(CurrentConversation.id, content, msgId);
                }
            });
        if (emojiPicker !== null) {
            root.opacity = 0;
            emojiPicker.x = xPositionProvider(JamiTheme.emojiPickerWidth);
            emojiPicker.y = yPositionProvider(JamiTheme.emojiPickerHeight);
            emojiPicker.open();
        } else {
            console.log("Error creating emojiPicker from message options popup");
        }
    }

    property real listViewHeight: listView.height
    property bool isScrolling: listView.verticalScrollBar.active

    onOpened: root.closeWithoutAnimation = false
    onClosed: if (emojiPicker)
        emojiPicker.closeEmojiPicker()

    function getQuickEmojiListModel() {
        const defaultModel = ["👍", "👎", "😂"];
        const reactedEmojis = Array.isArray(emojiReplied) ? emojiReplied.slice(0, defaultModel.length) : [];
        const uniqueEmojis = Array.from(new Set(reactedEmojis));
        const missingEmojis = defaultModel.filter(emoji => !uniqueEmojis.includes(emoji));
        const result = uniqueEmojis.concat(missingEmojis);
        return result;
    }

    property list<MenuItem> menuItems: [
        GeneralMenuItemList {
            id: emojiQuickReactions

            modelList: getQuickEmojiListModel()
            canTrigger: true
            iconSource: JamiResources.add_reaction_svg
            itemName: JamiStrings.copy
            addMenuSeparatorAfter: true
            messageId: msgId
        },
        GeneralMenuItem {
            id: saveFile

            canTrigger: type === Interaction.Type.DATA_TRANSFER
            iconSource: JamiResources.save_file_svg
            itemName: JamiStrings.saveFile
            onClicked: {
                MessagesAdapter.copyToDownloads(root.msgId, root.transferName);
            }
        },
        GeneralMenuItem {
            id: openLocation

            canTrigger: type === Interaction.Type.DATA_TRANSFER
            iconSource: JamiResources.round_folder_24dp_svg
            itemName: JamiStrings.openLocation
            onClicked: {
                MessagesAdapter.openDirectory(root.location);
            }
        },
        GeneralMenuItem {
            id: removeLocally

            canTrigger: type === Interaction.Type.DATA_TRANSFER && TransferStatus === Interaction.TransferStatus.TRANSFER_FINISHED
            iconSource: JamiResources.trash_black_24dp_svg
            itemName: JamiStrings.removeLocally
            onClicked: {
                MessagesAdapter.removeFile(msgId, root.location);
                ;
            }
        },
        GeneralMenuItem {
            id: editMessage

            canTrigger: root.isOutgoing && type === Interaction.Type.TEXT
            iconSource: JamiResources.edit_svg
            itemName: JamiStrings.editMessage
            onClicked: {
                MessagesAdapter.replyToId = "";
                MessagesAdapter.editId = root.msgId;
            }
        },
        GeneralMenuItem {
            id: deleteMessage

            canTrigger: root.isOutgoing && (type === Interaction.Type.TEXT || type === Interaction.Type.DATA_TRANSFER)
            iconSource: JamiResources.delete_svg
            itemName: JamiStrings.deleteMessage
            onClicked: {
                MessagesAdapter.editMessage(CurrentConversation.id, "", root.msgId);
            }
        },
        GeneralMenuItem {
            id: copyMessage

            canTrigger: true
            iconSource: JamiResources.copy_svg
            itemName: JamiStrings.copy
            onClicked: {
                UtilsAdapter.setClipboardText(msgBody);
            }
        }
    ]

    Component.onCompleted: {
        root.loadMenuItems(menuItems);
    }

    // destroy() and setBindings() are needed to unselect the share icon from SBSMessageBase

    onAboutToHide: {
        root.destroy();
    }

    Component.onDestruction: {
        parent.setBindings();
    }
}
