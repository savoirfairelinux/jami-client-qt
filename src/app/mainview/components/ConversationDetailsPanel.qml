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

    function isOpen(panel) { return visible && currentIndex === panel }

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
        if (visible && toggle) {
            if (currentIndex === panel) {
                closePanel()
                return
            }
        } else {
            visible = true
        }
        currentIndex = panel
    }

    function closePanel() {
        currentIndex = -1
        visible = false
    }

    MessagesResearchPanel {}
    SwarmDetailsPanel {}
    AddMemberPanel {}
}
