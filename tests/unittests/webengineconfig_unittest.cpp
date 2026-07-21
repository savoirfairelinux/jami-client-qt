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

#include "webengineconfig.h"

#include <QtGlobal>

#include <gtest/gtest.h>

TEST(WebEngineConfig, ChromiumFlagsPreserveUserFlags)
{
    const auto flags = jami::webEngineChromiumFlags("--remote-debugging-port=9222");

    EXPECT_EQ(flags,
              QByteArray("--remote-debugging-port=9222 --disable-web-security --single-process "
                         "--disable-gpu"));
}

TEST(WebEngineConfig, RuntimeCanDisableWebEngineFallback)
{
    const auto envName = "JAMI_DISABLE_WEBENGINE";
    const auto hadPreviousValue = qEnvironmentVariableIsSet(envName);
    const auto previousValue = qgetenv(envName);

    qputenv("JAMI_DISABLE_WEBENGINE", "");
    EXPECT_TRUE(jami::webEngineRuntimeAvailable());

    jami::disableWebEngineRuntime();

    EXPECT_FALSE(jami::webEngineRuntimeAvailable());
    if (hadPreviousValue)
        qputenv(envName, previousValue);
    else
        qunsetenv(envName);
}

TEST(WebEngineConfig, ConfigureDoesNotTouchFlagsWhenRuntimeDisabled)
{
    const auto disableEnvName = "JAMI_DISABLE_WEBENGINE";
    const auto flagsEnvName = "QTWEBENGINE_CHROMIUM_FLAGS";
    const auto hadDisableValue = qEnvironmentVariableIsSet(disableEnvName);
    const auto previousDisableValue = qgetenv(disableEnvName);
    const auto hadFlagsValue = qEnvironmentVariableIsSet(flagsEnvName);
    const auto previousFlagsValue = qgetenv(flagsEnvName);

    qputenv(disableEnvName, "1");
    qputenv(flagsEnvName, "--user-flag");

    jami::configureWebEngineRuntime();

    EXPECT_EQ(qgetenv(flagsEnvName), QByteArray("--user-flag"));

    if (hadDisableValue)
        qputenv(disableEnvName, previousDisableValue);
    else
        qunsetenv(disableEnvName);
    if (hadFlagsValue)
        qputenv(flagsEnvName, previousFlagsValue);
    else
        qunsetenv(flagsEnvName);
}
