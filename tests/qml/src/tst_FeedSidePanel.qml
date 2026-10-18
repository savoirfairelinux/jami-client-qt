/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import "../../../src/app/mainview/components"

TestWrapper {
    width: 400
    height: 600
    SidePanel {
        id: uut
        anchors.fill: parent
    }
    TestCase {
        name: "FeedSidePanel"
        when: windowShown
        function init() {
            uut.conversationCount = 0;
            uut.contactsMode = false;
        }
        function test_account_without_conversations_is_empty() {
            const placeholder = findChild(uut, "emptyAccountPlaceholder");
            verify(placeholder !== null);
            tryCompare(uut, "isEmptyAccount", true);
            tryCompare(placeholder, "visible", true);
        }
        function test_conversations_still_drive_the_placeholder() {
            const placeholder = findChild(uut, "emptyAccountPlaceholder");
            uut.conversationCount = 1;
            tryCompare(uut, "isEmptyAccount", false);
            tryCompare(placeholder, "visible", false);
        }
        function test_boards_are_reached_through_their_function() {
            // Boards are no longer listed in the side panel: the Board function holds them.
            compare(findChild(uut, "feedList"), null);
            const panel = findChild(uut, "functionsPanel");
            verify(panel !== null);
            verify(findChild(panel, "functionCard-" + FunctionsPanel.Board) !== null);
        }
        function test_the_functions_take_at_most_a_third_of_the_panel() {
            const panel = findChild(uut, "functionsPanel");
            compare(panel.maximumHeight, uut.height / 3);
            verify(panel.implicitHeight <= uut.height / 3);
        }
        function test_contacts_replace_the_conversations() {
            uut.openContacts();
            verify(uut.contactsMode);
            tryCompare(findChild(uut, "contactsListView"), "visible", true);
            tryCompare(findChild(uut, "contactsSortBar"), "visible", true);
            compare(findChild(uut, "emptyAccountPlaceholder").visible, false);
            // The functions stay with the conversation list.
            compare(findChild(uut, "functionsPanel").visible, false);

            findChild(uut, "closeContactsButton").clicked();
            verify(!uut.contactsMode);
            tryCompare(findChild(uut, "contactsListView"), "visible", false);
        }
    }
}
