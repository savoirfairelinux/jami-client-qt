/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

#include "api/conversationmodel.h"

#include <gtest/gtest.h>

using lrc::api::ConversationModel;

/**
 * When the remote peer of a one-to-one conversation leaves it, the account owner can remain as the
 * only participant. The conversation then shows the account owner as if they were their own
 * contact, and the actions offered on it have no valid target: there is no contact to remove, and
 * nothing to migrate to a swarm.
 *
 * The purpose of these tests is to validate the logic deciding which peer, if any, an action on a
 * conversation applies to, so that callers stop indexing into an empty list or acting on the
 * account owner themselves.
 */

/**
 * A conversation can be listed before its participants are known.
 */
TEST(ConversationPeers, NoPeerWhenTheListIsEmpty)
{
    const auto result = ConversationModel::computeActionablePeer({}, "self-uri");
    EXPECT_FALSE(result.has_value()) << "An empty peer list must not yield a peer to act on";
}

/**
 * The degenerate conversation reported by users: the account owner is the only participant left.
 */
TEST(ConversationPeers, NoPeerWhenSelfIsTheOnlyParticipant)
{
    const auto result = ConversationModel::computeActionablePeer({"self-uri"}, "self-uri");
    EXPECT_FALSE(result.has_value()) << "The account owner is never a peer to act on";
}

/**
 * The nominal case must keep working.
 */
TEST(ConversationPeers, PeerIsReturnedForARegularDialog)
{
    const auto result = ConversationModel::computeActionablePeer({"peer-uri"}, "self-uri");
    ASSERT_TRUE(result.has_value()) << "A regular dialog has a peer to act on";
    EXPECT_EQ(*result, "peer-uri");
}

/**
 * Participants are not guaranteed to be free of the account owner nor of empty URIs.
 */
TEST(ConversationPeers, SelfAndEmptyUrisAreSkipped)
{
    const auto result = ConversationModel::computeActionablePeer({"", "self-uri", "peer-uri"}, "self-uri");
    ASSERT_TRUE(result.has_value()) << "A remaining peer must be found past self and empty URIs";
    EXPECT_EQ(*result, "peer-uri");
}
