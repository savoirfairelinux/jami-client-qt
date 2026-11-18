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
    id: wrapper

    width: 400
    height: 640

    SidePanel {
        id: uut

        appContext: wrapper.appContext

        TestCase {
            name: "SidePanel"
            when: windowShown

            function test_feedSectionsOnlyApplyOutsideSearch() {
                const previousCategory = ConversationsAdapter.category;
                const list = findChild(uut, "sidebarConversationList");
                verify(list);
                try {
                    ConversationsAdapter.category = ConversationListProxyModel.Feeds;
                    compare(list.section.property, "IsRequest");
                    const joinedHeader = list.section.delegate.createObject(uut, {section: "false"});
                    const invitedHeader = list.section.delegate.createObject(uut, {section: "true"});
                    verify(joinedHeader);
                    verify(invitedHeader);
                    compare(joinedHeader.children[0].text, JamiStrings.feeds);
                    compare(invitedHeader.children[0].text, JamiStrings.feedInvitations);
                    joinedHeader.destroy();
                    invitedHeader.destroy();
                    ConversationsAdapter.setFilter("feed");
                    compare(list.section.property, "");
                    ConversationsAdapter.setFilter("");
                    compare(list.section.property, "IsRequest");
                    ConversationsAdapter.category = ConversationListProxyModel.Groups;
                    compare(list.section.property, "");
                } finally {
                    ConversationsAdapter.setFilter("");
                    ConversationsAdapter.category = previousCategory;
                }
            }

            function test_cancelingCreationDialog_data() {
                return [
                    {tag: "group", isFeed: false, category: ConversationListProxyModel.Groups},
                    {tag: "feed", isFeed: true, category: ConversationListProxyModel.Feeds}
                ];
            }

            function test_cancelingCreationDialog(data) {
                const previousCategory = ConversationsAdapter.category;
                const previousInvitationsOnly = ConversationsAdapter.invitationsOnly;

                try {
                    ConversationsAdapter.category = data.category;
                    ConversationsAdapter.invitationsOnly = true;

                    uut.openCreateConversationDialog(data.isFeed);
                    const dialog = uut.createConversationDialog;
                    verify(dialog);
                    tryCompare(dialog, "opened", true);
                    compare(dialog.isFeed, data.isFeed);

                    keyClick(Qt.Key_Escape);
                    tryVerify(() => uut.createConversationDialog === null);
                    compare(ConversationsAdapter.category, data.category);
                    compare(ConversationsAdapter.invitationsOnly, true);
                } finally {
                    if (uut.createConversationDialog)
                        uut.createConversationDialog.close();
                    ConversationsAdapter.category = previousCategory;
                    ConversationsAdapter.invitationsOnly = previousInvitationsOnly;
                }
            }
        }
    }
}
