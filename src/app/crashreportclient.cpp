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
#include <client/crashpad_info.h>
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

/**
 * In the context of Jami where we employ GnuTLS, OpenSSL, and other cryptographic
 * components as part of secure communication protocols, it is essential to configure
 * Crashpad with security in mind to prevent sensitive data from being exposed in crash
 * reports. We must assume that attackers may attempt to exploit vulnerabilities based on
 * stack data including values of cryptographic keys, certificates, etc. that may be used
 * in some way to compromise the security of the user's account.
 *
 * We attempt to mitigate this risk by configuring Crashpad to avoid collecting stack data
 * beyond the offending function that caused the crash. We make the assumption that
 * cryptographically sensitive data is not stored on the stack by 3rd party libraries.
 *
 * We also take care to avoid sending crash reports automatically and instead require user
 * consent before uploading the last report.
 *
 * IMPORTANT: The opt-in approach is crucial, and the potential implications of transmitting
 * these reports must be communicated to the user. The user should be informed that we cannot
 * guarantee the security of the data in the crash report, even if we take steps to avoid
 * leaking any sensitive information.
 *
 * We offer the following configuration options to enhance security:
 *
 * - (Option) EnableCrashReporting (default - true):
 *   An application settings allowing users to disable crash handling entirely.
 *
 * - (Option) EnableAutomaticCrashReporting (default - false):
 *   This setting allows users to opt-in to automatic crash reporting, which should be disabled
 *   by default. When the application crashes, the user should be prompted to upload the last
 *   crash report. If the user agrees, the report will be uploaded to the server. If this
 *   setting is enabled, no prompt will be shown, and the report will be uploaded automatically
 *   when the application crashes.
 *
 * - (Option) EnableDeepCrashReports (default - false):
 *   This is used to control the depth of data collection of indirectly referenced memory,
 *   which should prevent stack data in underlying libraries from being included in crash
 *   reports. Controlled using an application setting.
 *
 * Further considerations:
 *
 * - **Annotations**:
 *   Allows the inclusion of custom metadata in crash reports, such as the application version
 *   and build number, without exposing sensitive information. We must include this information
 *   to use the crash reports constructively.
 */

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

    // Update the handler settings after starting the handler (we may have restarted it).
    setHandlerSettings();
#endif // ENABLE_CRASHPAD
}

void
CrashReportClient::setHandlerSettings()
{
    // Configure the crashpad handler with the settings from the settings manager.
    using key = Settings::Key;
    crashpad::CrashpadInfo* crashpad_info = crashpad::CrashpadInfo::GetCrashpadInfo();

    // Optionally disable crashpad handler.
    auto enableCrashReporting = settingsManager_->getValue(key::EnableCrashReporting).toBool();
    if (!enableCrashReporting) {
        crashpad_info->set_crashpad_handler_behavior(crashpad::TriState::kDisabled);
    } else {
        crashpad_info->set_crashpad_handler_behavior(crashpad::TriState::kEnabled);
    }

    // Enable automatic crash reporting if the user has opted in.
    auto automaticReporting = settingsManager_->getValue(key::EnableAutomaticCrashReporting).toBool();
    setUploadsEnabled(automaticReporting);

    // Limit data collection by disabling the capture of indirectly referenced memory
    auto deepCrashReports = settingsManager_->getValue(key::EnableDeepCrashReports).toBool();
    if (!deepCrashReports) {
        crashpad_info->set_gather_indirectly_referenced_memory(crashpad::TriState::kDisabled, 0);
    } else {
        // crashpad_info->set_gather_indirectly_referenced_memory(crashpad::TriState::kEnabled, maxUint32);
        crashpad_info->set_gather_indirectly_referenced_memory(crashpad::TriState::kEnabled,
                                                               std::numeric_limits<uint32_t>::max());
    }
}

// This function is used to toggle automatic crash reporting.
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

// This function is used to clear all crash reports from the crashpad database.
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

// This function is a public Q_INVOKABLE function that is used to clear all crash reports.
void
CrashReportClient::clearAllReports()
{
#ifdef ENABLE_CRASHPAD
    auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath_));
    if (database == nullptr) {
        return;
    }
    ::clearAllReports(database.get());
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

    // Clear all reports from the database.
    ::clearAllReports(database.get());
#endif // ENABLE_CRASHPAD
}

// Used by the QML interface to query whether the application crashed last run.
bool
CrashReportClient::getCrashedLastRun()
{
    // In builds that do not support crashpad, this will always return false,
    // and thus will never trigger the dialog asking the user to upload the last report.
    return crashedLastRun_;
}
