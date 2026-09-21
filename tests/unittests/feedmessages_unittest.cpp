/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "app/messagesadapter.h"

#include <QDateTime>
#include <gtest/gtest.h>

namespace {
using lrc::api::MessageListModel;
using lrc::api::interaction::Info;
using lrc::api::interaction::Type;
using Role = lrc::api::MessageList::Role;

Info
message(Type type = Type::TEXT, const QString& replyTo = {}, std::time_t timestamp = 0)
{
    Info info;
    info.type = type;
    info.body = "Content";
    info.commit["reply-to"] = replyTo;
    info.timestamp = timestamp;
    return info;
}

QStringList
displayedOrder(const FilteredMsgListModel& model)
{
    QStringList result;
    // The view lays the reversed proxy out from bottom to top.
    for (int row = model.rowCount() - 1; row >= 0; --row)
        result.push_back(model.index(row, 0).data(Role::Id).toString());
    return result;
}
} // namespace

TEST(FeedMessages, HidesEventsOnlyInFeeds)
{
    MessageListModel source(nullptr);
    source.append("created", message(Type::INITIAL));
    source.append("invited", message(Type::CONTACT));
    source.append("call", message(Type::CALL));
    source.append("post", message());
    source.append("file", message(Type::DATA_TRANSFER));
    FilteredMsgListModel proxy;
    proxy.setSourceModel(&source);
    EXPECT_EQ(proxy.rowCount(), 5);
    proxy.setProperty("feedMode", true);
    EXPECT_EQ(displayedOrder(proxy), (QStringList {"post", "file"}));
    proxy.setProperty("feedMode", false);
    EXPECT_EQ(proxy.rowCount(), 5);
}

TEST(FeedMessages, GroupsLateRepliesUnderTheirPublication)
{
    MessageListModel source(nullptr);
    source.append("first", message());
    source.append("second", message());
    source.append("first-reply", message(Type::TEXT, "first"));
    source.append("second-reply", message(Type::TEXT, "second"));
    FilteredMsgListModel proxy;
    proxy.setSourceModel(&source);
    proxy.setProperty("feedMode", true);
    source.append("late-reply", message(Type::DATA_TRANSFER, "first"));
    EXPECT_EQ(displayedOrder(proxy), (QStringList {"first", "first-reply", "late-reply", "second", "second-reply"}));
    EXPECT_EQ(proxy.getDisplayIndex("late-reply"), 2);
    EXPECT_TRUE(proxy.get(2).value("IsFeedReply").toBool());
    proxy.setProperty("feedMode", false);
    EXPECT_EQ(displayedOrder(proxy), (QStringList {"first", "second", "first-reply", "second-reply", "late-reply"}));
}

TEST(FeedMessages, ReattachesRepliesWhenAnOlderParentLoads)
{
    MessageListModel source(nullptr);
    source.append("other-post", message());
    source.append("reply", message(Type::TEXT, "older-post"));
    FilteredMsgListModel proxy;
    proxy.setSourceModel(&source);
    proxy.setProperty("feedMode", true);
    EXPECT_TRUE(proxy.property("hasUnloadedFeedParents").toBool());
    EXPECT_EQ(proxy.rowCount(), 2);
    EXPECT_FALSE(proxy.get(0).value("IsFeedReply").toBool());
    source.insert("older-post", message(), 0);
    EXPECT_FALSE(proxy.property("hasUnloadedFeedParents").toBool());
    EXPECT_EQ(displayedOrder(proxy), (QStringList {"older-post", "reply", "other-post"}));
    EXPECT_TRUE(proxy.get(proxy.getDisplayIndex("reply")).value("IsFeedReply").toBool());
}

TEST(FeedMessages, UpdatesThreadsAndRetainsDeletedPublications)
{
    MessageListModel source(nullptr);
    source.append("first", message());
    source.append("second", message());
    source.append("reply", message(Type::TEXT, "second"));
    FilteredMsgListModel proxy;
    proxy.setSourceModel(&source);
    proxy.setProperty("feedMode", true);
    source.update("reply", message(Type::TEXT, "first"));
    EXPECT_EQ(displayedOrder(proxy), (QStringList {"first", "reply", "second"}));
    auto deleted = message();
    deleted.body.clear();
    source.update("first", deleted);
    EXPECT_EQ(displayedOrder(proxy), (QStringList {"first", "reply", "second"}));
    source.clear();
    EXPECT_EQ(proxy.rowCount(), 0);
    EXPECT_FALSE(proxy.property("hasUnloadedFeedParents").toBool());
    EXPECT_EQ(proxy.getDisplayIndex("first"), -1);
}

TEST(FeedMessages, SwitchingSourceDoesNotKeepPreviousThreads)
{
    MessageListModel first(nullptr);
    first.append("post", message());
    first.append("reply", message(Type::TEXT, "post"));
    MessageListModel second(nullptr);
    second.append("reply", message(Type::TEXT, "post"));
    FilteredMsgListModel proxy;
    proxy.setSourceModel(&first);
    proxy.setProperty("feedMode", true);
    proxy.setSourceModel(&second);
    EXPECT_TRUE(proxy.property("hasUnloadedFeedParents").toBool());
    EXPECT_FALSE(proxy.get(0).value("IsFeedReply").toBool());
    first.clear();
    EXPECT_EQ(proxy.rowCount(), 1);
    proxy.setSourceModel(nullptr);
    EXPECT_EQ(proxy.rowCount(), 0);
}

TEST(FeedMessages, DaySeparatorsIgnoreRepliesAndGroupPhotos)
{
    const auto today = QDateTime(QDate(2026, 9, 20), QTime(12, 0)).toSecsSinceEpoch();
    const auto tomorrow = QDateTime(QDate(2026, 9, 21), QTime(12, 0)).toSecsSinceEpoch();
    MessageListModel source(nullptr);
    source.append("first", message(Type::TEXT, {}, today));
    source.append("photo", message(Type::DATA_TRANSFER, {}, today + 60));
    source.append("reply", message(Type::TEXT, "first", tomorrow));
    source.append("next-day-photo", message(Type::DATA_TRANSFER, {}, tomorrow + 60));
    FilteredMsgListModel proxy;
    proxy.setSourceModel(&source);
    proxy.setProperty("feedMode", true);
    auto dayStart = [&](const QString& id) {
        return proxy.get(proxy.getDisplayIndex(id)).value("FeedDayStart").toBool();
    };
    EXPECT_TRUE(dayStart("first"));
    EXPECT_FALSE(dayStart("photo"));
    EXPECT_FALSE(dayStart("reply"));
    EXPECT_TRUE(dayStart("next-day-photo"));
}

TEST(FeedMessages, DaySeparatorMovesWhenOlderPhotosLoad)
{
    const auto midnight = QDateTime(QDate(2026, 9, 20), QTime(0, 0)).toSecsSinceEpoch();
    MessageListModel source(nullptr);
    source.append("photo", message(Type::DATA_TRANSFER, {}, midnight + 60));
    FilteredMsgListModel proxy;
    proxy.setSourceModel(&source);
    proxy.setProperty("feedMode", true);
    auto dayStart = [&](const QString& id) {
        return proxy.get(proxy.getDisplayIndex(id)).value("FeedDayStart").toBool();
    };
    EXPECT_TRUE(dayStart("photo"));
    source.insert("older-photo", message(Type::DATA_TRANSFER, {}, midnight), 0);
    EXPECT_TRUE(dayStart("older-photo"));
    EXPECT_FALSE(dayStart("photo"));
    source.with("older-photo", [midnight](const QString&, Info& info) { info.timestamp = midnight - 1; });
    Q_EMIT source.dataChanged(source.index(0, 0), source.index(0, 0), {Role::Timestamp});
    EXPECT_TRUE(dayStart("older-photo"));
    EXPECT_TRUE(dayStart("photo"));
}
