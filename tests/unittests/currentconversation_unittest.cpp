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
