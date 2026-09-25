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

    // Best to avoid using the visible property directly.
    // Pass through the following open/close wrappers instead.
    function openPanel(panel) {
        // The thread panel has nothing to show without a selected thread.
        if (panel === ChatView.ConversationThreadPanel && MessagesAdapter.threadRootId === "")
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

    Connections {
        target: CurrentConversation.members

        function onCountChanged() {
            // Close the panel if there are 8 or more members in the
            // conversation AND the "Add Member" panel is currently open.
            if (CurrentConversation.members.count >= 8 && isOpen(ChatView.AddMemberPanel)) {
                closePanel();
            }
        }
    }

    Connections {
        target: MessagesAdapter

        function onThreadRootIdChanged() {
            if (MessagesAdapter.threadRootId !== "") {
                openPanel(ChatView.ConversationThreadPanel);
            } else if (isOpen(ChatView.ConversationThreadPanel)) {
                // The thread was cleared (e.g. conversation switch or leaving threaded view).
                closePanel();
            }
        }
    }

    // Forget the selected thread once its panel is no longer shown, so that
    // selecting the same thread again reopens it.
    onCurrentIndexChanged: {
        if (visible && currentIndex !== ChatView.ConversationThreadPanel)
            MessagesAdapter.threadRootId = "";
    }
    onVisibleChanged: {
        if (!visible)
            MessagesAdapter.threadRootId = "";
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
        active: root.isOpen(ChatView.AddMemberPanel)
        sourceComponent: AddMemberPanel {}
    }

    Loader {
        active: root.isOpen(ChatView.ConversationStatusPanel)
        sourceComponent: ConversationStatusView {}
    }

    Loader {
        active: root.isOpen(ChatView.ConversationThreadPanel)
        sourceComponent: ConversationThread {}
    }
}
