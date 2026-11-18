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

#include "reentrancyguard.h"

#include <gtest/gtest.h>

#include <functional>

TEST(ReentrancyGuardTest, ScopeTracksDepth)
{
    ReentrancyGuard guard(2);
    EXPECT_EQ(guard.depth(), 0);
    {
        ReentrancyGuard::Scope outer(guard);
        EXPECT_TRUE(outer.entered());
        EXPECT_EQ(guard.depth(), 1);
        {
            ReentrancyGuard::Scope inner(guard);
            EXPECT_TRUE(inner.entered());
            EXPECT_EQ(guard.depth(), 2);
        }
        EXPECT_EQ(guard.depth(), 1);
    }
    EXPECT_EQ(guard.depth(), 0);
}

TEST(ReentrancyGuardTest, RejectsScopeBeyondMaxDepth)
{
    ReentrancyGuard guard(1);
    ReentrancyGuard::Scope first(guard);
    ASSERT_TRUE(first.entered());
    {
        ReentrancyGuard::Scope rejected(guard);
        EXPECT_FALSE(rejected.entered());
        EXPECT_EQ(guard.depth(), 1);
    }
    // A rejected scope must not decrement the depth on exit.
    EXPECT_EQ(guard.depth(), 1);
}

// Simulates an unbounded re-entrant callback chain (e.g. a window message
// handler that ends up sending the same message to itself) and checks that
// the guard bounds the recursion and fully unwinds afterwards.
TEST(ReentrancyGuardTest, BoundsUnboundedRecursion)
{
    constexpr int maxDepth = 8;
    ReentrancyGuard guard(maxDepth);
    int calls = 0;
    int rejected = 0;

    std::function<void()> handler = [&] {
        ++calls;
        ReentrancyGuard::Scope scope(guard);
        if (!scope.entered()) {
            ++rejected;
            return;
        }
        handler();
    };
    handler();

    EXPECT_EQ(calls, maxDepth + 1);
    EXPECT_EQ(rejected, 1);
    EXPECT_EQ(guard.depth(), 0);
}
