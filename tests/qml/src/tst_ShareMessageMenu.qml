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
import "../../../src/app/"
import "../../../src/app/commoncomponents"

TestWrapper {
    id: root
    width: 500
    height: 500

    function setBindings() {}

    ListModel {
        id: conversations
        ListElement { Title: "Alice"; Uris: "alice"; IsRequest: false; IsBanned: false; LastInteractionTimeStamp: 20 }
        ListElement { Title: "Group"; Uris: "group"; IsRequest: false; IsBanned: false; LastInteractionTimeStamp: 30 }
        ListElement { Title: "Invitation"; Uris: "invitation"; IsRequest: true; IsBanned: false; LastInteractionTimeStamp: 40 }
        ListElement { Title: "Blocked"; Uris: "blocked"; IsRequest: false; IsBanned: true; LastInteractionTimeStamp: 50 }
        ListElement { Title: "Empty"; Uris: ""; IsRequest: false; IsBanned: false; LastInteractionTimeStamp: 60 }
    }

    Item {
        id: msgBubble
        width: 50
        height: 50
    }

    ListView {
        id: msgList
        width: 400
        height: 400
    }

    ShareMessageMenu {
        id: uut
        parent: root
        msgId: ""
        msgBody: ""
        isOutgoing: false
        type: 2
        transferName: ""
        msgBubble: msgBubble
        listView: msgList
        author: ""
        formattedTime: ""
    }

    TestCase {
        id: testCase
        name: "ShareMessageMenu"
        when: windowShown

        readonly property var proxyModel: findChild(uut, "shareConvProxyModel")

        Repeater {
            id: recipients
            model: testCase.proxyModel
            delegate: Item {}
        }

        function init() {
            proxyModel.sourceModel = conversations;
            proxyModel.titleFilter = "";
        }

        function test_titleSearchExcludesInvitationsAndBlockedRows() {
            verify(proxyModel);
            compare(recipients.count, 2);
            proxyModel.titleFilter = "invitation|blocked";
            proxyModel.invalidate();
            compare(recipients.count, 0);
            proxyModel.titleFilter = "alice";
            proxyModel.invalidate();
            compare(recipients.count, 1);
        }

        function test_titleFilterMatchesTitleAndHandlesInvalidRegex() {
            verify(proxyModel);
            const titleFilter = proxyModel.filters[2];
            proxyModel.titleFilter = "ALICE";
            compare(titleFilter.filter("Alice", ["alice"]), true);
            compare(titleFilter.filter("Group", ["group"]), false);
            proxyModel.titleFilter = "[";
            compare(titleFilter.filter("A [group]", ["group"]), true);
            compare(titleFilter.filter("Alice", ["alice"]), false);
        }

        function test_emptyConversationCannotBeRecipient() {
            verify(proxyModel);
            compare(proxyModel.filters[2].filter("No peers", []), false);
        }
    }
}
