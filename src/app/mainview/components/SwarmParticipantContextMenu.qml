/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: startVideoCallItem
            canTrigger: ConversationsAdapter.dialogId(participantUri) !== ""
            iconSource: JamiResources.videocam_24dp_svg
            itemName: JamiStrings.startVideoCall

            onClicked: {
                ConversationsAdapter.openDialogConversationWith(participantUri);
                CallAdapter.placeCall();
            }
        },
        GeneralMenuItem {
            id: startAudioCall
            canTrigger: ConversationsAdapter.dialogId(participantUri) !== ""
            iconSource: JamiResources.place_audiocall_24dp_svg
            itemName: JamiStrings.startAudioCall

            onClicked: {
                ConversationsAdapter.openDialogConversationWith(participantUri);
                CallAdapter.placeAudioOnlyCall();
            }
        },
        GeneralMenuItem {
            id: goToConversation
            iconSource: JamiResources.gotoconversation_svg
            itemName: JamiStrings.goToConversation

            onClicked: {
                if (ConversationsAdapter.dialogId(participantUri) !== "")
                    ConversationsAdapter.openDialogConversationWith(participantUri);
                else
                    ConversationsAdapter.setFilter(participantUri);
            }
        },
        GeneralMenuItem {
            id: blockContact
            iconSource: JamiResources.block_black_24dp_svg
            itemName: JamiStrings.blockContact

            onClicked: {
                ContactAdapter.removeContact(participantUri, true);
            }
        },
        GeneralMenuItem {
            id: kickMember
            property var memberRole: UtilsAdapter.getParticipantRole(CurrentAccount.id, conversationId, participantUri)

            canTrigger: role === Member.Role.ADMIN
            iconSource: JamiResources.kick_member_svg
            itemName: memberRole === Member.Role.BANNED ? JamiStrings.reinstateMember : JamiStrings.kickMember

            onClicked: {
                if (memberRole === Member.Role.BANNED) {
                    MessagesAdapter.addConversationMember(conversationId, participantUri);
                } else {
                    MessagesAdapter.removeConversationMember(conversationId, participantUri);
                }
            }
        }
    ]
    property var participantUri: ""
    property var role

    Component.onCompleted: menuItemsToLoad = menuItems
}
