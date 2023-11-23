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
#include "global.h"
#include "version.h"

#ifdef ENABLE_CRASHPAD
#include <client/crash_report_database.h>
#include <client/crashpad_client.h>
#include <client/settings.h>
#endif // ENABLE_CRASHPAD

#include <QDir>
#include <QCoreApplication>
#include <QStandardPaths>

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
#define CRASH_REPORT_URL "http://localhost:8080/submit" // "https://crash.jami.net/submit"
#endif

CrashReportClient::CrashReportClient(AppSettingsManager* settingsManager, QObject* parent)
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
    C_DBG << "Handler path: " << handlerPath_.value();

    // Note: this may need to be called later in uploadLastReport to trigger an upload.
    startHandler();

    // Now we manage settings, and upload the last report if necessary.
    using key = Settings::Key;
    auto automaticReporting = settingsManager_->getValue(key::EnableAutomaticReporting).toBool();
    setUploadsEnabled(automaticReporting);

    // When the application crashes, the flag LastRunWasGraceful will not be set to true.
    // When the application starts, if the flag is false and AutomaticCrashReports is false,
    // we will request that the user to confirm the upload of the last crash report, because
    // it was not uploaded automatically.
    if (!settingsManager_->getValue(key::LastExitWasGraceful).toBool() && !automaticReporting) {
        // This flag will be queried by the QML interface to display a dialog.
        // If the user accepts, the uploadLastReport function will be called.
        crashedLastRun_ = true;
    }

    // Set the LastRunWasGraceful key to false.
    // Note: The destructor of QApplication should set the key to true for this to work.
    settingsManager_->setValue(key::LastExitWasGraceful, false);
#endif // ENABLE_CRASHPAD
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
CrashReportClient::startHandler()
{
#ifdef ENABLE_CRASHPAD
    std::vector<std::string> arguments;
    // We disable rate-limiting because we want to upload crash reports as soon as possible.
    // Perhaps we should enable rate-limiting in the future to avoid spamming the server, but
    // we will need to investigate how that works in crashpad's implementation.
    arguments.push_back("--no-rate-limit");
    // We disable gzip compression because we want to be able to read the reports easily.
    arguments.push_back("--no-upload-gzip");

    std::map<std::string, std::string> annotations;
    // This is the metadata that will be sent with each crash report. We keep this
    // in a QVariantMap so that it can be queried by the QML interface, but we
    // also need to convert it to a std::map<std::string, std::string> for crashpad.
    // This data is required to correlate crash reports with the build so we can
    // effectively load and analyze the mini-dumps.
    set_annotations({{"client_sha", "unknown"},
                     {"jamicore_sha", "unknown"},
                     {"build_id", QString(VERSION_STRING)},
                     {"platform", getPlatformString()}});
    Q_FOREACH (const QString& key, annotations_.keys()) {
        annotations.emplace(key.toStdString(), annotations_[key].toString().toStdString());
    }

    static crashpad::CrashpadClient client;
    bool success = client.StartHandler(handlerPath_,                 // handler
                                       dbPath_,                      // database_dir
                                       {},                           // metrics_dir
                                       url_.toStdString(),           // url to upload reports
                                       annotations,                  // Annotations
                                       arguments,                    // Arguments
                                       true,                         // restartable
                                       false,                        // asynchronous_start
                                       std::vector<base::FilePath>() // Attachments
    );

    if (!success) {
        C_WARN << "Crashpad initialization failed";
        return;
    }
#endif // ENABLE_CRASHPAD
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
#endif // ENABLE_CRASHPAD
}

bool
CrashReportClient::getCrashedLastRun()
{
    // In builds that do not support crashpad, this will always return false,
    // and thus will never trigger the dialog asking the user to upload the last report.
    return crashedLastRun_;
}
