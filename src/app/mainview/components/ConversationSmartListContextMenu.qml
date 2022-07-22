/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../commoncomponents/contextmenu"

ContextMenuAutoLoader {
    id: root

    signal showSwarmDetails

    ConfirmDialog {
        id: rmDialog

        title: JamiStrings.confirmAction
        textLabel: JamiStrings.confirmRmConversation
        confirmLabel: JamiStrings.optionDelete
        onAccepted: {
            if (isSwarm)
                MessagesAdapter.removeConversation(responsibleConvUid)
            else
                MessagesAdapter.removeContact(responsibleConvUid)
        }
    }

    ConfirmDialog {
        id: blockDialog

        title: JamiStrings.confirmAction
        textLabel: JamiStrings.confirmBlockConversation
        confirmLabel: JamiStrings.optionBlock
        onAccepted: MessagesAdapter.blockConversation(responsibleConvUid)
    }

    property string responsibleAccountId: ""
    property string responsibleConvUid: ""
    property bool isBanned: false
    property bool isSwarm: false
    property var mode: undefined
    property int contactType: Profile.Type.INVALID
    property bool hasCall: {
        if (responsibleAccountId && responsibleConvUid)
            return UtilsAdapter.getCallId(responsibleAccountId,
                                          responsibleConvUid) !== ""
        return false
    }
    property bool readOnly

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: startVideoCallItem

            canTrigger: CurrentAccount.videoEnabled_Video && !hasCall && !readOnly
            itemName: JamiStrings.startVideoCall
            iconSource: JamiResources.videocam_24dp_svg
            onClicked: {
                LRCInstance.selectConversation(responsibleConvUid,
                                               responsibleAccountId)
                if (CurrentAccount.videoEnabled_Video)
                    CallAdapter.placeCall()
            }
        },
        GeneralMenuItem {
            id: startAudioCall

            canTrigger: !hasCall && !readOnly
            itemName: JamiStrings.startAudioCall
            iconSource: JamiResources.place_audiocall_24dp_svg
            onClicked: {
                LRCInstance.selectConversation(responsibleConvUid,
                                               responsibleAccountId)
                CallAdapter.placeAudioOnlyCall()
            }
        },
        GeneralMenuItem {
            id: clearConversation

            canTrigger: !isSwarm && !hasCall && !root.isBanned
            itemName: JamiStrings.clearConversation
            iconSource: JamiResources.ic_clear_24dp_svg
            onClicked: MessagesAdapter.clearConversationHistory(
                           responsibleAccountId,
                           responsibleConvUid)
        },
        GeneralMenuItem {
            id: removeContact

            canTrigger: !hasCall && !root.isBanned
            itemName: {
                if (mode !== Conversation.Mode.ONE_TO_ONE && mode !== Conversation.Mode.NON_SWARM)
                    return JamiStrings.removeConversation
                else
                    return JamiStrings.removeContact
            }
            iconSource: JamiResources.ic_hangup_participant_24dp_svg
            onClicked: rmDialog.open()
        },
        GeneralMenuItem {
            id: hangup

            canTrigger: hasCall
            itemName: JamiStrings.hangup
            iconSource: JamiResources.ic_call_end_white_24dp_svg
            addMenuSeparatorAfter: contactType !== Profile.Type.SIP
                                   && (contactType === Profile.Type.PENDING
                                       || !hasCall)
            onClicked: CallAdapter.hangUpACall(responsibleAccountId,
                                               responsibleConvUid)
        },
        GeneralMenuItem {
            id: acceptContactRequest

            canTrigger: contactType === Profile.Type.PENDING
            itemName: JamiStrings.acceptContactRequest
            iconSource: JamiResources.add_people_24dp_svg
            onClicked: MessagesAdapter.acceptInvitation(responsibleConvUid)
        },
        GeneralMenuItem {
            id: declineContactRequest

            canTrigger: contactType === Profile.Type.PENDING
            itemName: JamiStrings.declineContactRequest
            iconSource: JamiResources.round_close_24dp_svg
            onClicked: MessagesAdapter.refuseInvitation(responsibleConvUid)
        },
        GeneralMenuItem {
            id: blockContact

            canTrigger: !hasCall && contactType !== Profile.Type.SIP && !root.isBanned
            itemName: !(mode && mode !== Conversation.Mode.ONE_TO_ONE && mode !== Conversation.Mode.NON_SWARM) ? JamiStrings.blockContact : JamiStrings.blockSwarm
            iconSource: JamiResources.block_black_24dp_svg
            addMenuSeparatorAfter: contactType !== Profile.Type.SIP
            onClicked: blockDialog.open()
        },
        GeneralMenuItem {
            id: unblockContact

            canTrigger: root.isBanned
            itemName: JamiStrings.reinstateContact
            iconSource: JamiResources.round_remove_circle_24dp_svg
            addMenuSeparatorAfter: contactType !== Profile.Type.SIP
            onClicked: MessagesAdapter.unbanConversation(responsibleConvUid)
        },
        GeneralMenuItem {
            id: contactDetails

            canTrigger: contactType !== Profile.Type.SIP
            itemName: JamiStrings.convDetails
            iconSource: JamiResources.person_24dp_svg
            onClicked: {
                if (!(mode && mode !== Conversation.Mode.ONE_TO_ONE && mode !== Conversation.Mode.NON_SWARM))
                    userProfile.open()
                else
                    root.showSwarmDetails()
            }
        }
    ]

    Component.onCompleted: menuItemsToLoad = menuItems
}
