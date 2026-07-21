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

#include "app/mainapplication.h"

#include <gtest/gtest.h>

TEST(MainApplication, AcceptsQtPatchRuntimeSkew)
{
    const auto patchSkewVersion = QStringLiteral("%1.%2.%3")
                                      .arg(QT_VERSION_MAJOR)
                                      .arg(QT_VERSION_MINOR)
                                      .arg(QT_VERSION_PATCH + 1);

    EXPECT_TRUE(MainApplication::isQtRuntimeVersionCompatible(patchSkewVersion));
}

TEST(MainApplication, RejectsQtMajorRuntimeSkew)
{
    const auto majorSkewVersion = QStringLiteral("%1.%2.%3")
                                      .arg(QT_VERSION_MAJOR + 1)
                                      .arg(QT_VERSION_MINOR)
                                      .arg(QT_VERSION_PATCH);

    EXPECT_FALSE(MainApplication::isQtRuntimeVersionCompatible(majorSkewVersion));
}

TEST(MainApplication, RejectsQtMinorRuntimeSkew)
{
    const auto minorSkewVersion = QStringLiteral("%1.%2.%3")
                                      .arg(QT_VERSION_MAJOR)
                                      .arg(QT_VERSION_MINOR + 1)
                                      .arg(QT_VERSION_PATCH);

    EXPECT_FALSE(MainApplication::isQtRuntimeVersionCompatible(minorSkewVersion));
}
