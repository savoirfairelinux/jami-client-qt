/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
#include "version.h"

#include <client/crash_report_database.h>
#include <client/settings.h>
#include <client/crashpad_info.h>

#include <QDir>
#include <QCoreApplication>
#include <QStandardPaths>

#if defined(OS_POSIX)
#define FILEPATHSTR(Qs)     Qs.toStdString()
#define STRFILEPATH(Qs)     QString::fromStdString(Qs)
#define CRASHPAD_EXECUTABLE "crashpad_handler"
#elif defined(OS_WIN)
#define FILEPATHSTR(Qs)     Qs.toStdWString()
#define STRFILEPATH(Qs)     QString::fromStdWString(Qs)
#define CRASHPAD_EXECUTABLE "crashpad_handler.exe"
#endif // OS_WIN

// We need the number of reports in the database to determine if the application crashed last time.
int
getReportCount(base::FilePath dbPath)
{
    auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath));
    if (database == nullptr) {
        return 0;
    }
    std::vector<crashpad::CrashReportDatabase::Report> reports;
    database->GetCompletedReports(&reports);
    return reports.size();
}

CrashPadClient::CrashPadClient(AppSettingsManager* settingsManager, QObject* parent)
    : CrashReportClient(settingsManager, parent)
{
    C_INFO << "Crashpad crash reporting enabled";
    // We store the crashpad database in the application's local data.
    const auto dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    dbPath_ = base::FilePath(FILEPATHSTR(QDir(dataPath).absoluteFilePath("crash_db")));
    // Make sure this directories exists.
    QDir().mkpath(STRFILEPATH(dbPath_.value()));

    // The crashpad_handler executable is in the same directory as this executable.
    const auto appBinPath = QCoreApplication::applicationDirPath();
    handlerPath_ = base::FilePath(FILEPATHSTR(QDir(appBinPath).filePath(CRASHPAD_EXECUTABLE)));
    C_DBG << "Handler path: " << handlerPath_.value();

    // Note: this may need to be called later in uploadLastReport to trigger an upload.
    startHandler();

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
}

static QString
getPlatformString()
{
    // This function returns a string that represents the platform the application is running on.
    QString platform = QSysInfo::prettyProductName();
    platform += " (" + QSysInfo::currentCpuArchitecture() + ")";
    return platform;
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

    // This is the metadata that will be sent with each crash report.
    // This data is required to correlate crash reports with the build so we can
    // effectively load and analyze the mini-dumps.
    using maptype = std::map<std::string, std::string>;
    maptype annotations = {{"client_sha", "unknown"},
                           {"jamicore_sha", "unknown"},
                           {"build_id", QString(VERSION_STRING).toStdString()},
                           {"platform", getPlatformString().toStdString()}};

    static crashpad::CrashpadClient client;
    bool success = client.StartHandler(handlerPath_,                  // handler
                                       dbPath_,                       // database_dir
                                       {},                            // metrics_dir
                                       crashReportUrl_.toStdString(), // url to upload reports
                                       annotations,                   // Annotations
                                       arguments,                     // Arguments
                                       true,                          // restartable
                                       false,                         // asynchronous_start
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
    crashpad_info->set_crashpad_handler_behavior(enableReportsAppSetting ? TriState::kEnabled
                                                                         : TriState::kDisabled);

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
clearAllReports(crashpad::CrashReportDatabase* database)
{
    using namespace crashpad;
    using OperationStatus = CrashReportDatabase::OperationStatus;
    std::vector<CrashReportDatabase::Report> reports;
    auto status = database->GetCompletedReports(&reports);
    if (OperationStatus::kNoError != status) {
        C_WARN << "Crashpad database GetCompletedReports failed";
        return;
    }

    for (const auto& report : reports) {
        status = database->DeleteReport(report.uuid);
        if (OperationStatus::kNoError != status) {
            C_WARN << "Crashpad database DeleteReport failed";
        }
    }
}

void
CrashPadClient::clearAllReports()
{
    auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath_));
    if (database == nullptr) {
        return;
    }
    ::clearAllReports(database.get());
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
        C_WARN << "Crashpad database GetPendingReports failed";
        return;
    }

    if (reports.empty()) {
        C_WARN << "Crashpad database reports empty";
        return;
    }

    auto report = reports.back();

    // Force the report to be uploaded.
    C_INFO << "Uploading report:" << report.uuid.ToString().c_str();
    status = database->RequestUpload(report.uuid);

    if (status != CrashReportDatabase::kNoError) {
        C_WARN << "Failed to request upload, status: " << status;
        return;
    }

    C_INFO << "Upload requested successfully.";
    // In this case, unless we restart the crashpad handler, the report won't
    // be uploaded until the application is terminated.
    startHandler();

    // Clear all reports from the database.
    ::clearAllReports(database.get());
}
