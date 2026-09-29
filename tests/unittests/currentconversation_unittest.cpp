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

#include "api/swarmpermissions.h"

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

TEST(CurrentConversation, DeniesPermissionsWhenConversationInfoIsMissing)
{
    QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountAdded);
    globalEnv.accountAdapter->createSIPAccount(QVariantMap());
    ASSERT_TRUE(accountAddedSpy.wait());

    const auto accountId = accountAddedSpy.takeFirst().at(0).toString();
    globalEnv.lrcInstance->set_currentAccountId(accountId);
    globalEnv.lrcInstance->set_selectedConvUid("missing-conversation-id");

    auto* conversationModel = globalEnv.lrcInstance->getCurrentConversationModel();
    ASSERT_NE(conversationModel, nullptr);
    EXPECT_FALSE(
        conversationModel->isActionPermitted("missing-conversation-id", lrc::api::permissions::Action::SendText));
    EXPECT_FALSE(conversationModel->isActionPermitted("missing-conversation-id",
                                                      lrc::api::permissions::Action::CreateCollaborativeDocument));
    EXPECT_FALSE(conversationModel->isProfileUpdatePermitted("missing-conversation-id"));

    {
        CurrentConversation currentConversation(globalEnv.lrcInstance.data());
        const auto canCreateDocument = currentConversation.property("canCreateDocument");
        ASSERT_TRUE(canCreateDocument.isValid());
        EXPECT_FALSE(canCreateDocument.toBool());
        EXPECT_FALSE(currentConversation.property("canSendText").toBool());
        EXPECT_FALSE(currentConversation.property("canSendFile").toBool());
        EXPECT_FALSE(currentConversation.property("canReplyText").toBool());
        EXPECT_FALSE(currentConversation.property("canReplyFile").toBool());
        EXPECT_FALSE(currentConversation.property("canReact").toBool());
        EXPECT_FALSE(currentConversation.property("canCall").toBool());
        EXPECT_FALSE(currentConversation.property("canAddMember").toBool());
        EXPECT_FALSE(currentConversation.property("canChangeConversationProfile").toBool());
        EXPECT_FALSE(currentConversation.property("canBanUnbanMember").toBool());
    }

    QSignalSpy accountRemovedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountRemoved);
    globalEnv.lrcInstance->accountModel().removeAccount(accountId);
    ASSERT_TRUE(accountRemovedSpy.wait());
}
