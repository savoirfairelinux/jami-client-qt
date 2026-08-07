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

#include "api/interaction.h"

#include <gtest/gtest.h>

using namespace lrc::api::interaction;

// A peer may commit a type this version of the client has never heard of, such
// as the collaborative document one. It must not reach the message list, which
// has no delegate for it.
TEST(InteractionType, AMessageTypeWeDoNotKnowIsNotDisplayed)
{
    EXPECT_EQ(to_type("application/collab-doc+json"), Type::INVALID);
    EXPECT_FALSE(isTypeDisplayable(Type::INVALID));
}

TEST(InteractionType, TheTypesTheMessageListDrawsAreDisplayed)
{
    for (const auto type : {Type::TEXT, Type::CALL, Type::CONTACT, Type::INITIAL, Type::DATA_TRANSFER}) {
        EXPECT_TRUE(isTypeDisplayable(type)) << to_string(type).toStdString();
    }
}

TEST(InteractionType, TheTypesTheMessageListCannotDrawAreNotDisplayed)
{
    for (const auto type : {Type::MERGE, Type::VOTE, Type::UPDATE_PROFILE, Type::COUNT__}) {
        EXPECT_FALSE(isTypeDisplayable(type)) << to_string(type).toStdString();
    }
}
