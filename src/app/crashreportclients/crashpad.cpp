/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

#include "crashpad.h"

#include "appsettingsmanager.h"
#include "global.h"

#include <client/crash_report_database.h>
#include <client/settings.h>
#include <client/crashpad_info.h>

#include <QDir>
#include <QCoreApplication>
#include <QStandardPaths>
#include <QThreadPool>

#include <thread>

#if defined(OS_WIN)
#define FILEPATHSTR(Qs)     Qs.toStdWString()
#define STRFILEPATH(Qs)     QString::fromStdWString(Qs)
#define CRASHPAD_EXECUTABLE "crashpad_handler.exe"
#else
#define FILEPATHSTR(Qs)     Qs.toStdString()
#define STRFILEPATH(Qs)     QString::fromStdString(Qs)
#define CRASHPAD_EXECUTABLE "crashpad_handler"
#endif // OS_WIN

// We need the number of reports in the database to determine if the application crashed last time.
static int
getReportCount(base::FilePath dbPath)
{
    auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath));
    if (database == nullptr) {
        return 0;
    }
    std::vector<crashpad::CrashReportDatabase::Report> completedReports;
    database->GetCompletedReports(&completedReports);
    return completedReports.size();
}

static void
clearCompletedReports(crashpad::CrashReportDatabase* database)
{
    using namespace crashpad;
    using OperationStatus = CrashReportDatabase::OperationStatus;

    std::vector<CrashReportDatabase::Report> reports;
    auto status = database->GetCompletedReports(&reports);
    if (OperationStatus::kNoError != status) {
        C_WARN << "Could not retrieve completed reports";
        return;
    }

    for (const auto& report : reports) {
        C_INFO.noquote() << QString("Deleting report: %1").arg(report.uuid.ToString().c_str());
        status = database->DeleteReport(report.uuid);
        if (OperationStatus::kNoError != status) {
            C_WARN << "Failed to delete report";
        }
    }
}

CrashPadClient::CrashPadClient(AppSettingsManager* settingsManager, QObject* parent)
    : CrashReportClient(settingsManager, parent)
{
    try {
        C_INFO << "Crashpad crash reporting enabled";

        // We store the crashpad database in the application's local data.
        const auto dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        if (dataPath.isEmpty()) {
            throw std::runtime_error("Failed to retrieve writable location for AppLocalData");
        }
        dbPath_ = base::FilePath(FILEPATHSTR(QDir(dataPath).absoluteFilePath("crash_db")));

        // Make sure the database directory exists.
        if (!QDir().mkpath(STRFILEPATH(dbPath_.value()))) {
            throw std::runtime_error("Failed to create crash database directory");
        }

        // The crashpad_handler executable is in the same directory as this executable.
        const auto appBinPath = QCoreApplication::applicationDirPath();
        if (appBinPath.isEmpty()) {
            throw std::runtime_error("Failed to retrieve application directory path");
        }
        handlerPath_ = base::FilePath(FILEPATHSTR(QDir(appBinPath).filePath(CRASHPAD_EXECUTABLE)));
        C_DBG << "Handler runtime path: " << handlerPath_.value();

        // Check if the application crashed last time it was run by checking the crashpad database
        // report count. If there is at least one report, we set the crashedLastRun_ flag to true.
        // The flag will be queried by the QML interface to display a dialog. If the user accepts,
        // the uploadLastReport function will be called, otherwise the reports will be cleared
        // to avoid a build up of crash reports on the user's system.
        using key = Settings::Key;
        auto automaticReporting = settingsManager_->getValue(key::EnableAutomaticCrashReporting).toBool();
        if (getReportCount(dbPath_) > 0 && !automaticReporting) {
            crashedLastRun_ = true;
        }

        // If we crashed last time and need to send off a report, then uploadLastReport will call
        // startHandler, and considering the `restartable` option for `StartHandler` is unused,
        // and that restarting the handler will cause an assertion failure when debugging Linux,
        // we will just not start the handler here in that case. The handler will be started in
        // the clearReports function after the reports are cleared.
        if (!crashedLastRun_) {
            startHandler();
        }
    } catch (const std::exception& e) {
        C_ERR << "Error initializing CrashPadClient: " << e.what();
    } catch (...) {
        C_ERR << "Unknown error initializing CrashPadClient";
    }
}

CrashPadClient::~CrashPadClient()
{
    // Remove any remaining stale crash reports.
    // We use sleep to ensure that the reports are cleared after a forced upload,
    // and it's possible that the reports are still being processed. This is a
    // workaround for the lack of a synchronous `report-uploaded` signal/event.
    if (auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath_))) {
        clearCompletedReports(database.get());
    }
}

void
CrashPadClient::startHandler()
{
    std::vector<std::string> arguments;

    // We disable rate-limiting because we want to upload crash reports as soon as possible.
    // Perhaps we should enable rate-limiting in the future to avoid spamming the server, but
    // we will need to investigate how that works in crashpad's implementation.
    arguments.push_back("--no-rate-limit");

    // We disable gzip compression because we want to be able to read the reports easily.
    arguments.push_back("--no-upload-gzip");

    // Convert the client metadata to map-string-string.
    std::map<std::string, std::string> annotations;
    Q_FOREACH (auto key, metaData_.keys()) {
        annotations[key.toStdString()] = metaData_[key].toString().toStdString();
    }

    C_INFO << "Starting crashpad handler";

    bool success = client_.StartHandler(handlerPath_,                  // handler
                                        dbPath_,                       // database_dir
                                        {},                            // metrics_dir
                                        crashReportUrl_.toStdString(), // url to upload reports
                                        annotations,                   // Annotations
                                        arguments,                     // Arguments
                                        false,                         // restartable (this doesn't do anything)
                                        false,                         // asynchronous_start (this doesn't do anything)
                                        std::vector<base::FilePath>()  // Attachments
    );

    if (!success) {
        C_WARN << "Crashpad initialization failed";
        return;
    }

    // Update the handler settings after starting the handler (we may have restarted it).
    syncHandlerWithSettings();
}

void
CrashPadClient::syncHandlerWithSettings()
{
    // Configure the crashpad handler with the settings from the settings manager.
    using key = Settings::Key;
    using namespace crashpad;
    CrashpadInfo* crashpad_info = CrashpadInfo::GetCrashpadInfo();

    // Optionally disable crashpad handler.
    auto enableReportsAppSetting = settingsManager_->getValue(key::EnableCrashReporting).toBool();
    crashpad_info->set_crashpad_handler_behavior(enableReportsAppSetting ? TriState::kEnabled : TriState::kDisabled);

    // Enable automatic crash reporting if the user has opted in.
    auto automaticReporting = settingsManager_->getValue(key::EnableAutomaticCrashReporting).toBool();
    setUploadsEnabled(automaticReporting);
}

void
CrashPadClient::setUploadsEnabled(bool enabled)
{
    auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath_));
    if (database != nullptr && database->GetSettings() != nullptr) {
        database->GetSettings()->SetUploadsEnabled(enabled);
    }
}

void
CrashPadClient::clearReports()
{
    auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath_));
    if (database == nullptr) {
        return;
    }

    C_DBG << "Clearing completed crash reports";

    const time_t secondsToWaitForReportLocks = 1;
    database->CleanDatabase(secondsToWaitForReportLocks);

    ::clearCompletedReports(database.get());

    // If the crashedLastRun_ flag is set, then we should follow up and start the handler.
    // Refer to the comment in constructor for more information on why the handler wasn't
    // started in the constructor if we crashed last time.
    if (crashedLastRun_) {
        startHandler();
    }
}

void
CrashPadClient::uploadLastReport()
{
    using namespace crashpad;

    // Find the latest crash report.
    auto database = CrashReportDatabase::Initialize(base::FilePath(dbPath_));
    if (database == nullptr) {
        C_WARN << "Crashpad database initialization failed";
        return;
    }

    std::vector<CrashReportDatabase::Report> reports;
    using OperationStatus = CrashReportDatabase::OperationStatus;
    auto status = database->GetCompletedReports(&reports);
    if (OperationStatus::kNoError != status) {
        C_WARN << "Crashpad database GetCompletedReports failed";
        return;
    }

    if (reports.empty()) {
        C_WARN << "Crashpad database contains no completed reports";
        return;
    }

    auto report = reports.back();

    // Force the report to be uploaded (should change the report state to pending).
    C_INFO << "Requesting report upload:" << report.uuid.ToString().c_str();
    status = database->RequestUpload(report.uuid);

    if (status != CrashReportDatabase::kNoError) {
        // This may indicate that the report has already been removed from the database.
        C_WARN << "Failed to request upload, status: " << status;
        return;
    }

    // In this case, unless we restart the crashpad handler, the report won't
    // be uploaded until the application is terminated.
    startHandler();

    // Let's wait for the report to be uploaded then clear all reports on a
    // separate thread to avoid blocking the UI.
    QThreadPool::globalInstance()->start([this, uuid = report.uuid]() {
        auto database = CrashReportDatabase::Initialize(base::FilePath(dbPath_));
        if (database == nullptr) {
            C_WARN << "Crashpad database initialization failed";
            return;
        }

        // Wait up to 10 seconds for the report to be uploaded.
        // Around 5s has been observed running the submission server locally when the client
        // is on Windows.
        const int maxAttempts = 40;
        int attempts = 0;
        auto timeout = std::chrono::milliseconds(250);

        C_INFO << "Waiting for report to be uploaded";
        while (attempts++ < maxAttempts) {
            CrashReportDatabase::Report report;
            if (database->LookUpCrashReport(uuid, &report) == CrashReportDatabase::kNoError) {
                if (report.uploaded && database->DeleteReport(uuid) == CrashReportDatabase::kNoError) {
                    C_INFO << "Report uploaded and deleted successfully";
                    return;
                }
            }
            std::this_thread::sleep_for(timeout);
        }

        // Note: This usually indicates that the submission server is inaccessible.
        C_WARN << "Failed to delete report. It may not have been uploaded successfully";

        // If we failed to delete the report, we should still try to clear any dangling reports.
        // This will prevent the database from growing indefinitely by removing at least the
        // previous unsuccessfully removed report. In this case, we don't know if the report
        // was successfully uploaded or not. This is a best-effort attempt.
        ::clearCompletedReports(database.get());
    });
}
