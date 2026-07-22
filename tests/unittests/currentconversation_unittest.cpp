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

#include "currentconversation.h"
#include "globaltestenvironment.h"
#include "gtest/gtest.h"

TEST(CurrentConversation, UpdateErrorsHandlesMissingCurrentConversationModel)
{
    const QString convId = "stale-conversation";
    CurrentConversation currentConversation(globalEnv.lrcInstance.data());

    currentConversation.set_id(convId);
    currentConversation.set_errors({"previous error"});
    currentConversation.set_backendErrors({"previous backend error"});
    globalEnv.lrcInstance->set_currentAccountId();

    ASSERT_TRUE(QMetaObject::invokeMethod(&currentConversation,
                                          "updateErrors",
                                          Qt::DirectConnection,
                                          Q_ARG(QString, convId)));
    EXPECT_TRUE(currentConversation.get_errors().isEmpty());
    EXPECT_TRUE(currentConversation.get_backendErrors().isEmpty());
}
