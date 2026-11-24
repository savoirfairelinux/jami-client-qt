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
 * along with this program; if not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtTest
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../../src/app/"
import "../../../src/app/commoncomponents"

TestWrapper {
    id: root
    width: 500
    height: 600

    ListModel {
        id: conversations
        dynamicRoles: true
        property list<string> peers: ["peer"]

        Component.onCompleted: {
            append({UID: "alice", Title: "Alice", Uris: peers, IsRequest: false, IsBanned: false, LastInteractionTimeStamp: 20});
            append({UID: "group", Title: "Group [ops]", Uris: peers, IsRequest: false, IsBanned: false, LastInteractionTimeStamp: 30});
            append({UID: "invitation", Title: "Invitation", Uris: peers, IsRequest: true, IsBanned: false, LastInteractionTimeStamp: 40});
            append({UID: "blocked", Title: "Blocked", Uris: peers, IsRequest: false, IsBanned: true, LastInteractionTimeStamp: 50});
        }
    }

    Component {
        id: fixtureDelegate
        Item {}
    }

    Component {
        id: menuComponent

        ShareMessageMenu {
            parent: root
            msgBody: "Shared message"
            type: 2
            viewCoordinator: root.viewCoordinator
        }
    }

    TestCase {
        id: testCase
        name: "ShareMessageMenu"
        when: windowShown

        property var menu
        readonly property var picker: menu ? findChild(menu, "conversationPicker") : null
        readonly property var recipients: picker ? findChild(picker, "creationConversationList") : null
        readonly property var proxyModel: recipients ? recipients.model : null

        function init() {
            menu = createTemporaryObject(menuComponent, root);
            verify(proxyModel);
        }

        function useFixture() {
            recipients.delegate = fixtureDelegate;
            proxyModel.sourceModel = conversations;
            proxyModel.invalidate();
        }

        function test_titleSearchExcludesInvitationsAndBlockedRows() {
            useFixture();
            compare(recipients.count, 2);
            proxyModel.searchText = "invitation|blocked";
            proxyModel.invalidate();
            compare(recipients.count, 0);
            proxyModel.searchText = "alice";
            proxyModel.invalidate();
            compare(recipients.count, 1);
        }

        function test_titleFilterMatchesTitleAndHandlesInvalidRegex() {
            useFixture();
            proxyModel.searchText = "ALICE";
            proxyModel.invalidate();
            compare(recipients.count, 1);
            proxyModel.searchText = "alice|group";
            proxyModel.invalidate();
            compare(recipients.count, 2);
            proxyModel.searchText = "[";
            proxyModel.invalidate();
            compare(recipients.count, 1);
        }

        function test_emptyConversationCannotBeRecipient() {
            const filters = proxyModel.filters;
            verify(!filters[filters.length - 1].filter("No peers", []));
        }

        function test_previewShowsSharedContent() {
            menu.open();
            tryCompare(menu, "opened", true);
            const preview = findChild(menu, "sharedMessagePreview");
            verify(preview.visible);
            compare(preview.text, "Shared message");

            menu.msgBody = "Long shared message ".repeat(20);
            tryVerify(() => preview.truncated);
            verify(preview.width <= picker.width);

            menu.type = 5;
            menu.msgBody = "/tmp/local-transfer";
            menu.transferName = "Report.pdf";
            compare(preview.text, "Report.pdf");
        }

        function test_sharesMessageAndCommentToFeed() {
            const previousId = LRCInstance.selectedConvUid;
            const title = "Share test feed";
            const feedId = ConversationsAdapter.createConversationFromConversations(title, "", "", [], true, false);
            verify(feedId);
            try {
                menu.open();
                tryCompare(menu, "opened", true);

                const search = findChild(picker, "creationConversationSearch");
                search.textField.text = title;
                tryCompare(recipients, "count", 1);
                tryVerify(() => !!recipients.itemAtIndex(0));
                const send = findChild(menu, "shareMessageButton");
                verify(!send.enabled);
                mouseClick(recipients.itemAtIndex(0));
                compare(picker.selectedIds, [feedId]);
                verify(send.enabled);

                const comment = "Optional comment";
                findChild(menu, "shareMessageComment").text = comment;
                mouseClick(send);

                LRCInstance.selectConversation(feedId);
                const messages = MessagesAdapter.messageListModel;
                tryVerify(() => {
                    const bodies = Array.from({length: messages.count}, (_, i) => messages.get(i).Body);
                    return bodies.includes("Shared message") && bodies.includes(comment);
                });
            } finally {
                LRCInstance.selectConversation(previousId);
                MessagesAdapter.removeConversation(feedId);
            }
        }
    }
}
