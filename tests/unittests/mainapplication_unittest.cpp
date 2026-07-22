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

#include "mainapplication.h"

#include <gtest/gtest.h>

TEST(MainApplication, AcceptsQtPatchRuntimeDifference)
{
    EXPECT_TRUE(isCompatibleQtRuntimeVersion("6.8.2", "6.8.3"));
    EXPECT_TRUE(isCompatibleQtRuntimeVersion("6.8.4", "6.8.3"));
}

TEST(MainApplication, RejectsQtMajorMinorRuntimeDifference)
{
    EXPECT_FALSE(isCompatibleQtRuntimeVersion("6.7.3", "6.8.3"));
    EXPECT_FALSE(isCompatibleQtRuntimeVersion("5.15.2", "6.8.3"));
}
