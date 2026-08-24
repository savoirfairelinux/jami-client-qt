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

