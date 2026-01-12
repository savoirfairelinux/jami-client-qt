/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

#include <QApplication>
#include <QStandardPaths>

#ifdef Q_OS_WIN
#define DATA_DIR    "JAMI_DATA_HOME"
#define CONFIG_DIR  "JAMI_CONFIG_HOME"
#define CACHE_DIR   "JAMI_CACHE_HOME"
#else
#define DATA_DIR    "XDG_DATA_HOME"
#define CONFIG_DIR  "XDG_CONFIG_HOME"
#define CACHE_DIR   "XDG_CACHE_HOME"
#endif

TestEnvironment globalEnv;

int
main(int argc, char* argv[])
{
    QDir tempDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation));

    auto jamiDataDir = tempDir.absolutePath() + "/jami_test/jami";
    auto jamiConfigDir = tempDir.absolutePath() + "/jami_test/.config";
    auto jamiCacheDir = tempDir.absolutePath() + "/jami_test/.cache";

    // Clean up the temp directories.
    QDir(jamiDataDir).removeRecursively();
    QDir(jamiConfigDir).removeRecursively();
    QDir(jamiCacheDir).removeRecursively();

    bool envSet = qputenv(DATA_DIR, jamiDataDir.toLocal8Bit());
    envSet &= qputenv(CONFIG_DIR, jamiConfigDir.toLocal8Bit());
    envSet &= qputenv(CACHE_DIR, jamiCacheDir.toLocal8Bit());
    if (!envSet)
        return 1;

    // We likely want to mute the daemon for log clarity.
    Utils::remove_argument(argv, argc, "--mutejamid", [&]() { globalEnv.muteDaemon = true; });

    // Allow the user to enable fatal warnings for certain tests.
    Utils::remove_argument(argv, argc, "--failonwarn", [&]() { qputenv("QT_FATAL_WARNINGS", "1"); });

    QApplication a(argc, argv);
    a.processEvents();

    ::testing::InitGoogleTest(&argc, argv);
    globalEnv.SetUp();
    auto result = RUN_ALL_TESTS();
    globalEnv.TearDown();

    return result;
}
