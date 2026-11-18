/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root
    objectName: "InviteMembersDialog"

    required property var viewCoordinator
    required property string conversationId
    property bool isFeed: false
    property string accountId: ""
    property var candidates: ({})
    property bool inviting: false
    property bool invitationFailed: false

    titleText: JamiStrings.inviteMembers
    title: titleText
    headerLeadingButton: !inviting ? picker.helpButton : null
    implicitWidth: Math.min(400, parent ? Math.max(0, parent.width - 64) : 400)
    height: Math.min(parent.height * 0.7, Math.max(0, parent.height - 64))
    autoClose: !inviting
    closeButtonVisible: !inviting

    function refreshCandidates() {
        if (accountId !== CurrentAccount.id || conversationId !== CurrentConversation.id)
            return;
        candidates = ConversationsAdapter.invitationCandidates(conversationId, picker.selectedIds);
    }

    onAboutToShow: accountId = CurrentAccount.id
    onOpened: {
        refreshCandidates();
        picker.focusSearch();
    }

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            root.close();
        }
        function onCurrentAccountRemoved() {
            root.close();
        }
    }

    Connections {
        target: CurrentConversation

        function onIdChanged() {
            if (CurrentConversation.id !== root.conversationId)
                root.close();
        }
        function onCanAddMemberChanged() {
            if (!CurrentConversation.canAddMember)
                root.close();
        }
    }

    Connections {
        target: CurrentConversation.members

        function onModelReset() {
            root.refreshCandidates();
        }
    }

    Connections {
        target: ConversationsAdapter.convListProxyModel.sourceModel

        function onDataChanged() {
            root.refreshCandidates();
        }
        function onModelReset() {
            root.refreshCandidates();
        }
        function onRowsRemoved() {
            root.refreshCandidates();
        }
    }

    button3.text: qsTr("Invite members (%1)").arg((candidates.uris || []).length)
    button3.iconSource: JamiResources.add_people_24dp_svg
    button3.textButton: false
    button3.filledButton: true
    button3.enabled: !inviting && (candidates.uris || []).length > 0
    button3.onClicked: {
        if (inviting || accountId !== CurrentAccount.id || conversationId !== CurrentConversation.id)
            return;
        inviting = true;
        invitationFailed = false;
        if (!ConversationsAdapter.inviteToConversation(conversationId, picker.selectedIds)) {
            inviting = false;
            invitationFailed = true;
            refreshCandidates();
            return;
        }
        close();
    }

    contentItem: ColumnLayout {
        Label {
            Layout.fillWidth: true
            visible: root.invitationFailed
            text: JamiStrings.memberInvitationFailed
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
        }

        ConversationPicker {
            id: picker
            Layout.fillWidth: true
            Layout.fillHeight: true
            enabled: !root.inviting
            viewCoordinator: root.viewCoordinator
            isFeed: root.isFeed
            excludedConversationId: root.conversationId
            lockedContactUris: Array.from(root.candidates.lockedUris || [])
            onSelectedIdsChanged: root.refreshCandidates()
        }
    }
}
