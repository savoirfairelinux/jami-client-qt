/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "."
import "contextmenu"

ContextMenuAutoLoader {
    id: root

    property string location
    property bool isOutgoing
    property string msgId
    property string transferName
    property string transferId

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: saveFile

            canTrigger: root.transferId !== ""
            itemName: JamiStrings.saveFile
            iconSource: JamiResources.save_file_svg
            onClicked: MessagesAdapter.copyToDownloads(root.transferId, root.transferName)
        },
        GeneralMenuItem {
            id: openLocation

            canTrigger: root.transferId !== ""
            itemName: JamiStrings.openLocation
            iconSource: JamiResources.round_folder_24dp_svg
            onClicked: {
                MessagesAdapter.openDirectory(root.location);
            }
        },
        GeneralMenuItem {
            id: reply

            itemName: JamiStrings.reply
            iconSource: JamiResources.reply_black_24dp_svg
            onClicked: {
                MessagesAdapter.editId = "";
                MessagesAdapter.replyToId = root.msgId;
            }
        },
        GeneralMenuItem {
            id: edit

            canTrigger: transferId === "" && isOutgoing
            itemName: JamiStrings.edit
            iconSource: JamiResources.edit_svg
            onClicked: {
                MessagesAdapter.replyToId = "";
                MessagesAdapter.editId = root.msgId;
            }
        },
        GeneralMenuItem {
            id: deleteMsg
            dangerous: true

            canTrigger: transferId === "" && isOutgoing
            itemName: JamiStrings.optionDelete
            iconSource: JamiResources.delete_svg
            onClicked: {
                MessagesAdapter.editMessage(CurrentConversation.id, "", root.msgId);
            }
        }
    ]

    Component.onCompleted: menuItemsToLoad = menuItems
}
