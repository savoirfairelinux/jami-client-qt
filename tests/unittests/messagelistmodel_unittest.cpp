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

TEST(FilteredMsgListModel, HidesMembershipEventsWhenEnabled)
{
    MessageListModel model(nullptr);
    auto memberEvent = makeTextMessage();
    memberEvent.type = interaction::Type::CONTACT;
    ASSERT_TRUE(model.append(QStringLiteral("member-event"), memberEvent));
    ASSERT_TRUE(model.append(QStringLiteral("text"), makeTextMessage()));

    FilteredMsgListModel proxy;
    proxy.setSourceModel(&model);
    EXPECT_EQ(proxy.rowCount(), 2);

    ASSERT_TRUE(proxy.setProperty("hideMembershipEvents", true));
    EXPECT_EQ(proxy.rowCount(), 1);
    EXPECT_TRUE(proxyIds(proxy).contains(QStringLiteral("text")));

    ASSERT_TRUE(proxy.setProperty("hideMembershipEvents", false));
    EXPECT_EQ(proxy.rowCount(), 2);
}

TEST(ThreadedMsgListModel, HidesMembershipEventsWhenEnabled)
{
    MessageListModel model(nullptr);
    auto memberEvent = makeTextMessage(QStringLiteral("root"));
    memberEvent.type = interaction::Type::CONTACT;
    ASSERT_TRUE(model.append(QStringLiteral("root"), makeTextMessage()));
    ASSERT_TRUE(model.append(QStringLiteral("member-event"), memberEvent));
    ASSERT_TRUE(model.append(QStringLiteral("reply"), makeTextMessage(QStringLiteral("root"))));

    FilteredMsgListModel filtered;
    filtered.setSourceModel(&model);
    ThreadedMsgListModel proxy;
    proxy.setSourceModel(&filtered);
    proxy.setThreadId(QStringLiteral("root"));
    EXPECT_EQ(proxy.rowCount(), 3);

    ASSERT_TRUE(filtered.setProperty("hideMembershipEvents", true));
    QCoreApplication::processEvents();
    EXPECT_EQ(proxy.rowCount(), 2);
    EXPECT_TRUE(proxyIds(proxy).contains(QStringLiteral("reply")));
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
