/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

TabBar {
    id: tabBar

    enum TabIndex {
        Conversations,
        Requests
    }

    function selectTab(idx) {
        ConversationsAdapter.filterRequests = (idx === SidePanelTabBar.Requests);
    }

    currentIndex: 0

    FilterTabButton {
        id: conversationsTabButton

        down: !ConversationsAdapter.filterRequests
        labelText: JamiStrings.conversations
        onSelected: selectTab(SidePanelTabBar.Conversations)
        badgeCount: ConversationsAdapter.totalUnreadMessageCount
        acceleratorSequence: "Ctrl+L"
    }

    FilterTabButton {
        id: requestsTabButton

        down: !conversationsTabButton.down
        labelText: JamiStrings.invitations
        onSelected: selectTab(SidePanelTabBar.Requests)
        badgeCount: ConversationsAdapter.pendingRequestCount
        acceleratorSequence: "Ctrl+R"
    }
}
