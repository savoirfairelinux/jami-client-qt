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

#include "api/messagelistmodel.h"
#include "messagesadapter.h"

#include <gtest/gtest.h>

#include <QSignalSpy>

using namespace lrc::api;

namespace {

MessageListModel::container_t
makeBatch(int first, int count)
{
    // The daemon walks git backwards, so a load arrives newest first.
    MessageListModel::container_t batch;
    for (int i = first + count - 1; i >= first; --i) {
        interaction::Info info;
        info.type = interaction::Type::TEXT;
        info.body = QString("body-%1").arg(i);
        info.timestamp = 1700000000 + i;
        // Every commit points at the one before it, which is what lets a batch
        // find where it belongs.
        info.parentId = i > 0 ? QString("msg-%1").arg(i - 1) : QString();
        batch.append({QString("msg-%1").arg(i), std::move(info)});
    }
    return batch;
}

QString
bodyAt(MessageListModel& model, int row)
{
    return model.data(model.index(row, 0), MessageList::Role::Body).toString();
}

} // namespace

// A swarm load must land oldest first, matching the order the message list draws.
TEST(MessageListBatch, ABatchIsStoredOldestFirst)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(0, 5), 0);

    ASSERT_EQ(model.rowCount(), 5);
    for (int i = 0; i < 5; ++i) {
        EXPECT_EQ(bodyAt(model, i).toStdString(), QString("body-%1").arg(i).toStdString());
    }
}

// Older pages are prepended, so the history stays contiguous across loads.
TEST(MessageListBatch, AnOlderPageIsPrependedToTheHistory)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(10, 5), 0);
    model.insertRange(makeBatch(0, 10), 0);

    ASSERT_EQ(model.rowCount(), 15);
    EXPECT_EQ(bodyAt(model, 0).toStdString(), "body-0");
    EXPECT_EQ(bodyAt(model, 14).toStdString(), "body-14");
}

// loadSwarmUntil replays everything between the newest message and the target,
// so most of a jump batch is already in the model.
TEST(MessageListBatch, MessagesAlreadyLoadedAreSkipped)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(5, 5), 0);

    const auto inserted = model.insertRange(makeBatch(0, 10), 0);

    EXPECT_EQ(model.rowCount(), 10);
    ASSERT_EQ(inserted.size(), 5);
    EXPECT_EQ(inserted.first().toStdString(), "msg-4");
    EXPECT_EQ(inserted.last().toStdString(), "msg-0");
    EXPECT_EQ(bodyAt(model, 0).toStdString(), "body-0");
    EXPECT_EQ(bodyAt(model, 9).toStdString(), "body-9");
}

TEST(MessageListBatch, ABatchOfNothingNewChangesNothing)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(0, 5), 0);

    QSignalSpy inserts(&model, &QAbstractItemModel::rowsInserted);
    EXPECT_TRUE(model.insertRange(makeBatch(0, 5), 0).isEmpty());
    EXPECT_EQ(model.rowCount(), 5);
    EXPECT_EQ(inserts.count(), 0);
}

// The reason this exists: a per-message insert makes the sorting proxy remap and
// the message list re-read its count once per message, which is what stalls the
// GUI thread when a jump replays a long history.
TEST(MessageListBatch, ABatchCostsOneModelTransaction)
{
    MessageListModel model(nullptr);
    QSignalSpy inserts(&model, &QAbstractItemModel::rowsInserted);

    model.insertRange(makeBatch(0, 500), 0);

    ASSERT_EQ(model.rowCount(), 500);
    EXPECT_EQ(inserts.count(), 1);
    EXPECT_EQ(inserts.first().at(1).toInt(), 0);
    EXPECT_EQ(inserts.first().at(2).toInt(), 499);
}


// A reply parent, or the window around a jump target, is fetched on its own and
// has nothing loaded next to it. It belongs before everything held, and must not
// be mistaken for the page that continues the history.
TEST(MessageListBatch, ADetachedOlderMessageLandsAtTheOldestEnd)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(10, 5), 0);

    model.insertRange(makeBatch(0, 1), 0);

    ASSERT_EQ(model.rowCount(), 6);
    EXPECT_EQ(bodyAt(model, 0).toStdString(), "body-0");
    EXPECT_EQ(bodyAt(model, 1).toStdString(), "body-10");
}

// Once a detached message is held, the oldest end is no longer where a page of
// history goes: it has to land against the commit it actually follows.
TEST(MessageListBatch, APageLandsAtItsSeamNotTheOldestEnd)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(10, 5), 0);
    model.insertRange(makeBatch(0, 1), 0);

    // Paging up from the newest range: joins msg-10, not msg-0.
    model.insertRange(makeBatch(5, 5), 0);

    ASSERT_EQ(model.rowCount(), 11);
    EXPECT_EQ(bodyAt(model, 0).toStdString(), "body-0");
    EXPECT_EQ(bodyAt(model, 1).toStdString(), "body-5");
    EXPECT_EQ(bodyAt(model, 6).toStdString(), "body-10");
}

// Closing the gap has to leave one ordered history, not two ranges either side
// of the message that was fetched on its own.
TEST(MessageListBatch, ClosingTheGapLeavesTheHistoryOrdered)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(10, 5), 0);
    model.insertRange(makeBatch(0, 1), 0);
    model.insertRange(makeBatch(5, 5), 0);

    model.insertRange(makeBatch(1, 4), 0);

    ASSERT_EQ(model.rowCount(), 15);
    for (int i = 0; i < 15; ++i) {
        EXPECT_EQ(bodyAt(model, i).toStdString(), QString("body-%1").arg(i).toStdString());
    }
}

// The message list draws the proxy, so what the proxy admits is what the row
// count, and with it the scrollbar, is sized from.
TEST(MessageListWindow, TheListShowsOnlyTheWindow)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(0, 15), 0);

    FilteredMsgListModel proxy;
    proxy.setSourceModel(&model);
    ASSERT_EQ(proxy.count(), 15);

    proxy.setWindow("msg-10", "msg-14");

    EXPECT_EQ(proxy.count(), 5);
    // Proxy row 0 is the newest message.
    EXPECT_EQ(proxy.data(proxy.index(0, 0), MessageList::Role::Body).toString().toStdString(),
              "body-14");
}

// A reply parent is fetched on its own and must not appear in the timeline,
// but the preview still has to be able to read it.
TEST(MessageListWindow, AMessageOutsideTheWindowStaysResolvable)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(10, 5), 0);

    FilteredMsgListModel proxy;
    proxy.setSourceModel(&model);
    proxy.setWindow("msg-10", "msg-14");

    model.insertRange(makeBatch(0, 1), 0);

    EXPECT_EQ(proxy.count(), 5);
    EXPECT_EQ(model.rowCount(), 6);
    EXPECT_NE(model.indexOfMessage("msg-0"), -1);
}

// Splicing a batch in shifts every row after it, so a window held as row
// numbers would silently slide onto the wrong messages.
TEST(MessageListWindow, TheWindowFollowsItsIdsWhenABatchIsSpliced)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(10, 5), 0);

    FilteredMsgListModel proxy;
    proxy.setSourceModel(&model);
    proxy.setWindow("msg-10", "msg-14");

    model.insertRange(makeBatch(5, 5), 0);

    ASSERT_EQ(proxy.count(), 5);
    EXPECT_EQ(proxy.data(proxy.index(0, 0), MessageList::Role::Body).toString().toStdString(),
              "body-14");
    EXPECT_EQ(proxy.data(proxy.index(4, 0), MessageList::Role::Body).toString().toStdString(),
              "body-10");
}

// A reply preview reads the parent through the model, so when the parent is
// fetched after the reply is already on screen, the reply's row has to be
// announced as changed or the preview stays blank.
TEST(MessageListReply, TheReplyIsRefreshedWhenItsParentArrives)
{
    MessageListModel model(nullptr);

    MessageListModel::container_t reply;
    interaction::Info info;
    info.type = interaction::Type::TEXT;
    info.body = "the reply";
    info.parentId = "msg-9";
    info.commit["reply-to"] = "msg-0";
    reply.append({QString("reply-1"), std::move(info)});
    model.insertRange(std::move(reply), 0);

    ASSERT_EQ(model.data(model.index(0, 0), MessageList::Role::ReplyToBody).toString().toStdString(),
              "");

    QSignalSpy changed(&model, &QAbstractItemModel::dataChanged);
    model.insertRange(makeBatch(0, 1), 0);

    const auto replyRow = model.indexOfMessage("reply-1");
    EXPECT_EQ(model.data(model.index(replyRow, 0), MessageList::Role::ReplyToBody)
                  .toString()
                  .toStdString(),
              "body-0");
    ASSERT_GE(changed.count(), 1);
}

// Trimming has to reach the list as row removals. A reset would drop the view's
// position, which is the scrollbar jump this window exists to avoid.
TEST(MessageListWindow, TrimmingRemovesRowsRatherThanResetting)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(0, 40), 0);

    FilteredMsgListModel proxy;
    proxy.setSourceModel(&model);
    ASSERT_EQ(proxy.count(), 40);

    QSignalSpy removed(&proxy, &QAbstractItemModel::rowsRemoved);
    QSignalSpy reset(&proxy, &QAbstractItemModel::modelReset);

    proxy.setWindow("msg-10", "msg-29");

    EXPECT_EQ(proxy.count(), 20);
    EXPECT_EQ(reset.count(), 0);
    EXPECT_GE(removed.count(), 1);
}

// Growing the window back has to arrive as insertions, so scrolling into
// history that was trimmed away restores it in place.
TEST(MessageListWindow, GrowingTheWindowInsertsRows)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(0, 40), 0);

    FilteredMsgListModel proxy;
    proxy.setSourceModel(&model);
    proxy.setWindow("msg-10", "msg-29");

    QSignalSpy inserted(&proxy, &QAbstractItemModel::rowsInserted);
    QSignalSpy reset(&proxy, &QAbstractItemModel::modelReset);

    proxy.setWindow("msg-0", "msg-29");

    EXPECT_EQ(proxy.count(), 30);
    EXPECT_EQ(reset.count(), 0);
    EXPECT_GE(inserted.count(), 1);
}

// A jump to a message that was trimmed out of the shown run must not go back to
// the daemon for history the client already has.
TEST(MessageListWindow, AMessageTrimmedAwayIsRevealedNotRefetched)
{
    MessageListModel model(nullptr);
    model.insertRange(makeBatch(0, 40), 0);

    FilteredMsgListModel proxy;
    proxy.setSourceModel(&model);
    proxy.setWindow("msg-30", "msg-39");
    ASSERT_EQ(proxy.getDisplayIndex("msg-5"), -1);

    EXPECT_TRUE(proxy.showMessage("msg-5"));
    EXPECT_NE(proxy.getDisplayIndex("msg-5"), -1);

    // A message the source really does not hold still has to be fetched.
    EXPECT_FALSE(proxy.showMessage("msg-999"));
}
