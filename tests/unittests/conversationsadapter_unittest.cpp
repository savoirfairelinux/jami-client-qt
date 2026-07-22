#include "app/conversationsadapter.h"

#include <gtest/gtest.h>

TEST(ConversationsAdapter, MissingCallKeepsDefaultCallUiState)
{
    const auto state = ConversationsAdapter::callUiStateForCall(nullptr);

    EXPECT_FALSE(state.callStackViewShouldShow);
    EXPECT_EQ(state.callState, lrc::api::call::Status::INVALID);
}
