/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 */

#include "messagesadapter.h"

#include <gtest/gtest.h>

using namespace lrc::api;

namespace {

interaction::Info
textMessage()
{
    return interaction::Info("author", "body", 1, 0, interaction::Type::TEXT, interaction::Status::SUCCESS, true);
}

} // namespace

TEST(MessagesAdapterTest, DisplayIndexMatchesReversedFilteredSource)
{
    MessageListModel source(nullptr);
    FilteredMsgListModel proxy;
    proxy.setSourceModel(&source);

    source.append("oldest", textMessage());
    source.append("hidden", interaction::Info("author",
                                               "body",
                                               2,
                                               0,
                                               interaction::Type::REACTION,
                                               interaction::Status::SUCCESS,
                                               true));
    source.append("newest", textMessage());

    EXPECT_EQ(proxy.getDisplayIndex("newest"), 0);
    EXPECT_EQ(proxy.getDisplayIndex("oldest"), 1);
    EXPECT_EQ(proxy.getDisplayIndex("hidden"), -1);
}
