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

#include "api/conversation.h"

#include <gtest/gtest.h>

namespace {
lrc::api::conversation::Info
makeConversation(const QStringList& participantUris)
{
    lrc::api::conversation::Info conversation("conversation-uid", nullptr);
    conversation.accountUri = "self-uri";
    for (const auto& uri : participantUris)
        conversation.participants.push_back({uri, lrc::api::member::Role::MEMBER});
    return conversation;
}
} // namespace

TEST(ConversationPeers, EmptyConversationHasNoRemotePeer)
{
    EXPECT_TRUE(makeConversation({}).remotePeerUri().isEmpty());
}

TEST(ConversationPeers, OwnerOnlyConversationHasNoRemotePeer)
{
    EXPECT_TRUE(makeConversation({"self-uri"}).remotePeerUri().isEmpty());
}

TEST(ConversationPeers, EmptyAndOwnerUrisAreSkipped)
{
    const auto peer = makeConversation({"", "self-uri", "peer-uri"}).remotePeerUri();

    EXPECT_EQ(peer, "peer-uri");
}

TEST(ConversationPeers, RegularConversationHasRemotePeer)
{
    const auto peer = makeConversation({"peer-uri"}).remotePeerUri();

    EXPECT_EQ(peer, "peer-uri");
}
