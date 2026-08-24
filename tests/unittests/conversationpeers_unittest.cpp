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

/**
 * Removing such a conversation used to be carried out on the account owner: the peer list of a
 * one-to-one conversation holds the account owner once its remote peer has left, and the removal
 * took the first entry of that list as the contact to remove.
 */

namespace {
lrc::api::conversation::Info
makeConversation(lrc::api::conversation::Mode mode, const QStringList& participantUris)
{
    lrc::api::conversation::Info conversation("conversation-uid", nullptr);
    conversation.mode = mode;
    for (const auto& uri : participantUris) {
        lrc::api::member::Member member;
        member.uri = uri;
        conversation.participants.push_back(member);
    }
    return conversation;
}
} // namespace

/**
 * The degenerate conversation again, this time as the removal sees it.
 */
TEST(ConversationPeers, RemovingADialogWithNoPeerLeftTargetsNoContact)
{
    const auto conversation = makeConversation(lrc::api::conversation::Mode::ONE_TO_ONE, {"self-uri"});

    const auto result = ConversationModel::computeContactToRemove(conversation, {"self-uri"}, "self-uri", false, false);

    EXPECT_FALSE(result.has_value()) << "Removing the conversation must not remove the account owner";
}

/**
 * The nominal case must keep removing the contact behind the conversation.
 */
TEST(ConversationPeers, RemovingADialogTargetsItsPeer)
{
    const auto conversation = makeConversation(lrc::api::conversation::Mode::ONE_TO_ONE, {"self-uri", "peer-uri"});

    const auto result = ConversationModel::computeContactToRemove(conversation, {"peer-uri"}, "self-uri", false, false);

    ASSERT_TRUE(result.has_value()) << "A dialog with a peer left still removes that contact";
    EXPECT_EQ(*result, "peer-uri");
}

/**
 * Banning is asked for the peer, not for the conversation.
 */
TEST(ConversationPeers, BanningADialogTargetsItsPeer)
{
    const auto conversation = makeConversation(lrc::api::conversation::Mode::ONE_TO_ONE, {"self-uri", "peer-uri"});

    const auto result = ConversationModel::computeContactToRemove(conversation, {"peer-uri"}, "self-uri", true, false);

    ASSERT_TRUE(result.has_value()) << "Banning still applies to the peer";
    EXPECT_EQ(*result, "peer-uri");
}

/**
 * A legacy conversation only exists through its contact.
 */
TEST(ConversationPeers, RemovingALegacyDialogTargetsItsPeer)
{
    const auto conversation = makeConversation(lrc::api::conversation::Mode::NON_SWARM, {"peer-uri"});

    const auto result = ConversationModel::computeContactToRemove(conversation, {"peer-uri"}, "self-uri", false, false);

    ASSERT_TRUE(result.has_value()) << "A legacy conversation is removed through its contact";
    EXPECT_EQ(*result, "peer-uri");
}

/**
 * A group has no contact standing for it, and leaving a dialog while keeping its contact removes
 * the conversation only.
 */
TEST(ConversationPeers, RemovingAGroupOrKeepingTheContactTargetsNoContact)
{
    const auto group = makeConversation(lrc::api::conversation::Mode::INVITES_ONLY, {"self-uri", "peer-uri"});
    EXPECT_FALSE(ConversationModel::computeContactToRemove(group, {"peer-uri"}, "self-uri", false, false).has_value())
        << "A group is removed as a conversation";

    const auto dialog = makeConversation(lrc::api::conversation::Mode::ONE_TO_ONE, {"self-uri", "peer-uri"});
    EXPECT_FALSE(ConversationModel::computeContactToRemove(dialog, {"peer-uri"}, "self-uri", false, true).has_value())
        << "Keeping the contact removes the conversation only";
}
