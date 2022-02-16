/*
 * Copyright (C) 2022 by Savoir-faire Linux
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

import "../../commoncomponents"
import "../../commoncomponents/contextmenu"

ContextMenuAutoLoader {
    id: root
    property var conversationId: ""
    property var participantUri: ""
    property var role

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: startVideoCallItem
            itemName: JamiStrings.startVideoCall
            canTrigger: ConversationsAdapter.dialogId(participantUri) !== ""
            iconSource: JamiResources.videocam_24dp_svg
            onClicked: {
                ConversationsAdapter.openDialogConversationWith(participantUri)
                CallAdapter.placeCall()
            }
        },
        GeneralMenuItem {
            id: startAudioCall
            itemName: JamiStrings.startAudioCall
            canTrigger: ConversationsAdapter.dialogId(participantUri) !== ""
            iconSource: JamiResources.place_audiocall_24dp_svg
            onClicked: {
                ConversationsAdapter.openDialogConversationWith(participantUri)
                CallAdapter.placeAudioOnlyCall()
            }
        },
        GeneralMenuItem {
            id: goToConversation

            iconSource: JamiResources.gotoconversation_svg
            itemName: JamiStrings.goToConversation
            onClicked: {
                if (ConversationsAdapter.dialogId(participantUri) !== "")
                    ConversationsAdapter.openDialogConversationWith(participantUri)
                else
                    ConversationsAdapter.setFilter(participantUri)
            }
        },
        GeneralMenuItem {
            id: blockContact
            itemName: JamiStrings.blockContact
            iconSource: JamiResources.block_black_24dp_svg
            onClicked: {
                ContactAdapter.removeContact(participantUri, true)
            }
        },
        GeneralMenuItem {
            id: kickMember
            itemName: JamiStrings.kickMember
            iconSource: JamiResources.kick_member_svg
            canTrigger: role === Member.Role.ADMIN

            onClicked: {
                MessagesAdapter.removeConversationMember(conversationId, participantUri)
            }
        }
    ]

    Component.onCompleted: menuItemsToLoad = menuItems
}
