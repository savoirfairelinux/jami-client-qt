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

#include <QOperatingSystemVersion>

#include <gtest/gtest.h>

class UtilsFixture : public ::testing::Test
{};

/*!
 * WHEN  Qt WebEngine support is queried for Windows 8.
 * THEN  It should be disabled before Qt WebEngine can initialize Chromium.
 */
TEST_F(UtilsFixture, WebEngineIsDisabledBeforeWindowsTen)
{
#if WITH_WEBENGINE
    const QOperatingSystemVersion windows8(QOperatingSystemVersion::Windows, 6, 2);
    EXPECT_FALSE(Utils::isWebEngineSupported(windows8));
#else
    GTEST_SKIP() << "Qt WebEngine is not built";
#endif
}

/*!
 * WHEN  Qt WebEngine support is queried for Windows 10.
 * THEN  It should remain enabled on a supported Chromium platform.
 */
TEST_F(UtilsFixture, WebEngineStaysEnabledOnWindowsTen)
{
#if WITH_WEBENGINE
    const QOperatingSystemVersion windows10(QOperatingSystemVersion::Windows, 10);
    EXPECT_TRUE(Utils::isWebEngineSupported(windows10));
#else
    GTEST_SKIP() << "Qt WebEngine is not built";
#endif
}
