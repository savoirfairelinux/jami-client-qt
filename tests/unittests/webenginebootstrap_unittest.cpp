/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "webenginebootstrap.h"

#include <gtest/gtest.h>

TEST(WebEngineBootstrap, RejectsWindowsVersionsBeforeTen)
{
    EXPECT_FALSE(WebEngineBootstrap::isWindowsVersionSupported(6));
    EXPECT_FALSE(WebEngineBootstrap::isWindowsVersionSupported(9));
}

TEST(WebEngineBootstrap, AcceptsWindowsTenAndLater)
{
    EXPECT_TRUE(WebEngineBootstrap::isWindowsVersionSupported(10));
    EXPECT_TRUE(WebEngineBootstrap::isWindowsVersionSupported(11));
}

TEST(WebEngineBootstrap, PreservesUserChromiumFlags)
{
    EXPECT_EQ(WebEngineBootstrap::chromiumFlagsWithRequiredOptions("--foo=bar"),
              QByteArray("--foo=bar --disable-web-security --disable-gpu"));
}

TEST(WebEngineBootstrap, DoesNotDuplicateRequiredChromiumFlags)
{
    EXPECT_EQ(WebEngineBootstrap::chromiumFlagsWithRequiredOptions("--disable-gpu"),
              QByteArray("--disable-gpu --disable-web-security"));
}
