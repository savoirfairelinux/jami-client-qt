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

#include <QFile>

TEST(CrashReportClient, UploadCleanupDoesNotCaptureClientInstance)
{
    QFile file(QStringLiteral(JAMI_TEST_SOURCE_DIR)
               + QStringLiteral("/src/app/crashreportclients/crashpad.cpp"));
    ASSERT_TRUE(file.open(QIODevice::ReadOnly | QIODevice::Text))
        << file.errorString().toStdString();

    const auto source = QString::fromUtf8(file.readAll());
    EXPECT_FALSE(source.contains(QStringLiteral("start([this")));
    EXPECT_TRUE(source.contains(QStringLiteral("start([dbPath = dbPath_")));
}
