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

#include "globaltestenvironment.h"

/*!
 * Test fixture for AccountAdapter testing
 */
class AccountFixture : public ::testing::Test
{
public:
    // Prepare unit test context. Called at
    // prior each unit test execution
    void SetUp() override {}

    // Close unit test context. Called
    // after each unit test ending
    void TearDown() override {}
};

/*!
 * WHEN  There is no account initially.
 * THEN  Account list should be empty.
 */
TEST_F(AccountFixture, InitialAccountListCheck)
{
    auto accountListSize = globalEnv.lrcInstance->accountModel().getAccountCount();

    ASSERT_EQ(accountListSize, 0);
}

/*!
 * WHEN  The current account id is empty or stale.
 * THEN  Updating the current account display name should be ignored.
 */
TEST_F(AccountFixture, SetCurrentDisplayNameWithoutCurrentAccountDoesNotThrow)
{
    ASSERT_EQ(globalEnv.lrcInstance->accountModel().getAccountCount(), 0);

    globalEnv.lrcInstance->set_currentAccountId("");
    EXPECT_NO_THROW(globalEnv.lrcInstance->setCurrAccDisplayName("Alice"));

    globalEnv.lrcInstance->set_currentAccountId("stale-account-id");
    EXPECT_NO_THROW(globalEnv.lrcInstance->setCurrAccDisplayName("Alice"));
}

/*!
 * WHEN  An SIP account is created.
 * THEN  The size of the account list should be one.
 */
TEST_F(AccountFixture, CreateSIPAccountTest)
{
    // AccountAdded signal spy
    QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountAdded);

    // Create SIP Acc
    globalEnv.accountAdapter->createSIPAccount(QVariantMap());

    accountAddedSpy.wait();
    EXPECT_EQ(accountAddedSpy.count(), 1);

    QList<QVariant> accountAddedArguments = accountAddedSpy.takeFirst();
    EXPECT_TRUE(accountAddedArguments.at(0).typeId() == qMetaTypeId<QString>());

    // Select the created account
    globalEnv.lrcInstance->set_currentAccountId(accountAddedArguments.at(0).toString());

    auto accountListSize = globalEnv.lrcInstance->accountModel().getAccountCount();
    ASSERT_EQ(accountListSize, 1);

    // Make sure the account setup is done
    QSignalSpy accountStatusChangedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountStatusChanged);

    accountStatusChangedSpy.wait();
    EXPECT_GE(accountStatusChangedSpy.count(), 1);

    // Remove the account
    QSignalSpy accountRemovedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountRemoved);

    globalEnv.lrcInstance->accountModel().removeAccount(globalEnv.lrcInstance->get_currentAccountId());

    accountRemovedSpy.wait();
    EXPECT_EQ(accountRemovedSpy.count(), 1);

    accountListSize = globalEnv.lrcInstance->accountModel().getAccountCount();
    ASSERT_EQ(accountListSize, 0);
}
/*!
 * WHEN  A bot account is created from an existing account.
 * THEN  The current account should stay on the creator account.
 */
TEST_F(AccountFixture, CreateBotAccountKeepsCreatorAsCurrentAccount)
{
    QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountAdded);

    globalEnv.accountAdapter->createSIPAccount(QVariantMap());

    ASSERT_TRUE(accountAddedSpy.wait());
    ASSERT_EQ(accountAddedSpy.count(), 1);

    const auto creatorAccountId = accountAddedSpy.takeFirst().at(0).toString();
    globalEnv.lrcInstance->set_currentAccountId(creatorAccountId);

    QSignalSpy accountAdapterAddedSpy(globalEnv.accountAdapter.get(), &AccountAdapter::accountAdded);

    QVariantMap botSettings;
    botSettings["alias"] = "Bot account";
    botSettings["registeredName"] = "";
    botSettings["password"] = "";
    botSettings["archivePath"] = "";
    botSettings["avatar"] = "";
    botSettings["botOwner"] = "jami:" + creatorAccountId;

    globalEnv.accountAdapter->createJamiAccount(botSettings);

    ASSERT_TRUE(accountAdapterAddedSpy.wait());
    ASSERT_EQ(accountAdapterAddedSpy.count(), 1);

    const auto botAccountId = accountAdapterAddedSpy.takeFirst().at(0).toString();
    EXPECT_NE(botAccountId, creatorAccountId);
    EXPECT_EQ(globalEnv.lrcInstance->get_currentAccountId(), creatorAccountId);

    globalEnv.lrcInstance->accountModel().removeAccount(botAccountId);
    globalEnv.lrcInstance->accountModel().removeAccount(creatorAccountId);

    QTRY_COMPARE(globalEnv.lrcInstance->accountModel().getAccountCount(), 0);
}

/*!
 * WHEN  Current account is deleted through AccountAdapter.
 * THEN  All API tokens for that account are revoked.
 */
TEST_F(AccountFixture, DeleteCurrentAccountRevokesAllApiTokens)
{
    QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountAdded);

    globalEnv.accountAdapter->createSIPAccount(QVariantMap());

    accountAddedSpy.wait();
    ASSERT_EQ(accountAddedSpy.count(), 1);

    const auto accountId = accountAddedSpy.takeFirst().at(0).toString();
    globalEnv.lrcInstance->set_currentAccountId(accountId);

    auto firstToken = globalEnv.apiTokenManager->createToken(accountId, "token-a");
    auto secondToken = globalEnv.apiTokenManager->createToken(accountId, "token-b");

    ASSERT_EQ(globalEnv.apiTokenManager->listTokens(accountId).size(), 2);
    ASSERT_NE(globalEnv.apiTokenManager->validateToken(firstToken.rawToken), nullptr);
    ASSERT_NE(globalEnv.apiTokenManager->validateToken(secondToken.rawToken), nullptr);

    QSignalSpy accountRemovedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountRemoved);

    globalEnv.accountAdapter->deleteCurrentAccount();

    accountRemovedSpy.wait();
    ASSERT_EQ(accountRemovedSpy.count(), 1);

    EXPECT_EQ(globalEnv.apiTokenManager->listTokens(accountId).size(), 0);
    EXPECT_EQ(globalEnv.apiTokenManager->validateToken(firstToken.rawToken), nullptr);
    EXPECT_EQ(globalEnv.apiTokenManager->validateToken(secondToken.rawToken), nullptr);
}
