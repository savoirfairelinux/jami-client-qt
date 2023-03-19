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

    property int detailsIndex: -1

    function isOpen(panel) { return visible && currentIndex === panel }

    visible: currentIndex > -1

    property bool detailsShouldOpen: false
    onVisibleChanged: if (visible) detailsShouldOpen = true

    function restoreState() {
        // Only applies to Jami accounts, and we musn't be in a call.
        if (detailsShouldOpen && !inCallView) {
            switchToPanel(ChatView.SwarmDetailsPanel, false)
        } else {
            closePanel()
        }
    }

    Connections {
        target: CurrentConversationMembers

        function onCountChanged() {
            // Close the panel if there are 8 or more members in the
            // conversation AND the "Add Member" panel is currently open.
            if (CurrentConversationMembers.count >= 8
                    && isOpen(ChatView.AddMemberPanel)) {
                closePanel();
            }
        }
    }

    // This will open the details panel if it's not already visible.
    // Additionally, `toggle` being true (default) will close the panel
    // if it is already open to `panel`.
    function switchToPanel(panel, toggle=true) {
        if (visible && toggle && currentIndex === panel) {
            closePanel()
        } else {
            currentIndex = panel
        }
    }

    function closePanel() {
        // We need to close the panel, but not save it when appropriate.
        currentIndex = -1
        if (!inCallView)
            detailsShouldOpen = false
    }

    SwarmDetailsPanel {
        id: detailsPanel

        property int parentIndex: root.currentIndex
        // When we change to the details panel we should load the tab index.
        onParentIndexChanged: tabBarIndex = Math.min(tabBarItemsLength - 1,
                                                     Math.max(0, root.detailsIndex))
        // Save it when it changes.
        onTabBarIndexChanged: root.detailsIndex = tabBarIndex
    }
    MessagesResearchPanel {}
    AddMemberPanel {}
}
