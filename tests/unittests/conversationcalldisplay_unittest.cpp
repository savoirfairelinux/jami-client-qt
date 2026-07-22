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

#include "app/conversationsadapterutils.h"

#include <gtest/gtest.h>

using lrc::api::call::Info;
using lrc::api::call::Status;

TEST(ConversationCallDisplay, MissingCallDoesNotShowStack)
{
    const auto result = ConversationsAdapterUtils::getCallDisplayInfo(nullptr);

    EXPECT_FALSE(result.callStackViewShouldShow);
    EXPECT_EQ(result.callState, Status::INVALID);
}

TEST(ConversationCallDisplay, IncomingActiveCallShowsStack)
{
    Info call;
    call.isOutgoing = false;
    call.status = Status::IN_PROGRESS;

    const auto result = ConversationsAdapterUtils::getCallDisplayInfo(&call);

    EXPECT_TRUE(result.callStackViewShouldShow);
    EXPECT_EQ(result.callState, Status::IN_PROGRESS);
}

TEST(ConversationCallDisplay, EndedOutgoingCallDoesNotShowStack)
{
    Info call;
    call.isOutgoing = true;
    call.status = Status::ENDED;

    const auto result = ConversationsAdapterUtils::getCallDisplayInfo(&call);

    EXPECT_FALSE(result.callStackViewShouldShow);
    EXPECT_EQ(result.callState, Status::ENDED);
}
