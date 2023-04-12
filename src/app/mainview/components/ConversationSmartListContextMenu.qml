/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

    // For UserProfile dialog.
    property string aliasText
    property int contactType: Profile.Type.INVALID
    property bool hasCall: false
    property string idText
    property bool isBanned: false
    property var isCoreDialog: undefined
    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: startVideoCallItem
            canTrigger: CurrentAccount.videoEnabled_Video && !hasCall && !readOnly
            iconSource: JamiResources.videocam_24dp_svg
            itemName: JamiStrings.startVideoCall

            onClicked: {
                LRCInstance.selectConversation(responsibleConvUid, responsibleAccountId);
                if (CurrentAccount.videoEnabled_Video)
                    CallAdapter.placeCall();
            }
        },
        GeneralMenuItem {
            id: startAudioCall
            canTrigger: !hasCall && !readOnly
            iconSource: JamiResources.place_audiocall_24dp_svg
            itemName: JamiStrings.startAudioCall

            onClicked: {
                LRCInstance.selectConversation(responsibleConvUid, responsibleAccountId);
                CallAdapter.placeAudioOnlyCall();
            }
        },
        GeneralMenuItem {
            id: clearConversation
            canTrigger: mode === Conversation.Mode.NON_SWARM && !hasCall && !root.isBanned
            iconSource: JamiResources.ic_clear_24dp_svg
            itemName: JamiStrings.clearConversation

            onClicked: MessagesAdapter.clearConversationHistory(responsibleAccountId, responsibleConvUid)
        },
        GeneralMenuItem {
            id: removeContact
            canTrigger: !hasCall && !root.isBanned
            iconSource: JamiResources.ic_hangup_participant_24dp_svg
            itemName: {
                if (mode !== Conversation.Mode.NON_SWARM)
                    return JamiStrings.removeConversation;
                else
                    return JamiStrings.removeContact;
            }

            onClicked: {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                        "title": JamiStrings.confirmAction,
                        "textLabel": JamiStrings.confirmRmConversation,
                        "confirmLabel": JamiStrings.optionRemove
                    });
                dlg.accepted.connect(function () {
                        if (!isCoreDialog)
                            MessagesAdapter.removeConversation(responsibleConvUid);
                        else
                            MessagesAdapter.removeContact(responsibleConvUid);
                    });
            }
        },
        GeneralMenuItem {
            id: hangup
            addMenuSeparatorAfter: contactType !== Profile.Type.SIP && (contactType === Profile.Type.PENDING || !hasCall)
            canTrigger: hasCall
            iconSource: JamiResources.ic_call_end_white_24dp_svg
            itemName: JamiStrings.endCall

            onClicked: CallAdapter.hangUpACall(responsibleAccountId, responsibleConvUid)
        },
        GeneralMenuItem {
            id: acceptContactRequest
            canTrigger: contactType === Profile.Type.PENDING
            iconSource: JamiResources.add_people_24dp_svg
            itemName: JamiStrings.acceptContactRequest

            onClicked: MessagesAdapter.acceptInvitation(responsibleConvUid)
        },
        GeneralMenuItem {
            id: declineContactRequest
            canTrigger: contactType === Profile.Type.PENDING
            iconSource: JamiResources.round_close_24dp_svg
            itemName: JamiStrings.declineContactRequest

            onClicked: MessagesAdapter.refuseInvitation(responsibleConvUid)
        },
        GeneralMenuItem {
            id: blockContact
            addMenuSeparatorAfter: canTrigger
            canTrigger: !hasCall && contactType !== Profile.Type.SIP && !root.isBanned
            iconSource: JamiResources.block_black_24dp_svg
            itemName: !(mode && isCoreDialog) ? JamiStrings.blockContact : JamiStrings.blockSwarm

            onClicked: {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                        "title": JamiStrings.confirmAction,
                        "textLabel": JamiStrings.confirmBlockConversation,
                        "confirmLabel": JamiStrings.optionBlock
                    });
                dlg.accepted.connect(function () {
                        MessagesAdapter.blockConversation(responsibleConvUid);
                    });
            }
        },
        GeneralMenuItem {
            id: unblockContact
            addMenuSeparatorAfter: canTrigger
            canTrigger: root.isBanned
            iconSource: JamiResources.round_remove_circle_24dp_svg
            itemName: JamiStrings.reinstateContact

            onClicked: MessagesAdapter.unbanConversation(responsibleConvUid)
        },
        GeneralMenuItem {
            id: contactDetails
            canTrigger: contactType !== Profile.Type.SIP
            iconSource: JamiResources.person_24dp_svg
            itemName: isCoreDialog ? JamiStrings.contactDetails : JamiStrings.convDetails

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
    property var mode: undefined
    property bool readOnly: false
    property string registeredNameText
    property string responsibleAccountId: ""
    property string responsibleConvUid: ""

    signal showSwarmDetails

    Component.onCompleted: menuItemsToLoad = menuItems
}
