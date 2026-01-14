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

#include "api/callmodel.h"

#include <gtest/gtest.h>

using lrc::api::CallModel;

/**
 * For context, let's imagine that Alice calls Bob from the conversation she has with him.
 * Then, Alice adds Charlie to the call, making it a conference.
 * If Bob leaves the conference, we want Alice's client to 'redirect' the remaining call with Charlie
 * to the conversation she has with Charlie, instead of remaining in the conversation with Bob.
 *
 * See https://git.jami.net/savoirfairelinux/jami-client-qt/-/issues/1569 for more details.
 *
 * The purpose of these tests is to validate the logic that decides whether a conversation switch
 * should happen when a participant leaves a conference, and if so, which conversation to switch to.
 */

/**
 * The conversation switch mecanism is only applicable in 1:1 conversations.
 */
TEST(ConversationSwitch, NoSwitchForNonDialogConversations)
{
    const bool currentIsCoreDialog = false;
    const QString currentConversationUid = "convA";
    const QStringList remoteParticipantUris = {"uri1"};
    QMap<QString, QString> peerUriToConversationUid;
    peerUriToConversationUid.insert("uri1", "convB");

    auto result = CallModel::computeFallbackConversation(currentIsCoreDialog,
                                                         currentConversationUid,
                                                         remoteParticipantUris,
                                                         peerUriToConversationUid);
    EXPECT_FALSE(result.has_value()) << "Fallback logic should only apply to 1:1 (core dialog) conversations";
}

/**
 * If there are no remaining participants in the conference, there is no conversation to switch to.
 * So we remain in the current conversation.
 */
TEST(ConversationSwitch, NoSwitchWhenNoParticipantsRemain)
{
    const bool currentIsCoreDialog = true;
    const QString currentConversationUid = "convA";
    const QStringList remoteParticipantUris;
    QMap<QString, QString> peerUriToConversationUid;

    auto result = CallModel::computeFallbackConversation(currentIsCoreDialog,
                                                         currentConversationUid,
                                                         remoteParticipantUris,
                                                         peerUriToConversationUid);
    EXPECT_FALSE(result.has_value()) << "No fallback possible when no participants remain";
}

/**
 * If the current conversation UID is empty, we default to any available conversation.
 * Which one is chosen does not matter, as we were not in a valid conversation to begin with.
 * The selection is implementation defined.
 */
TEST(ConversationSwitch, SwitchWhenCurrentConversationUidIsEmpty)
{
    const bool currentIsCoreDialog = true;
    const QString currentConversationUid; // Empty UID
    const QStringList remoteParticipantUris = {"uri1", "uri2"};
    QMap<QString, QString> peerUriToConversationUid;
    peerUriToConversationUid.insert("uri1", "convB");
    peerUriToConversationUid.insert("uri2", "convC");

    auto result = CallModel::computeFallbackConversation(currentIsCoreDialog,
                                                         currentConversationUid,
                                                         remoteParticipantUris,
                                                         peerUriToConversationUid);
    ASSERT_TRUE(result.has_value()) << "Should fallback to valid conversation even if current UID is empty";
    EXPECT_TRUE(result.value() == "convB" || result.value() == "convC")
        << "Fallback should select one of the valid candidate conversations";
}

/**
 * If any remaining participant maps to the current conversation,
 * then no switch should be performed, as we are already in the correct conversation.
 */
TEST(ConversationSwitch, NoSwitchWhenAnyParticipantMapsToCurrentConversation)
{
    const bool currentIsCoreDialog = true;
    const QString currentConversationUid = "convA";
    const QStringList remoteParticipantUris = {"uri1", "uri2", "uri3", "uri4", "uri5"};
    // First three are potential candidates, but fourth matches current conversation
    QMap<QString, QString> peerUriToConversationUid;
    peerUriToConversationUid.insert("uri1", "convB");
    peerUriToConversationUid.insert("uri2", "convC");
    peerUriToConversationUid.insert("uri3", "convD");
    peerUriToConversationUid.insert("uri4", "convA");

    auto result = CallModel::computeFallbackConversation(currentIsCoreDialog,
                                                         currentConversationUid,
                                                         remoteParticipantUris,
                                                         peerUriToConversationUid);
    EXPECT_FALSE(result.has_value()) << "If any remaining participant maps to current conversation, no switch needed";
}

/**
 * The selected fallback conversation should be one of the candidate conversations.
 */
TEST(ConversationSwitch, SelectedFallbackConversationIsFromCandidates)
{
    const bool currentIsCoreDialog = true;
    const QString currentConversationUid = "convA";
    const QStringList remoteParticipantUris = {"uri1", "uri2", "uri3"};
    // First two are potential candidates
    QMap<QString, QString> peerUriToConversationUid;
    peerUriToConversationUid.insert("uri1", "convB");
    peerUriToConversationUid.insert("uri2", "convC");
    peerUriToConversationUid.insert("uri3", ""); // No conversation for uri3

    auto result = CallModel::computeFallbackConversation(currentIsCoreDialog,
                                                         currentConversationUid,
                                                         remoteParticipantUris,
                                                         peerUriToConversationUid);
    ASSERT_TRUE(result.has_value()) << "A valid fallback conversation should be found";
    EXPECT_TRUE(result.value() == "convB" || result.value() == "convC")
        << "The selected conversation be one of the candidate conversations";
}

/**
 * If none of the remaining participants map to a valid conversation,
 * then no switch should be performed.
 */
TEST(ConversationSwitch, DoNotSwitchToEmptyConversationUids)
{
    const bool currentIsCoreDialog = true;
    const QString currentConversationUid = "convA";
    const QStringList remoteParticipantUris = {"uri1", "uri2", "uri3"};
    // No participants have a valid conversation
    QMap<QString, QString> peerUriToConversationUid;
    peerUriToConversationUid.insert("uri1", "");
    peerUriToConversationUid.insert("uri2", "");
    peerUriToConversationUid.insert("uri3", "");

    auto result = CallModel::computeFallbackConversation(currentIsCoreDialog,
                                                         currentConversationUid,
                                                         remoteParticipantUris,
                                                         peerUriToConversationUid);
    ASSERT_FALSE(result.has_value()) << "No valid fallback conversation should be found";
}