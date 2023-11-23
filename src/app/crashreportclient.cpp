/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "crashreportclient.h"

#include "appsettingsmanager.h"

#ifdef ENABLE_CRASHPAD
#include <client/crash_report_database.h>
#include <client/crashpad_client.h>
#include <client/settings.h>
#endif // ENABLE_CRASHPAD

#include <QDir>
#include <QCoreApplication>
#include <QStandardPaths>

#include <chrono>
#include <thread>

#ifdef ENABLE_CRASHPAD
#if defined(OS_POSIX)
#define FILEPATHSTR(Qs) Qs.toStdString()
#define STRFILEPATH(Qs) QString::fromStdString(Qs)
#define CRASHPADBIN     "crashpad_handler"
#elif defined(OS_WIN)
#define FILEPATHSTR(Qs) Qs.toStdWString()
#define STRFILEPATH(Qs) QString::fromStdWString(Qs)
#define CRASHPADBIN     "crashpad_handler.exe"
#endif // OS_WIN
#endif // ENABLE_CRASHPAD

// Use a local server for debugging
#ifndef NDEBUG
#define CRASH_REPORT_URL "http://localhost:8080/submit"
#else
#define CRASH_REPORT_URL "https://crash.jami.net/submit"
#endif

CrashReportClient::CrashReportClient(AppSettingsManager* settingsManager,
                                     QObject* parent)
    : QObject(parent)
    , settingsManager_(settingsManager)
    , url_(CRASH_REPORT_URL)
{
#ifdef ENABLE_CRASHPAD
    // We store the crashpad database in the application's local data.
    const auto dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    dbPath_ = base::FilePath(FILEPATHSTR(QDir(dataPath).absoluteFilePath("crash_db")));
    // Make sure this directories exists.
    QDir().mkpath(STRFILEPATH(dbPath_.value()));

    // The crashpad_handler executable is in the same directory as this executable.
    const auto appBinPath = QCoreApplication::applicationDirPath();
    handlerPath_ = base::FilePath(FILEPATHSTR(QDir(appBinPath).filePath(CRASHPADBIN)));
#endif // ENABLE_CRASHPAD

    startHandler();
}

void
CrashReportClient::startHandler()
{
#ifdef ENABLE_CRASHPAD
    std::vector<std::string> arguments;
    arguments.push_back("--no-rate-limit");
    //arguments.push_back("--no-upload-gzip");
    bool success = client_.StartHandler(handlerPath_,
                                        dbPath_,
                                        {},
                                        url_.toStdString(),                   // url
                                        std::map<std::string, std::string>(), // Annotations
                                        arguments,                            // Arguments
                                        true,                                 // restartable
                                        false,                                // asynchronous_start
                                        std::vector<base::FilePath>()         // Attachments
    );

    if (!success) {
        qWarning() << "Crashpad initialization failed";
        return;
    }
#endif // ENABLE_CRASHPAD

    using key = Settings::Key;
    setUploadsEnabled(true);//settingsManager_->getValue(key::EnableAutomaticReporting).toBool());

    // When the application crashes, the flag LastRunWasGraceful will be set to false.
    // When the application starts, if the flag is false and AutomaticCrashReports is
    // false, it will request the user to confirm the upload of the last crash report,
    // because it was not uploaded automatically.
    if (!settingsManager_->getValue(key::LastExitWasGraceful).toBool()) {
        // For now this will print the last report.
        qDebug() << "Application crashed last run.";

        // TODO: the UI hasn't loaded yet, so we can't show a dialog.
        // This will need to be deferred until the UI is ready.
        Q_EMIT requestReportUpload();
        // Test: This will upload the last report.
        // Note: there seem to be some issues with the crashpad_handler
        // upload on Linux.  It works on Windows.
        uploadLastReport();
    }

    // Set the LastRunWasGraceful key to false.
    // Note: The destructor of QApplication should set the key to true for this to work.
    settingsManager_->setValue(key::LastExitWasGraceful, false);
}

void
CrashReportClient::setUploadsEnabled(bool enabled)
{
#ifdef ENABLE_CRASHPAD
    auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath_));
    if (database != nullptr && database->GetSettings() != nullptr) {
        database->GetSettings()->SetUploadsEnabled(enabled);
    }
#endif // ENABLE_CRASHPAD
}

// This function is used to upload the last crash report that wasn't uploaded yet.
void
CrashReportClient::uploadLastReport()
{
#ifdef ENABLE_CRASHPAD
    using namespace crashpad;

    // Find the latest crash report.
    auto database = CrashReportDatabase::Initialize(base::FilePath(dbPath_));
    if (database == nullptr) {
        qWarning() << "Crashpad database initialization failed";
        return;
    }

    std::vector<CrashReportDatabase::Report> reports;
    using OperationStatus = CrashReportDatabase::OperationStatus;
    auto status = database->GetCompletedReports(&reports);
    if (OperationStatus::kNoError != status) {
        qWarning() << "Crashpad database GetPendingReports failed";
        return;
    }

    if (reports.empty()) {
        qWarning() << "Crashpad database reports empty";
        return;
    }

    auto report = reports.back();
    // Force the report to be uploaded.
    qInfo() << "Uploading report" << report.uuid.ToString().c_str();
    database->RequestUpload(report.uuid);
#endif // ENABLE_CRASHPAD
}
