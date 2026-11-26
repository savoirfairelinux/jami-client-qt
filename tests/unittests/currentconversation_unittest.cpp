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
#include "currentconversationmembers.h"

#include "api/swarmpermissions.h"

#include "dbus/configurationmanager.h"

#include <QScopeGuard>
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

TEST(CurrentConversationMembers, ListsPendingFeedInviteesAsInvited)
{
    CurrentConversationMembers members(globalEnv.lrcInstance.data());
    members.setMembers("account-id", "feed-id", {}, {"pending-uri"});

    ASSERT_EQ(members.rowCount(), 1);
    const auto index = members.index(0);
    EXPECT_EQ(members.data(index, Members::Role::MemberUri).toString(), "pending-uri");
    EXPECT_EQ(members.data(index, Members::Role::MemberRole).value<lrc::api::member::Role>(),
              lrc::api::member::Role::INVITED);
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
        conversationModel->isActionPermitted("missing-conversation-id", lrc::api::permissions::Permission::Text));
    EXPECT_FALSE(conversationModel->isActionPermitted("missing-conversation-id",
                                                      lrc::api::permissions::Permission::CreateDocument));
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
        const auto canEdit = currentConversation.property("canEdit");
        ASSERT_TRUE(canEdit.isValid());
        EXPECT_FALSE(canEdit.toBool());
        const auto canDelete = currentConversation.property("canDelete");
        ASSERT_TRUE(canDelete.isValid());
        EXPECT_FALSE(canDelete.toBool());
        EXPECT_FALSE(currentConversation.property("canCall").toBool());
        EXPECT_FALSE(currentConversation.property("canAddMember").toBool());
        EXPECT_FALSE(currentConversation.property("canChangeConversationProfile").toBool());
        EXPECT_FALSE(currentConversation.property("canBanUnbanMember").toBool());
    }

    QSignalSpy accountRemovedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountRemoved);
    globalEnv.lrcInstance->accountModel().removeAccount(accountId);
    ASSERT_TRUE(accountRemovedSpy.wait());
}

/*!
 * WHEN  A conversation profile update arrives with only the repository profile.
 * THEN  Infos tracked locally by the daemon, such as the creation date, are kept.
 */
TEST(ConversationModel, ProfileUpdateKeepsLocalConversationInfos)
{
    auto& accountModel = globalEnv.lrcInstance->accountModel();
    QSignalSpy accountAddedSpy(&accountModel, &AccountModel::accountAdded);
    const auto accountId = accountModel.createNewAccount(lrc::api::profile::Type::JAMI, {{"alias", "Feed publisher"}});
    const auto cleanup = qScopeGuard([&] {
        accountModel.removeAccount(accountId);
        EXPECT_TRUE(QTest::qWaitFor([&] { return !accountModel.hasAccount(accountId); }));
    });
    ASSERT_TRUE(accountAddedSpy.count() > 0 || accountAddedSpy.wait(15000));

    auto& conversationModel = *accountModel.getAccountInfo(accountId).conversationModel;
    const auto convId = conversationModel.createFeedConversation({});
    ASSERT_FALSE(convId.isEmpty());
    ASSERT_TRUE(QTest::qWaitFor([&] { return conversationModel.getConversationForUid(convId).has_value(); }));

    QSignalSpy profileUpdatedSpy(&conversationModel, &ConversationModel::profileUpdated);
    conversationModel.updateConversationInfos(convId, {{"title", "Renamed"}});
    ASSERT_TRUE(profileUpdatedSpy.wait(15000));

    const auto& infos = conversationModel.getConversationForUid(convId)->get().infos;
    EXPECT_EQ(infos.value("title"), "Renamed");
    EXPECT_TRUE(infos.contains("createdMs"));
}

/*!
 * WHEN  The publisher switches a feed between all contacts and selected contacts.
 * THEN  The conversation infos reflect the new audience.
 */
TEST(ConversationModel, SwitchesFeedAudience)
{
    auto& accountModel = globalEnv.lrcInstance->accountModel();
    QSignalSpy accountAddedSpy(&accountModel, &AccountModel::accountAdded);
    const auto accountId = accountModel.createNewAccount(lrc::api::profile::Type::JAMI, {{"alias", "Feed publisher"}});
    const auto cleanup = qScopeGuard([&] {
        accountModel.removeAccount(accountId);
        EXPECT_TRUE(QTest::qWaitFor([&] { return !accountModel.hasAccount(accountId); }));
    });
    ASSERT_TRUE(accountAddedSpy.count() > 0 || accountAddedSpy.wait(15000));

    auto& conversationModel = *accountModel.getAccountInfo(accountId).conversationModel;
    const auto convId = conversationModel.createFeedConversation({});
    ASSERT_FALSE(convId.isEmpty());
    ASSERT_TRUE(QTest::qWaitFor([&] { return conversationModel.getConversationForUid(convId).has_value(); }));
    const auto infos = [&] {
        return conversationModel.getConversationForUid(convId)->get().infos;
    };
    EXPECT_EQ(infos().value("inviteAllContacts"), "false");

    QSignalSpy conversationUpdatedSpy(&conversationModel, &ConversationModel::conversationUpdated);
    EXPECT_TRUE(conversationModel.setFeedInviteAllContacts(convId, true));
    EXPECT_EQ(infos().value("inviteAllContacts"), "true");
    EXPECT_EQ(conversationUpdatedSpy.count(), 1);

    EXPECT_TRUE(conversationModel.setFeedInviteAllContacts(convId, false));
    EXPECT_EQ(infos().value("inviteAllContacts"), "false");
}
