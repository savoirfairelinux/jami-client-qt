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

#include "appsettingsmanager.h"
#include "crashreportclients/crashpad.h"

#include <client/crash_report_database.h>

#include <QCoreApplication>
#include <QDir>
#include <QScopeGuard>
#include <QSemaphore>
#include <QStandardPaths>
#include <QThreadPool>
#include <QUuid>

#include <gtest/gtest.h>

namespace {
class CrashPadClientWithoutHandler final : public CrashPadClient
{
public:
    using CrashPadClient::CrashPadClient;

private:
    void startHandler() override {}
};
} // namespace

TEST(CrashReportClient, UploadCleanupOutlivesClient)
{
    using Database = crashpad::CrashReportDatabase;

    const auto appName = QCoreApplication::applicationName();
    const auto testMode = QStandardPaths::isTestModeEnabled();
    const auto restorePaths = qScopeGuard([&] {
        QCoreApplication::setApplicationName(appName);
        QStandardPaths::setTestModeEnabled(testMode);
    });
    const auto testAppName = QString("crashpad-test-%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    QStandardPaths::setTestModeEnabled(true);
    QCoreApplication::setApplicationName(testAppName);
    const auto dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    ASSERT_EQ(QDir(dataPath).dirName(), testAppName);
    const auto removeDatabase = qScopeGuard([&] { QDir(dataPath).removeRecursively(); });
    const auto path = QDir(dataPath).filePath("crash_db");
    ASSERT_TRUE(QDir().mkpath(path));
#ifdef Q_OS_WIN
    const base::FilePath dbPath(path.toStdWString());
#else
    const base::FilePath dbPath(path.toStdString());
#endif
    auto database = Database::Initialize(dbPath);
    ASSERT_NE(database, nullptr);

    std::unique_ptr<Database::NewReport> newReport;
    crashpad::UUID uuid;
    ASSERT_EQ(database->PrepareNewCrashReport(&newReport), Database::kNoError);
    ASSERT_EQ(database->FinishedWritingCrashReport(std::move(newReport), &uuid), Database::kNoError);
    ASSERT_EQ(database->SkipReportUpload(uuid, crashpad::Metrics::CrashSkippedReason::kUploadsDisabled),
              Database::kNoError);

    AppSettingsManager settings;
    const auto automaticReporting = settings.getValue(Settings::Key::EnableAutomaticCrashReporting);
    const auto restoreSettings = qScopeGuard(
        [&] { settings.setValue(Settings::Key::EnableAutomaticCrashReporting, automaticReporting); });
    settings.setValue(Settings::Key::EnableAutomaticCrashReporting, false);
    auto client = std::make_unique<CrashPadClientWithoutHandler>(&settings);
    ASSERT_TRUE(client->getHasPendingReport());

    auto* pool = QThreadPool::globalInstance();
    const auto maxThreads = pool->maxThreadCount();
    QSemaphore started;
    QSemaphore unblock;
    const auto restorePool = qScopeGuard([&] {
        unblock.release();
        pool->waitForDone(15000);
        pool->setMaxThreadCount(maxThreads);
    });
    pool->setMaxThreadCount(1);
    pool->start([&] {
        started.release();
        unblock.acquire();
    });
    ASSERT_TRUE(started.tryAcquire(1, 5000));

    client->uploadLastReport();
    Database::Report report;
    ASSERT_EQ(database->LookUpCrashReport(uuid, &report), Database::kNoError);
    ASSERT_TRUE(report.upload_explicitly_requested);
    client.reset();

    // Complete the upload only after destruction so the destructor cannot delete it.
    std::unique_ptr<const Database::UploadReport> upload;
    ASSERT_EQ(database->GetReportForUploading(uuid, &upload, false), Database::kNoError);
    ASSERT_EQ(database->RecordUploadComplete(std::move(upload), "test-upload"), Database::kNoError);

    unblock.release();
    ASSERT_TRUE(pool->waitForDone(5000));
    EXPECT_EQ(database->LookUpCrashReport(uuid, &report), Database::kReportNotFound);
}
