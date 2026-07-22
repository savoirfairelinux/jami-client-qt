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

#include "globaltestenvironment.h"
#include "utils.h"

TEST(WebEngineSupport, RejectsWindowsBeforeTen)
{
    EXPECT_FALSE(Utils::isWebEngineSupported(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 6, 2)));
    EXPECT_FALSE(Utils::isWebEngineSupported(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 6, 3)));
}

TEST(WebEngineSupport, AllowsWindowsTenOrLater)
{
    EXPECT_TRUE(Utils::isWebEngineSupported(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 10, 0)));
    EXPECT_TRUE(Utils::isWebEngineSupported(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 11, 0)));
}

TEST(WebEngineSupport, AllowsNonWindowsPlatforms)
{
    EXPECT_TRUE(Utils::isWebEngineSupported(
        QOperatingSystemVersion(QOperatingSystemVersion::MacOS, 10, 15)));
    EXPECT_TRUE(Utils::isWebEngineSupported(
        QOperatingSystemVersion(QOperatingSystemVersion::Android, 13, 0)));
}
