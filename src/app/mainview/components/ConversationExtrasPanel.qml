/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
        target: CurrentConversationMembers

        function onCountChanged() {
            // Close the panel if there are 8 or more members in the
            // conversation AND the "Add Member" panel is currently open.
            if (CurrentConversationMembers.count >= 8 && isOpen(ChatView.AddMemberPanel)) {
                closePanel();
            }
        }
    }

    SwarmDetailsPanel {
        id: detailsPanel

        property int parentIndex: root.currentIndex
        // When we change to the details panel we should load the tab index.
        onParentIndexChanged: tabBarIndex = Math.min(tabBarItemsLength - 1, Math.max(0, root.detailsIndex))
        // Save it when it changes.
        onTabBarIndexChanged: root.detailsIndex = tabBarIndex
    }
    MessagesResearchPanel {}
    AddMemberPanel {}
}
