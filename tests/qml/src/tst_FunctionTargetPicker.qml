/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import "../../../src/app/mainview/components"

TestWrapper {
    width: 900
    height: 800

    ListModel {
        id: fakeConversations

        property bool showContacts: true
        property bool showGroups: true
        property string query: ""

        function setFilter(text) {
            query = text;
        }

        ListElement { UID: "alice"; Title: "Alice"; Presence: 2; IsCoreDialog: true }
        ListElement { UID: "team"; Title: "Team"; Presence: 0; IsCoreDialog: false }
    }

    QtObject {
        id: fakeCircles
        property var circles: [{id: "friends", name: "Friends", count: 2, members: ["alice", "bob"]},
                               {id: "family", name: "Family", count: 0, members: []}]
    }

    QtObject {
        id: fakeFeeds
        property var feeds: [{id: "news", title: "News", owned: true, feedClosed: false, avatar: ""},
                             {id: "old", title: "Old", owned: true, feedClosed: true, avatar: ""},
                             {id: "travel", title: "Travel", owned: false, subscribed: true, avatar: ""},
                             {id: "offer", title: "Offer", owned: false, subscribed: false, avatar: ""}]
    }

    FunctionTargetPicker {
        id: uut
        conversations: fakeConversations
        circleService: fakeCircles
        feedService: fakeFeeds

        SignalSpy { id: conversationSpy; target: uut; signalName: "conversationPicked" }
        SignalSpy { id: circleSpy; target: uut; signalName: "circlePicked" }
        SignalSpy { id: boardSpy; target: uut; signalName: "boardPicked" }
    }

    TestCase {
        name: "FunctionTargetPicker"
        when: windowShown

        function init() {
            conversationSpy.clear();
            circleSpy.clear();
            boardSpy.clear();
        }

        function cleanup() {
            uut.close();
            findChild(uut, "targetSearch").text = "";
        }

        function openFor(fn) {
            uut.fn = fn;
            uut.filter = fn === FunctionsPanel.Calls || fn === FunctionsPanel.Messages ? "contacts" : "all";
            uut.open();
            tryCompare(uut, "opened", true);
        }

        // findChild() does not walk into the ListView contentItem.
        function find(item, name) {
            if (!item)
                return null;
            if (item.objectName === name)
                return item;
            const children = Array.from(item.children || []);
            if (item.contentItem && children.indexOf(item.contentItem) < 0)
                children.push(item.contentItem);
            for (const child of children) {
                const found = find(child, name);
                if (found)
                    return found;
            }
            return null;
        }

        // The Circles and Boards come after the conversations, once the list is laid out
        // again: a click before that would miss them.
        function waitForRows(rows) {
            const list = find(uut.contentItem, "targetList");
            tryVerify(() => list.contentHeight >= rows * find(uut.contentItem, "targetConversation-alice").height);
        }

        function test_calls_are_with_contacts_first_and_never_circles_nor_boards() {
            openFor(FunctionsPanel.Calls);
            compare(uut.filters, ["all", "contacts", "groups"]);
            compare(uut.filter, "contacts");
            verify(fakeConversations.showContacts);
            verify(!fakeConversations.showGroups);
            uut.filter = "all";
            compare(uut.circles.length, 0);
            compare(uut.boards.length, 0);
        }

        function test_messages_are_with_contacts_first() {
            openFor(FunctionsPanel.Messages);
            compare(uut.filters, ["all", "contacts", "groups", "circles", "boards"]);
            compare(uut.filter, "contacts");
        }

        function test_documents_are_with_anyone_first() {
            openFor(FunctionsPanel.Documents);
            compare(uut.filter, "all");
            verify(fakeConversations.showContacts);
            verify(fakeConversations.showGroups);
        }

        function test_location_is_never_shared_with_circles_nor_boards() {
            openFor(FunctionsPanel.Location);
            compare(uut.filters, ["all", "contacts", "groups"]);
        }

        function test_filters_select_the_kind_of_recipient() {
            openFor(FunctionsPanel.Messages);
            mouseClick(find(uut.contentItem, "targetFilter-groups"));
            compare(uut.filter, "groups");
            verify(!fakeConversations.showContacts);
            verify(fakeConversations.showGroups);
            compare(uut.circles.length, 0);

            mouseClick(find(uut.contentItem, "targetFilter-circles"));
            verify(!fakeConversations.showContacts);
            verify(!fakeConversations.showGroups);
            // Only the Circles that have members.
            compare(uut.circles.map(c => c.id), ["friends"]);

            mouseClick(find(uut.contentItem, "targetFilter-boards"));
            // Boards the account publishes and still open, or follows.
            compare(uut.boards.map(f => f.id), ["news", "travel"]);
        }

        function test_search_applies_to_everyone() {
            openFor(FunctionsPanel.Messages);
            uut.filter = "all";
            findChild(uut, "targetSearch").text = "tra";
            compare(fakeConversations.query, "tra");
            compare(uut.circles.length, 0);
            compare(uut.boards.map(f => f.id), ["travel"]);
        }

        function test_calling_a_contact_in_video_or_audio() {
            openFor(FunctionsPanel.Calls);
            tryVerify(() => find(uut.contentItem, "targetConversation-alice") !== null);
            const row = find(uut.contentItem, "targetConversation-alice");
            mouseClick(find(row, "videoCall"));
            compare(conversationSpy.count, 1);
            compare(conversationSpy.signalArguments[0][0], "alice");
            compare(conversationSpy.signalArguments[0][1], true);

            openFor(FunctionsPanel.Calls);
            tryVerify(() => find(uut.contentItem, "targetConversation-alice") !== null);
            mouseClick(find(find(uut.contentItem, "targetConversation-alice"), "audioCall"));
            compare(conversationSpy.count, 2);
            compare(conversationSpy.signalArguments[1][0], "alice");
            compare(conversationSpy.signalArguments[1][1], false);
        }

        function test_writing_to_a_circle_or_a_board() {
            openFor(FunctionsPanel.Messages);
            uut.filter = "all";
            tryVerify(() => find(uut.contentItem, "targetCircle-friends") !== null);
            // One Circle and two Boards after the two conversations.
            waitForRows(5);
            mouseClick(find(uut.contentItem, "targetCircle-friends"));
            compare(circleSpy.count, 1);
            compare(circleSpy.signalArguments[0][0], "friends");

            openFor(FunctionsPanel.Messages);
            uut.filter = "boards";
            tryVerify(() => find(uut.contentItem, "targetBoard-travel") !== null);
            waitForRows(4);
            mouseClick(find(uut.contentItem, "targetBoard-travel"));
            compare(boardSpy.count, 1);
            compare(boardSpy.signalArguments[0][0], "travel");
        }
    }
}
