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
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

TestWrapper {
    FeedListView {
        id: uut

        width: 900
        height: 1400

        TestCase {
            name: "FeedListView"
            when: windowShown

            readonly property var posts: MessagesAdapter.threadedMessageListModel
            property string olderPostId
            property string newerPostId
            property string commentId
            property string replyToCommentId

            function messageId(body) {
                const flat = MessagesAdapter.messageListModel;
                for (let row = 0; row < flat.count; ++row) {
                    const message = flat.get(row);
                    if (message.Body === body)
                        return message.Id;
                }
                return "";
            }

            function send(body, replyTo) {
                MessagesAdapter.replyToId = replyTo || "";
                MessagesAdapter.sendMessage(body);
                MessagesAdapter.replyToId = "";
                tryVerify(() => messageId(body) !== "", 10000, "message was not added: " + body);
                return messageId(body);
            }

            function post(id) {
                const row = posts.getDisplayIndex(id);
                verify(row >= 0, "post is not listed");
                uut.positionViewAtIndex(row, ListView.Contain);
                let item = null;
                tryVerify(() => {
                    item = uut.itemAtIndex(posts.getDisplayIndex(id));
                    return item !== null && item.objectName === "feedPost";
                }, 5000, "post delegate was not created");
                return item;
            }

            function comments(postItem) {
                const loader = findChild(postItem, "feedComments");
                return loader && loader.item ? loader.item : null;
            }

            function waitUntilOpen(postItem) {
                tryCompare(findChild(postItem, "feedCommentsArea"), "reveal", 1);
            }

            function commentRows(postItem) {
                const list = comments(postItem);
                const rows = [];
                if (list)
                    for (let i = 0; i < list.children.length; ++i)
                        if (list.children[i].objectName === "feedComment")
                            rows.push(list.children[i]);
                return rows;
            }

            function initTestCase() {
                const stamp = Date.now();
                olderPostId = send("older post " + stamp);
                newerPostId = send("newer post " + stamp);
                commentId = send("a comment " + stamp, olderPostId);
                replyToCommentId = send("a reply to the comment " + stamp, commentId);
            }

            function cleanup() {
                uut.expandedPosts = {};
                MessagesAdapter.replyToId = "";
            }

            // Runs check() on a view shorter than the posts, so it can scroll, with the older post in sight.
            function withShortView(check) {
                const fullHeight = uut.height;
                uut.height = 300;
                try {
                    const item = post(olderPostId);
                    uut.positionViewAtIndex(posts.getDisplayIndex(olderPostId), ListView.Contain);
                    waitForRendering(uut);
                    const card = findChild(item, "feedPostCard");
                    const top = card.mapToItem(uut, 0, 0).y;
                    check(item, () => {
                        waitForRendering(uut);
                        fuzzyCompare(card.mapToItem(uut, 0, 0).y, top, 1, "the post moved");
                    });
                } finally {
                    uut.height = fullHeight;
                }
            }

            function test_commentsButtonOpensCommentsAndStartsAComment() {
                const item = post(olderPostId);
                const button = findChild(item, "feedCommentsButton");

                mouseClick(button);
                compare(MessagesAdapter.replyToId, olderPostId);
                tryVerify(() => commentRows(item).length === 2, 5000, "comments did not open");
                waitUntilOpen(item);

                mouseClick(button);
                compare(MessagesAdapter.replyToId, "", "closing did not cancel the comment");
                tryVerify(() => comments(item) === null, 5000, "comments did not close");
            }

            function test_closingCommentsCancelsAReplyToOneOfThem() {
                uut.setExpanded(olderPostId, true);
                const item = post(olderPostId);
                MessagesAdapter.replyToId = commentId;
                mouseClick(findChild(item, "feedCommentsButton"));
                compare(MessagesAdapter.replyToId, "");
                verify(!uut.isExpanded(olderPostId));
            }

            function test_commentsAreOldestFirstWithReplyHint() {
                uut.setExpanded(olderPostId, true);
                const item = post(olderPostId);
                tryVerify(() => commentRows(item).length === 2);
                waitUntilOpen(item);
                const rows = commentRows(item);
                compare(rows[0].commentId, commentId);
                compare(rows[1].commentId, replyToCommentId);
                verify(!findChild(rows[0], "feedCommentReplyingTo").visible);
                verify(findChild(rows[1], "feedCommentReplyingTo").visible);
            }

            function test_replyButtonRepliesToTheComment() {
                uut.setExpanded(olderPostId, true);
                const item = post(olderPostId);
                tryVerify(() => commentRows(item).length === 2);
                waitUntilOpen(item);
                const rows = commentRows(item);
                mouseClick(findChild(rows[0], "feedCommentReplyButton"));
                compare(MessagesAdapter.replyToId, commentId);
                verify(rows[0].isTarget);
                verify(!rows[1].isTarget);
            }

            function test_scrollToCommentOpensItsPost() {
                CurrentConversation.scrollToMsg(replyToCommentId);
                verify(uut.isExpanded(olderPostId));
                verify(!uut.isExpanded(newerPostId));
            }

            function reactionPill(postItem, emoji) {
                const pills = findChild(postItem, "feedReactions");
                for (let i = 0; pills && i < pills.children.length; ++i)
                    if (pills.children[i].objectName === "feedReactionPill" && pills.children[i].emoji === emoji)
                        return pills.children[i];
                return null;
            }

            function test_reactionPillTogglesOurReaction() {
                const emoji = "🎉";
                const item = post(newerPostId);
                compare(reactionPill(item, emoji), null);

                MessagesAdapter.addEmojiReaction(CurrentConversation.id, emoji, newerPostId);
                tryVerify(() => reactionPill(item, emoji) !== null, 10000, "no pill for our reaction");
                const pill = reactionPill(item, emoji);
                compare(pill.count, 1);
                verify(pill.checked, "our own reaction is not checked");

                mouseClick(pill);
                tryVerify(() => reactionPill(item, emoji) === null, 10000, "clicking our pill did not remove the reaction");
            }

            function test_tallPhotoIsShownWholeWithinTheHeightCap() {
                const path = "/tmp/feed_tall_photo_" + Date.now() + ".png";
                let saved = false;
                tallPhoto.grabToImage(result => saved = result.saveToFile(path));
                tryVerify(() => saved, 5000, "could not write the test photo");

                const before = MessagesAdapter.messageListModel.count;
                MessagesAdapter.sendFile(path);
                tryVerify(() => MessagesAdapter.messageListModel.count > before, 10000, "photo post was not added");
                const photoPostId = MessagesAdapter.messageListModel.get(0).Id;

                let frame = null;
                tryVerify(() => {
                    const image = findChild(post(photoPostId), "feedMediaImage");
                    frame = image && image.ready ? findChild(image, "feedMediaFrame") : null;
                    return frame !== null;
                }, 10000, "photo did not load");
                fuzzyCompare(frame.height, JamiTheme.maxImageHeight, 1);
                fuzzyCompare(frame.width / frame.height, 300 / 900, 0.01);
            }
        }
    }

    Rectangle {
        id: tallPhoto

        width: 300
        height: 900
        x: -width
        gradient: Gradient {
            GradientStop { position: 0; color: "red" }
            GradientStop { position: 1; color: "blue" }
        }
    }
}
