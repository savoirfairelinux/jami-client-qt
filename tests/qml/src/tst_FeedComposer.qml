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
    width: 800
    height: 400
    ChatViewFooter {
        id: composer
        width: 780
    }
    TestCase {
        name: "FeedComposer"
        when: windowShown
        property var original
        function init() {
            original = [CurrentConversation.isFeed, CurrentConversation.isFeedOwner,
                        CurrentConversation.feedReplies, CurrentConversation.feedClosed];
            CurrentConversation.isFeed = true;
            CurrentConversation.isFeedOwner = false;
            CurrentConversation.feedReplies = false;
            CurrentConversation.feedClosed = false;
            MessagesAdapter.replyToId = "";
            MessagesAdapter.editId = "";
        }
        function cleanup() {
            CurrentConversation.isFeed = original[0];
            CurrentConversation.isFeedOwner = original[1];
            CurrentConversation.feedReplies = original[2];
            CurrentConversation.feedClosed = original[3];
            MessagesAdapter.replyToId = "";
            MessagesAdapter.editId = "";
        }
        function test_read_only_subscriber() {
            compare(composer.feedWritable, false);
            verify(!composer.messageBar.visible);
            CurrentConversation.feedReplies = true;
            compare(composer.feedWritable, false);
        }
        function test_reply_only_and_closed() {
            CurrentConversation.feedReplies = true;
            MessagesAdapter.replyToId = "publication";
            compare(composer.feedWritable, true);
            MessagesAdapter.replyToId = "";
            compare(composer.feedWritable, false);
            CurrentConversation.isFeedOwner = true;
            compare(composer.feedWritable, true);
            CurrentConversation.feedClosed = true;
            compare(composer.feedWritable, false);
            CurrentConversation.isFeed = false;
            compare(composer.feedWritable, true);
        }
    }
}
