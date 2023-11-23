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

#include <QDir>

CrashReportClient::CrashReportClient(AppSettingsManager* settingsManager,
                                     const QString& url,
                                     QObject* parent)
    : QObject(parent)
    , settingsManager_(settingsManager)
    , url_(url)
{
    // We store the crashpad database and metrics database in the application's local data.
    const auto dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    dbPath_ = base::FilePath(FILEPATHSTR(QDir(dataPath).absoluteFilePath("crash_db")));
    metricsPath_ = base::FilePath(FILEPATHSTR(QDir(dataPath).absoluteFilePath("metrics_db")));

    // The crashpad_handler executable is in the same directory as this executable.
    const auto appBinPath = QCoreApplication::applicationDirPath();
    handlerPath_ = base::FilePath(FILEPATHSTR(QDir(appBinPath).filePath(CRASHPADBIN)));

    startHandler();
}

void
CrashReportClient::startHandler()
{
    std::vector<std::string> arguments;
    arguments.push_back("--no-rate-limit");
    arguments.push_back("--no-upload-gzip");
    bool success = client_.StartHandler(handlerPath_,
                                        dbPath_,
                                        metricsPath_,
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

    using key = Settings::Key;
    setUploadsEnabled(settingsManager_->getValue(key::EnableAutomaticReporting).toBool());

    // When the application crashes, the flag LastRunWasGraceful will be set to false.
    // When the application starts, if the flag is false and AutomaticCrashReports is
    // false, it will request the user to confirm the upload of the last crash report,
    // because it was not uploaded automatically.
    if (!settingsManager_->getValue(key::LastExitWasGraceful).toBool()) {
        // For now this will print the last report.
        qDebug() << "Application crashed last run.";
        Q_EMIT requestReportUpload();
    }

    // Now we set the LastRunWasGraceful key to false.
    // Note: The destructor of QApplication should set the key to true for this to work.
    settingsManager_->setValue(key::LastExitWasGraceful, false);
}

void
CrashReportClient::setUploadsEnabled(bool enabled)
{
    auto database = crashpad::CrashReportDatabase::Initialize(base::FilePath(dbPath_));
    if (database != nullptr && database->GetSettings() != nullptr) {
        database->GetSettings()->SetUploadsEnabled(enabled);
    }
}

// This function is used to upload the last crash report that wasn't uploaded yet.
void
CrashReportClient::uploadLastReport()
{
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
}
