/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import Qt.labs.qmlmodels
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

TestWrapper {
    id: testRoot
    width: 1000
    height: 800

    Component {
        id: liveFeedView
        MessageListView {
            width: 900
            height: 700
        }
    }

    QtObject {
        id: context
        property string id: "feed"
        property bool isFeed: true
        property bool isFeedOwner: true
        property bool feedReplies: true
        property bool feedClosed: false
        property string feedOwner: CurrentAccount.uri
        property bool allMessagesLoaded: true
        property int loadRequests: 0
        function loadMoreMessages() { loadRequests++; }
        property string lastSelfMessageId: "publication"
        property color color: "#00b0d0"
        property QtObject members: QtObject { property int count: 1 }
        signal scrollTo(string id)
        signal newInteraction()
        signal moreMessagesLoaded(int loadingRequestId)
        signal fileCopied(string fileName, string downloadDir)
    }

    MessageListView {
        id: list
        width: 900
        height: 700
        convContext: context
        model: ListModel {
            id: messages
            dynamicRoles: true
            property bool hasUnloadedFeedParents: false
        }
        delegate: DelegateChooser {
            role: "Type"
            DelegateChoice {
                roleValue: Interaction.Type.TEXT
                TextMessageDelegate {
                    convContext: context
                    // QML ListModel turns nested arrays into child models, unlike the C++ source.
                    readers: []
                    Component.onCompleted: {
                        bubble.isEdited = false;
                        list.computeChatview(this, index);
                    }
                }
            }
            DelegateChoice {
                roleValue: Interaction.Type.DATA_TRANSFER
                DataTransferMessageDelegate {
                    convContext: context
                    onLoaded: {
                        item.readers = [];
                        item.bubble.isEdited = false;
                    }
                    Component.onCompleted: list.computeChatview(this, index)
                }
            }
        }
    }

    TestCase {
        name: "FeedMessages"
        when: windowShown

        function message(id, replyTo, outgoing) {
            return {
                Id: id, Author: outgoing ? CurrentAccount.uri : "subscriber",
                Body: "A publication with content", ParsedBody: "A publication with content",
                OriginalBody: "", ParsedOriginalBody: "", ParentId: "", Timestamp: 1708025460,
                Type: Interaction.Type.TEXT, Status: Interaction.Status.SUCCESS,
                PreviousBodies: [], Reactions: {}, Readers: [], LinkPreviewInfo: {},
                ReplyTo: replyTo, ReplyToAuthor: replyTo ? CurrentAccount.uri : "",
                ReplyToBody: replyTo ? "A publication with content" : "",
                IsFeedReply: replyTo !== "", IsEmojiOnly: false, IsLastSent: outgoing,
                FeedDayStart: replyTo === "",
                TransferName: "", TID: "", TotalSize: 0, Index: 0
            };
        }

        function init() {
            context.isFeed = true;
            context.isFeedOwner = true;
            context.feedOwner = CurrentAccount.uri;
            context.allMessagesLoaded = true;
            context.loadRequests = 0;
            messages.hasUnloadedFeedParents = false;
            list.width = 900;
            messages.clear();
            wait(0);
            tryCompare(list, "count", 0);
        }

        function test_publication_layout_data() {
            return [{tag: "desktop", width: 900}, {tag: "compact", width: 320}];
        }

        function test_publication_layout(data) {
            list.width = data.width;
            messages.append(message("publication", "", true));
            tryVerify(() => list.itemAtIndex(0) !== null);
            waitForPolish(list);
            const item = list.itemAtIndex(0);
            verify(item.isOutgoing);
            compare(item.bubble.out, false);
            tryVerify(() => item.bubble.mapToItem(list, 0, 0).x >= Math.min(96, data.width * 0.12));
            tryVerify(() => item.bubble.mapToItem(list, item.bubble.width, 0).x <= list.width);
            const selfAvatar = findChild(item, "selfReadIconLoader");
            verify(selfAvatar !== null);
            compare(selfAvatar.active, false);
            context.isFeed = false;
            tryCompare(item.bubble, "out", true);
            tryCompare(selfAvatar, "active", true);
        }

        function test_publication_hides_author_name() {
            context.isFeedOwner = false;
            context.feedOwner = "subscriber";
            messages.append(message("publication", "", false));
            tryVerify(() => list.itemAtIndex(0) !== null);
            waitForPolish(list);
            const item = list.itemAtIndex(0);
            verify(!item.isOutgoing);
            const author = findChild(item, "messageAuthorName");
            verify(author !== null);
            // Every publication comes from the Feed owner, who is already named in
            // the header, so repeating the name above each one is noise.
            compare(author.visible, false);
            // Ordinary conversations keep naming the author of a sequence.
            context.isFeed = false;
            tryCompare(author, "visible", true);
        }

        function test_threaded_reply_shows_author_name() {
            context.isFeedOwner = false;
            context.feedOwner = "subscriber";
            messages.append(message("reply", "publication", false));
            tryVerify(() => list.itemAtIndex(0) !== null);
            waitForPolish(list);
            const reply = list.itemAtIndex(0);
            verify(reply.threadedReply);
            const author = findChild(reply, "messageAuthorName");
            verify(author !== null);
            // Replies can come from any subscriber, so they must stay attributed.
            compare(author.visible, true);
        }

        function test_reply_below_publication() {
            messages.append(message("reply", "publication", false));
            messages.append(message("publication", "", true));
            tryVerify(() => list.itemAtIndex(0) !== null && list.itemAtIndex(1) !== null);
            waitForPolish(list);
            const reply = list.itemAtIndex(0);
            const post = list.itemAtIndex(1);
            tryVerify(() => reply.bubble.mapToItem(list, 0, 0).x > post.bubble.mapToItem(list, 0, 0).x);
            verify(reply.mapToItem(list, 0, 0).y >= post.mapToItem(list, 0, post.height).y);
            verify(!findChild(reply, "messageReplyPreview").visible);
            compare(reply.canReply, false);
            context.isFeed = false;
            tryCompare(findChild(reply, "messageReplyPreview"), "visible", true);
        }

        function test_attachment_layout_data() {
            return test_publication_layout_data();
        }

        function test_attachment_layout(data) {
            list.width = data.width;
            const entry = message("publication", "", true);
            entry.Type = Interaction.Type.DATA_TRANSFER;
            entry.TID = "transfer";
            entry.TransferStatus = Interaction.TransferStatus.TRANSFER_CREATED;
            entry.TransferName = "publication.txt";
            entry.TotalSize = 100;
            messages.append(entry);
            tryVerify(() => list.itemAtIndex(0) !== null && list.itemAtIndex(0).item !== null);
            waitForPolish(list);
            const item = list.itemAtIndex(0).item;
            compare(item.bubble.out, false);
            tryVerify(() => item.bubble.mapToItem(list, 0, 0).x >= Math.min(96, data.width * 0.12));
            tryVerify(() => item.bubble.mapToItem(list, item.bubble.width, 0).x <= list.width);
            compare(findChild(item, "selfReadIconLoader").active, false);
        }

        function test_loads_missing_parents_and_stops_at_end() {
            context.allMessagesLoaded = false;
            messages.hasUnloadedFeedParents = true;
            tryCompare(context, "loadRequests", 1);
            context.allMessagesLoaded = true;
            context.moreMessagesLoaded(1);
            wait(200);
            compare(context.loadRequests, 1);
        }

        function test_photo_day_separator() {
            for (let i = 2; i >= 0; --i) {
                const entry = message("photo-" + i, "", true);
                entry.Type = Interaction.Type.DATA_TRANSFER;
                entry.TID = "transfer-" + i;
                entry.TransferStatus = Interaction.TransferStatus.TRANSFER_CREATED;
                entry.TransferName = "photo.png";
                entry.TotalSize = 100;
                entry.FeedDayStart = i === 0;
                messages.append(entry);
            }
            tryVerify(() => list.itemAtIndex(2) !== null && list.itemAtIndex(2).item !== null);
            waitForPolish(list);
            for (let i = 0; i < 3; ++i) {
                compare(list.itemAtIndex(i).showDay, i === 2);
                compare(list.itemAtIndex(i).item.showDay, i === 2);
            }
            messages.setProperty(2, "FeedDayStart", false);
            tryCompare(list.itemAtIndex(2).item, "showDay", false);
        }

        function test_z_live_feed_thread_model() {
            const feedId = FeedAdapter.createFeed(CurrentAccount.id, "Thread presentation", "", true);
            verify(feedId !== "");
            tryVerify(() => FeedAdapter.feeds.some(feed => feed.id === feedId));
            FeedAdapter.open(feedId);
            tryCompare(CurrentConversation, "isFeed", true);
            const model = MessagesAdapter.messageListModel;
            tryCompare(model, "feedMode", true);
            tryCompare(model, "count", 0);

            MessagesAdapter.sendMessageToUid("First publication", feedId);
            tryCompare(model, "count", 1);
            const firstId = model.get(0).Id;
            MessagesAdapter.sendMessageToUid("Second publication", feedId);
            tryCompare(model, "count", 2);
            MessagesAdapter.replyToId = firstId;
            MessagesAdapter.sendMessageToUid("Reply to the first publication", feedId);
            tryCompare(model, "count", 3);
            MessagesAdapter.replyToId = "";

            compare(model.get(0).Body, "Second publication");
            compare(model.get(1).ReplyTo, firstId);
            compare(model.get(1).IsFeedReply, true);
            compare(model.get(2).Id, firstId);
            const view = createTemporaryObject(liveFeedView, testRoot);
            verify(view !== null);
            tryCompare(view, "count", 3);
            tryVerify(() => view.itemAtIndex(1) !== null && view.itemAtIndex(1).threadedReply);
            tryVerify(() => view.itemAtIndex(2) !== null);
            const publication = view.itemAtIndex(2);
            compare(publication.bubble.out, false);
            compare(findChild(publication, "selfReadIconLoader").active, false);
            compare(publication.showDay, true);
            const differentDay = MessagesAdapter.getFormattedDay(model.get(0).Timestamp)
                                 !== MessagesAdapter.getFormattedDay(model.get(2).Timestamp);
            compare(view.itemAtIndex(0).showDay, differentDay);
            verify(FeedAdapter.closeFeed(CurrentAccount.id, feedId));
        }
    }
}
