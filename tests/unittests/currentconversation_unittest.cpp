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

#include "globaltestenvironment.h"

#include "currentconversation.h"
#include "utils.h"

#include <QSignalSpy>

#include <gtest/gtest.h>

TEST(CurrentConversation, DeselectsConversationBeforeAccountRemoval)
{
    QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountAdded);
    globalEnv.accountAdapter->createSIPAccount(QVariantMap());
    ASSERT_TRUE(accountAddedSpy.wait());

    const auto accountId = accountAddedSpy.takeFirst().at(0).toString();
    globalEnv.lrcInstance->set_currentAccountId(accountId);
    globalEnv.lrcInstance->set_selectedConvUid("conversation-id");

    QSignalSpy accountRemovedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountRemoved);
    globalEnv.lrcInstance->accountModel().removeAccount(accountId);
    ASSERT_TRUE(accountRemovedSpy.wait());
    EXPECT_TRUE(globalEnv.lrcInstance->get_selectedConvUid().isEmpty());
}

/**
 * A conversation that cannot be found used to leave CurrentConversation with the properties of the
 * previously selected one. The view then offered actions for a conversation the model knows nothing
 * about: the banner proposing to migrate it to a swarm was shown, and its buttons had no peer to
 * act on. Selecting an unknown conversation must therefore clear every conversation-scoped
 * property.
 */
TEST(CurrentConversation, ClearsPropertiesOfAnUnknownConversation)
{
    QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountAdded);
    globalEnv.accountAdapter->createSIPAccount(QVariantMap());
    ASSERT_TRUE(accountAddedSpy.wait());

    const auto accountId = accountAddedSpy.takeFirst().at(0).toString();
    globalEnv.lrcInstance->set_currentAccountId(accountId);

    CurrentConversation currentConversation(globalEnv.lrcInstance.data());

    // Stand in for the state a selected and loaded conversation leaves behind.
    currentConversation.set_title("Title");
    currentConversation.set_description("Description");
    currentConversation.set_botOwner("bot-owner-uri");
    currentConversation.set_isSwarm(true);
    currentConversation.set_isLegacy(true);
    currentConversation.set_isCoreDialog(true);
    currentConversation.set_isRequest(true);
    currentConversation.set_needsSyncing(true);
    currentConversation.set_isSip(true);
    currentConversation.set_isBanned(true);
    currentConversation.set_ignoreNotifications(true);
    currentConversation.set_callId("call-id");
    currentConversation.set_color("#123456");
    currentConversation.set_rdvAccount("rendezvous-account-uri");
    currentConversation.set_rdvDevice("rendezvous-device-id");
    currentConversation.set_callState(call::Status::CONNECTED);
    currentConversation.set_hasCall(true);
    currentConversation.set_inCall(true);
    currentConversation.set_isTemporary(true);
    currentConversation.set_isContact(true);
    currentConversation.set_allMessagesLoaded(true);
    currentConversation.set_modeString("Private");
    currentConversation.set_activeCalls(QVariantList {QVariant("call-id")});
    currentConversation.set_errors(QStringList {"error"});
    currentConversation.set_backendErrors(QStringList {"backend error"});
    currentConversation.set_lastSelfMessageId("message-id");

    const QString unknownConvUid("unknown-conversation-uid");
    globalEnv.lrcInstance->set_selectedConvUid(unknownConvUid);

    EXPECT_EQ(currentConversation.get_id(), unknownConvUid);
    EXPECT_TRUE(currentConversation.get_title().isEmpty());
    EXPECT_TRUE(currentConversation.get_description().isEmpty());
    EXPECT_TRUE(currentConversation.get_botOwner().isEmpty());
    EXPECT_FALSE(currentConversation.get_isSwarm());
    // The migration banner is keyed on this property.
    EXPECT_FALSE(currentConversation.get_isLegacy());
    EXPECT_FALSE(currentConversation.get_isCoreDialog());
    EXPECT_FALSE(currentConversation.get_isRequest());
    EXPECT_FALSE(currentConversation.get_needsSyncing());
    EXPECT_FALSE(currentConversation.get_isSip());
    EXPECT_FALSE(currentConversation.get_isBanned());
    EXPECT_FALSE(currentConversation.get_ignoreNotifications());
    EXPECT_TRUE(currentConversation.get_callId().isEmpty());
    EXPECT_EQ(currentConversation.get_color(), Utils::getAvatarColor(unknownConvUid).name());
    EXPECT_TRUE(currentConversation.get_rdvAccount().isEmpty());
    EXPECT_TRUE(currentConversation.get_rdvDevice().isEmpty());
    EXPECT_EQ(currentConversation.get_callState(), call::Status::INVALID);
    EXPECT_FALSE(currentConversation.get_hasCall());
    EXPECT_FALSE(currentConversation.get_inCall());
    EXPECT_FALSE(currentConversation.get_isTemporary());
    EXPECT_FALSE(currentConversation.get_isContact());
    // A stale value here would keep MessageListView from loading any message.
    EXPECT_FALSE(currentConversation.get_allMessagesLoaded());
    EXPECT_TRUE(currentConversation.get_modeString().isEmpty());
    EXPECT_TRUE(currentConversation.get_activeCalls().isEmpty());
    EXPECT_TRUE(currentConversation.get_errors().isEmpty());
    EXPECT_TRUE(currentConversation.get_backendErrors().isEmpty());
    EXPECT_TRUE(currentConversation.get_lastSelfMessageId().isEmpty());
}
