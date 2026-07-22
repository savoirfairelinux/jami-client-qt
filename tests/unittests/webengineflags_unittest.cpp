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

#include "webengineflags.h"

#include <gtest/gtest.h>

TEST(WebEngineFlags, PreservesExistingChromiumFlags)
{
    const auto flags = jami::webengine::buildChromiumFlags("--remote-debugging-port=0", false);

    EXPECT_TRUE(jami::webengine::hasChromiumFlag(flags, "--remote-debugging-port=0"));
    EXPECT_TRUE(jami::webengine::hasChromiumFlag(flags, jami::webengine::kDisableWebSecurity));
    EXPECT_TRUE(jami::webengine::hasChromiumFlag(flags, jami::webengine::kDisableGpu));
}

TEST(WebEngineFlags, AddsWindowsHandleVerifierMitigation)
{
    const auto flags = jami::webengine::buildChromiumFlags({}, true);

    EXPECT_TRUE(jami::webengine::hasChromiumFlag(flags, jami::webengine::kDisableHandleVerifier));
}

TEST(WebEngineFlags, DoesNotDuplicateExistingFlags)
{
    const auto flags = jami::webengine::buildChromiumFlags(
        "--disable-web-security --disable-gpu --disable-handle-verifier",
        true);

    EXPECT_EQ(flags.split(' ').count("--disable-web-security"), 1);
    EXPECT_EQ(flags.split(' ').count("--disable-gpu"), 1);
    EXPECT_EQ(flags.split(' ').count("--disable-handle-verifier"), 1);
}
