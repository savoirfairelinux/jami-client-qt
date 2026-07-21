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

#include "webengineavailability.h"

#include <gtest/gtest.h>

TEST(WebEngineAvailabilityTest, DisablesUnsupportedWindowsRuntime)
{
#if defined(WITH_WEBENGINE) && WITH_WEBENGINE
    EXPECT_FALSE(WebEngineAvailability::isSupportedOn(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 6, 2)));
    EXPECT_FALSE(WebEngineAvailability::isSupportedOn(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 6, 3)));
    EXPECT_TRUE(WebEngineAvailability::isSupportedOn(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 10)));
#else
    EXPECT_FALSE(WebEngineAvailability::isSupportedOn(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 10)));
#endif
}
