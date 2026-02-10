/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

    property string responsibleAccountId: ""
    property string responsibleConvUid: ""
    property bool isBanned: false
    property bool isCoreDialog: false
    property var mode: undefined
    property int contactType: Profile.Type.INVALID
    // whether the current user is already in a call in the conversation or not
    property bool isInCall: false
    // the number of ongoing calls in the current conversation (independent of whether the user has joined them)
    property int nbActiveCalls: 0
    property bool readOnly: false

    // For UserProfile dialog.
    property string aliasText
    property string registeredNameText
    property string idText

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: startOrJoinAudioCall

            canTrigger: !readOnly && !isInCall
            itemName: nbActiveCalls > 0 ? JamiStrings.joinWithAudio : JamiStrings.startAudioCall
            iconSource: JamiResources.start_audiocall_24dp_svg
            onClicked: {
                LRCInstance.selectConversation(responsibleConvUid, responsibleAccountId);
                CallAdapter.startAudioOnlyCall();
            }
        },
        GeneralMenuItem {
            id: startOrJoinVideoCall

            canTrigger: CurrentAccount.videoEnabled_Video && !readOnly && !isInCall
            itemName: nbActiveCalls > 0 ? JamiStrings.joinWithVideo : JamiStrings.startVideoCall
            iconSource: JamiResources.videocam_24dp_svg
            onClicked: {
                LRCInstance.selectConversation(responsibleConvUid, responsibleAccountId);
                if (CurrentAccount.videoEnabled_Video)
                    CallAdapter.startCall();
            }
        },
        GeneralMenuItem {
            id: deleteConversation

            canTrigger: mode === Conversation.Mode.NON_SWARM && !isInCall && !root.isBanned
            itemName: JamiStrings.deleteConversation
            iconSource: JamiResources.ic_clear_24dp_svg
            onClicked: MessagesAdapter.clearConversationHistory(responsibleAccountId, responsibleConvUid)
        },
        GeneralMenuItem {
            id: removeConversation

            canTrigger: !isInCall && !root.isBanned
            itemName: mode === Conversation.Mode.ONE_TO_ONE ? JamiStrings.removeConversation : JamiStrings.leaveGroup
            iconSource: JamiResources.ic_disconnect_participant_24dp_svg
            onClicked: {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                    "title": JamiStrings.confirmAction,
                    "textLabel": mode === Conversation.Mode.ONE_TO_ONE ? JamiStrings.confirmRemoveOneToOneConversation : JamiStrings.confirmLeaveGroup,
                    "confirmLabel": mode === Conversation.Mode.ONE_TO_ONE ? JamiStrings.optionRemove : JamiStrings.optionLeave
                });
                dlg.accepted.connect(function () {
                    MessagesAdapter.removeConversation(responsibleConvUid, true);
                });
            }
        },
        GeneralMenuItem {
            id: removeContact

            canTrigger: !isInCall && !root.isBanned && mode === Conversation.Mode.ONE_TO_ONE
            itemName: JamiStrings.removeContact
            iconSource: JamiResources.kick_member_svg
            onClicked: {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                    "title": JamiStrings.confirmAction,
                    "textLabel": JamiStrings.confirmRemoveContact,
                    "confirmLabel": JamiStrings.optionRemove
                });
                dlg.accepted.connect(function () {
                    MessagesAdapter.removeContact(responsibleConvUid);
                });
            }
        },
        GeneralMenuItem {
            id: endCall

            canTrigger: isInCall
            itemName: JamiStrings.endCall
            iconSource: JamiResources.ic_call_end_white_24dp_svg
            onClicked: CallAdapter.endCall(responsibleAccountId, responsibleConvUid)
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
            onClicked: MessagesAdapter.declineInvitation(responsibleConvUid)
        },
        GeneralMenuItem {
            id: blockContact

            canTrigger: !isInCall && contactType !== Profile.Type.SIP && !root.isBanned && isCoreDialog && root.idText !== CurrentAccount.uri
            itemName: JamiStrings.blockContact
            iconSource: JamiResources.block_black_24dp_svg
            onClicked: {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                    "title": JamiStrings.confirmAction,
                    "textLabel": JamiStrings.confirmBlockContact,
                    "confirmLabel": JamiStrings.optionBlock
                });
                dlg.accepted.connect(function () {
                    MessagesAdapter.blockConversation(responsibleConvUid);
                });
            }
        },
        GeneralMenuItem {
            id: unblockContact

            canTrigger: root.isBanned
            itemName: JamiStrings.reinstateContact
            iconSource: JamiResources.round_remove_circle_24dp_svg
            onClicked: MessagesAdapter.unbanConversation(responsibleConvUid)
        },
        GeneralMenuItem {
            id: contactDetails

            canTrigger: contactType !== Profile.Type.SIP
            itemName: isCoreDialog ? JamiStrings.contactDetails : JamiStrings.convDetails
            iconSource: JamiResources.person_24dp_svg
            onClicked: {
                if (isCoreDialog) {
                    viewCoordinator.presentDialog(appWindow, "mainview/components/UserProfile.qml", {
                        "aliasText": aliasText,
                        "registeredNameText": registeredNameText,
                        "idText": idText,
                        "convId": responsibleConvUid
                    });
                } else {
                    root.showSwarmDetails();
                }
            }
        }
    ]

    Component.onCompleted: menuItemsToLoad = menuItems
}
