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
            uut.feedCount = 0;
        }
        function test_account_without_conversations_nor_feeds_is_empty() {
            const placeholder = findChild(uut, "emptyAccountPlaceholder");
            verify(placeholder !== null);
            tryCompare(uut, "isEmptyAccount", true);
            tryCompare(placeholder, "visible", true);
        }
        function test_feed_only_account_is_not_empty() {
            const placeholder = findChild(uut, "emptyAccountPlaceholder");
            verify(placeholder !== null);
            // A single Feed, followed or owned, already fills the side panel, so
            // the "no conversations" placeholder must not claim the account is empty.
            uut.feedCount = 1;
            tryCompare(uut, "isEmptyAccount", false);
            tryCompare(placeholder, "visible", false);
        }
        function test_conversations_still_drive_the_placeholder() {
            const placeholder = findChild(uut, "emptyAccountPlaceholder");
            uut.conversationCount = 1;
            tryCompare(uut, "isEmptyAccount", false);
            tryCompare(placeholder, "visible", false);
        }
    }
}
