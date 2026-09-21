/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import "../../../src/app/mainview/components"

TestWrapper {
    width: 900
    height: 750
    TestCase {
        name: "FeedIntegration"
        when: windowShown
        function test_owner_feed_uses_chat_and_separate_list() {
            const accountId = CurrentAccount.id;
            const id = FeedAdapter.createFeed(accountId, "QML integration Feed", "", true);
            verify(id !== "");
            tryVerify(() => FeedAdapter.details(id).title === "QML integration Feed", 15000);
            verify(FeedAdapter.followed.some(item => item.id === id));
            FeedAdapter.open(id);
            tryCompare(CurrentConversation, "id", id, 15000);
            tryCompare(CurrentConversation, "isFeed", true);
            compare(CurrentConversation.isFeedOwner, true);
            compare(CurrentConversation.feedReplies, true);
            MessagesAdapter.sendMessage("A Feed publication from Qt");
            verify(FeedAdapter.update(accountId, id, "Renamed from Qt", "", false));
            tryCompare(CurrentConversation, "title", "Renamed from Qt", 15000);
            tryCompare(CurrentConversation, "feedReplies", false);
            verify(FeedAdapter.closeFeed(accountId, id));
            tryVerify(() => !FeedAdapter.followed.some(item => item.id === id), 15000);
        }
    }
}
