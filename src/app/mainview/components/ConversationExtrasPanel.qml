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
import QtQuick.Layouts
import net.jami.Adapters 1.1

StackLayout {
    id: root

    // We need to set the currentIndex to -1 to make sure the
    // panel is closed when the application starts.
    Component.onCompleted: closePanel()

    // The index of the tab in the swarm details panel.
    property int detailsIndex: -1
    property var inviteMembersDialog: null

    function openInviteMembersDialog(focusItem) {
        if (inviteMembersDialog || !CurrentConversation.canAddMember)
            return;
        inviteMembersDialog = viewCoordinator.presentDialog(appWindow.contentItem, "mainview/components/InviteMembersDialog.qml", {
            "viewCoordinator": viewCoordinator,
            "conversationId": CurrentConversation.id,
            "isFeed": CurrentConversation.isFeedMode
        }, true);
        if (!inviteMembersDialog)
            return;
        inviteMembersDialog.closed.connect(() => {
            root.inviteMembersDialog = null;
            if (focusItem && focusItem.visible)
                focusItem.forceActiveFocus();
        });
    }

    // Best to avoid using the visible property directly.
    // Pass through the following open/close wrappers instead.
    function openPanel(panel) {
        // The thread panel has nothing to show without an open thread (e.g. when restored after a call).
        if (panel === ChatView.ThreadPanel && MessagesAdapter.threadMessageListModel.threadId === "")
            return;
        currentIndex = panel;
        visible = true;
    }

    function closePanel() {
        currentIndex = -1;
        visible = false;
    }

    function isOpen(panel) {
        return visible && currentIndex === panel;
    }

    // This will open the details panel if it's not already visible.
    // Additionally, `toggle` being true (default) will close the panel
    // if it is already open to `panel`.
    function switchToPanel(panel, toggle = true) {
        console.debug("switchToPanel: %1, toggle: %2".arg(panel).arg(toggle));
        if (visible) {
            // We need to close the panel if it's open and we're switching to
            // the same panel.
            if (toggle && currentIndex === panel) {
                // Toggle off.
                closePanel();
            } else {
                // Switch to the new panel.
                openPanel(panel);
            }
        } else {
            openPanel(panel);
        }
    }

    // The thread panel follows the open thread; closing the panel closes the thread.
    Connections {
        target: MessagesAdapter.threadMessageListModel

        function onThreadIdChanged() {
            if (MessagesAdapter.threadMessageListModel.threadId !== "")
                openPanel(ChatView.ThreadPanel);
            // Not isOpen(): the panel reads as hidden while the chat view is (e.g. in the settings).
            else if (currentIndex === ChatView.ThreadPanel)
                closePanel();
        }
    }

    onCurrentIndexChanged: {
        if (currentIndex !== ChatView.ThreadPanel)
            MessagesAdapter.threadMessageListModel.threadId = "";
    }

    Loader {
        active: root.isOpen(ChatView.SwarmDetailsPanel)
        sourceComponent: SwarmDetailsPanel {}
    }

    Loader {
        active: root.isOpen(ChatView.MessagesResearchPanel)
        sourceComponent: MessagesResearchPanel {}
    }

    Loader {
        active: root.isOpen(ChatView.ConversationStatusPanel)
        sourceComponent: ConversationStatusView {}
    }

    Loader {
        active: root.isOpen(ChatView.ThreadPanel)
        sourceComponent: ThreadPanel {}
    }
}
