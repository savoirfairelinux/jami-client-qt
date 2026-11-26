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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../../src/app/mainview/components"

TestWrapper {
    SwarmDetailsPanel {
        id: uut

        width: 400
        height: 600

        TestCase {
            name: "Feed audience selector"
            when: windowShown

            property var saved

            function init() {
                saved = {
                    "isCoreDialog": CurrentConversation.isCoreDialog,
                    "isFeedMode": CurrentConversation.isFeedMode,
                    "canAddMember": CurrentConversation.canAddMember,
                    "feedInviteAllContacts": CurrentConversation.feedInviteAllContacts
                };
            }

            function cleanup() {
                for (const key in saved)
                    CurrentConversation[key] = saved[key];
            }

            function test_audienceFollowsCurrentConversation() {
                CurrentConversation.isCoreDialog = false;
                CurrentConversation.isFeedMode = true;
                CurrentConversation.canAddMember = true;
                findChild(uut, "swarmDetailsPanelTabBar").currentIndex = 1;

                const audience = findChild(uut, "feedAudienceComboBox");
                const inviteButton = findChild(uut, "inviteMemberButton");
                verify(audience.visible);
                compare(audience.currentIndex, 1);
                verify(inviteButton.visible);

                CurrentConversation.feedInviteAllContacts = true;
                compare(audience.currentIndex, 0);
                verify(!inviteButton.visible);

                CurrentConversation.canAddMember = false;
                verify(!audience.visible);
            }
        }
    }
}
