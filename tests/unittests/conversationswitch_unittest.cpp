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
    EXPECT_FALSE(result.has_value()) << "Fallback logic should not apply to group conversations";
}

TEST(ConversationSwitch, NoSwitchWhenEmptyRemoteParticipantsList)
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

TEST(ConversationSwitch, NoSwitchWhenCurrentConversationUidIsEmpty)
{
    const bool currentIsCoreDialog = true;
    const QString currentConversationUid; // Empty UID
    const QStringList remoteParticipantUris = {"uri1"};
    QMap<QString, QString> peerUriToConversationUid;
    peerUriToConversationUid.insert("uri1", "convB");

    auto result = CallModel::computeFallbackConversation(currentIsCoreDialog,
                                                         currentConversationUid,
                                                         remoteParticipantUris,
                                                         peerUriToConversationUid);
    EXPECT_FALSE(result.has_value()) << "Current conversation UID is needed for fallback decision";
}

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
        << "Fallback should select one of the valid candidate conversations";
}