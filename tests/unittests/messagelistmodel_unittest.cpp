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

using namespace lrc::api;

namespace {

interaction::Info
makeTextMessage(const QString& replyTo = {})
{
    interaction::Info message;
    message.type = interaction::Type::TEXT;
    message.body = QStringLiteral("body");
    if (!replyTo.isEmpty())
        message.commit[QStringLiteral("reply-to")] = replyTo;
    return message;
}

QStringList
proxyIds(const QSortFilterProxyModel& proxy)
{
    QStringList ids;
    for (int row = 0; row < proxy.rowCount(); ++row)
        ids.append(proxy.data(proxy.index(row, 0), MessageList::Id).toString());
    return ids;
}

} // namespace

TEST(MessageListModel, ResolvesThreadRootTransitively)
{
    MessageListModel model(nullptr);
    ASSERT_TRUE(model.append(QStringLiteral("root"), makeTextMessage()));
    ASSERT_TRUE(model.append(QStringLiteral("reply"), makeTextMessage(QStringLiteral("root"))));
    ASSERT_TRUE(model.append(QStringLiteral("nested"), makeTextMessage(QStringLiteral("reply"))));
    ASSERT_TRUE(model.append(QStringLiteral("other"), makeTextMessage()));

    EXPECT_EQ(model.data(QStringLiteral("root"), MessageList::ThreadRootId).toString(), QStringLiteral("root"));
    EXPECT_EQ(model.data(QStringLiteral("reply"), MessageList::ThreadRootId).toString(), QStringLiteral("root"));
    EXPECT_EQ(model.data(QStringLiteral("nested"), MessageList::ThreadRootId).toString(), QStringLiteral("root"));
    EXPECT_EQ(model.data(QStringLiteral("root"), MessageList::ThreadReplyCount).toInt(), 2);
    EXPECT_EQ(model.data(QStringLiteral("other"), MessageList::ThreadReplyCount).toInt(), 0);
}

TEST(MessageListModel, ResolvesThreadRootWhenHistoryLoadsAfterReplies)
{
    MessageListModel model(nullptr);
    ASSERT_TRUE(model.append(QStringLiteral("nested"), makeTextMessage(QStringLiteral("reply"))));
    ASSERT_TRUE(model.insert(QStringLiteral("reply"), makeTextMessage(QStringLiteral("root")), 0));

    EXPECT_EQ(model.data(QStringLiteral("nested"), MessageList::ThreadRootId).toString(), QStringLiteral("root"));

    ASSERT_TRUE(model.insert(QStringLiteral("root"), makeTextMessage(), 0));

    EXPECT_EQ(model.data(QStringLiteral("nested"), MessageList::ThreadRootId).toString(), QStringLiteral("root"));
    EXPECT_EQ(model.data(QStringLiteral("root"), MessageList::ThreadReplyCount).toInt(), 2);
}

TEST(MessageListModel, ClearingResetsThreadIndex)
{
    MessageListModel model(nullptr);
    ASSERT_TRUE(model.append(QStringLiteral("root"), makeTextMessage()));
    ASSERT_TRUE(model.append(QStringLiteral("reply"), makeTextMessage(QStringLiteral("root"))));

    model.clear();
    ASSERT_TRUE(model.append(QStringLiteral("root"), makeTextMessage()));

    EXPECT_EQ(model.data(QStringLiteral("root"), MessageList::ThreadReplyCount).toInt(), 0);
}

TEST(FilteredMsgListModel, HidesRepliesOnlyInThreadedView)
{
    MessageListModel model(nullptr);
    ASSERT_TRUE(model.append(QStringLiteral("root"), makeTextMessage()));
    ASSERT_TRUE(model.append(QStringLiteral("reply"), makeTextMessage(QStringLiteral("root"))));

    FilteredMsgListModel proxy;
    proxy.setSourceModel(&model);
    EXPECT_EQ(proxy.rowCount(), 2);

    proxy.setThreaded(true);
    EXPECT_EQ(proxyIds(proxy), QStringList {QStringLiteral("root")});

    proxy.setThreaded(false);
    EXPECT_EQ(proxy.rowCount(), 2);
}

TEST(ThreadMsgListModel, ShowsRootAndItsRepliesOnly)
{
    MessageListModel model(nullptr);
    ASSERT_TRUE(model.append(QStringLiteral("root"), makeTextMessage()));
    ASSERT_TRUE(model.append(QStringLiteral("reply"), makeTextMessage(QStringLiteral("root"))));
    ASSERT_TRUE(model.append(QStringLiteral("other"), makeTextMessage()));
    ASSERT_TRUE(model.append(QStringLiteral("nested"), makeTextMessage(QStringLiteral("reply"))));
    ASSERT_TRUE(model.append(QStringLiteral("other-reply"), makeTextMessage(QStringLiteral("other"))));

    ThreadMsgListModel proxy;
    proxy.setSourceModel(&model);
    EXPECT_EQ(proxy.rowCount(), 0);

    proxy.setRootId(QStringLiteral("root"));
    auto ids = proxyIds(proxy);
    ids.sort();
    EXPECT_EQ(ids, (QStringList {QStringLiteral("nested"), QStringLiteral("reply"), QStringLiteral("root")}));

    ASSERT_TRUE(model.append(QStringLiteral("late-reply"), makeTextMessage(QStringLiteral("nested"))));
    EXPECT_EQ(proxy.rowCount(), 4);
}

TEST(MessageListModel, FindsReactionIdForAuthorAndEmoji)
{
    MessageListModel model(nullptr);
    interaction::Info message;
    message.body = QStringLiteral("message body");
    ASSERT_TRUE(model.append(QStringLiteral("message-id"), message));

    model.addReaction(QStringLiteral("message-id"),
                      {{QStringLiteral("id"), QStringLiteral("other-reaction-id")},
                       {QStringLiteral("author"), QStringLiteral("other")},
                       {QStringLiteral("body"), QStringLiteral("👍")}});
    model.addReaction(QStringLiteral("message-id"),
                      {{QStringLiteral("id"), QStringLiteral("my-reaction-id")},
                       {QStringLiteral("author"), QStringLiteral("me")},
                       {QStringLiteral("body"), QStringLiteral("👍")}});

    EXPECT_EQ(model.reactionIdFor(QStringLiteral("message-id"), QStringLiteral("me"), QStringLiteral("👍")),
              QStringLiteral("my-reaction-id"));
    EXPECT_TRUE(model.reactionIdFor(QStringLiteral("message-id"), QStringLiteral("me"), QStringLiteral("👎")).isEmpty());
    EXPECT_TRUE(
        model.reactionIdFor(QStringLiteral("missing-message"), QStringLiteral("me"), QStringLiteral("👍")).isEmpty());
}

TEST(MessageListModel, RemovingReactionKeepsOtherReactionsFromSameAuthor)
{
    MessageListModel model(nullptr);
    interaction::Info message;
    message.body = QStringLiteral("message body");
    ASSERT_TRUE(model.append(QStringLiteral("message-id"), message));

    model.addReaction(QStringLiteral("message-id"),
                      {{QStringLiteral("id"), QStringLiteral("keep-before")},
                       {QStringLiteral("author"), QStringLiteral("me")},
                       {QStringLiteral("body"), QStringLiteral("🔥")}});
    model.addReaction(QStringLiteral("message-id"),
                      {{QStringLiteral("id"), QStringLiteral("remove")},
                       {QStringLiteral("author"), QStringLiteral("me")},
                       {QStringLiteral("body"), QStringLiteral("👍")}});
    model.addReaction(QStringLiteral("message-id"),
                      {{QStringLiteral("id"), QStringLiteral("keep-after")},
                       {QStringLiteral("author"), QStringLiteral("me")},
                       {QStringLiteral("body"), QStringLiteral("😂")}});

    model.rmReaction(QStringLiteral("message-id"), QStringLiteral("remove"));

    EXPECT_EQ(model.reactionIdFor(QStringLiteral("message-id"), QStringLiteral("me"), QStringLiteral("🔥")),
              QStringLiteral("keep-before"));
    EXPECT_TRUE(model.reactionIdFor(QStringLiteral("message-id"), QStringLiteral("me"), QStringLiteral("👍")).isEmpty());
    EXPECT_EQ(model.reactionIdFor(QStringLiteral("message-id"), QStringLiteral("me"), QStringLiteral("😂")),
              QStringLiteral("keep-after"));
    EXPECT_EQ(model.data(QStringLiteral("message-id"), MessageList::Body).toString(), QStringLiteral("message body"));
}
