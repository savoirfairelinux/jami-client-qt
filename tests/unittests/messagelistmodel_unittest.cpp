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

using namespace lrc::api;

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
