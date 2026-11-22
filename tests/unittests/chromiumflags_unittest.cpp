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

#include "utils.h"

#include <gtest/gtest.h>

static bool
hasFlag(const QByteArray& flags, const QByteArray& flag)
{
    return flags.split(' ').contains(flag);
}

TEST(ChromiumFlags, UserProvidedFlagsArePreserved)
{
    const auto flags = Utils::webEngineChromiumFlags("--user-flag");
    EXPECT_TRUE(flags.startsWith("--user-flag ")) << flags.toStdString();
    EXPECT_TRUE(hasFlag(flags, "--disable-web-security")) << flags.toStdString();
}

TEST(ChromiumFlags, NoLeadingSeparatorWithoutUserFlags)
{
    const auto flags = Utils::webEngineChromiumFlags({});
    EXPECT_FALSE(flags.startsWith(' ')) << flags.toStdString();
    EXPECT_TRUE(hasFlag(flags, "--disable-web-security")) << flags.toStdString();
}

// --disable-gpu works around a Linux-only (GBM/Vulkan fallback) Chromium
// crash. On Windows it makes Chromium hit a fatal CHECK while the first
// WebEngineView initializes the WebEngine context (BREAKPOINT_80000003 in
// Qt6WebEngineCore), so it must not be forced there.
TEST(ChromiumFlags, GpuIsOnlyDisabledWhereRequired)
{
    const auto flags = Utils::webEngineChromiumFlags({});
#if defined(Q_OS_WIN)
    EXPECT_FALSE(hasFlag(flags, "--disable-gpu")) << flags.toStdString();
#else
    EXPECT_TRUE(hasFlag(flags, "--disable-gpu")) << flags.toStdString();
#endif
}

TEST(ChromiumFlags, SingleProcessIsOnlyUsedOnMacOS)
{
    const auto flags = Utils::webEngineChromiumFlags({});
#if defined(Q_OS_MACOS)
    EXPECT_TRUE(hasFlag(flags, "--single-process")) << flags.toStdString();
#else
    EXPECT_FALSE(hasFlag(flags, "--single-process")) << flags.toStdString();
#endif
}
