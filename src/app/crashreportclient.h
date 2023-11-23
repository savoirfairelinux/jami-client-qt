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

#pragma once

#include "appsettingsmanager.h"

#include <QCoreApplication>
#include <QStandardPaths>
#include <QNetworkAccessManager>
#include <QHttpMultiPart>
#include <QFile>

#include <client/crash_report_database.h>
#include <client/crashpad_client.h>
#include <client/settings.h>

#if defined(OS_POSIX)
#define FILEPATHSTR(Qs) Qs.toStdString()
#define STRFILEPATH(Qs) QString::fromStdString(Qs)
#define CRASHPADBIN     "crashpad_handler"
#elif defined(OS_WIN)
#define FILEPATHSTR(Qs) Qs.toStdWString()
#define STRFILEPATH(Qs) QString::fromStdWString(Qs)
#define CRASHPADBIN     "crashpad_handler.exe"
#endif // OS_WIN

#define CRASH_REPORT_URL "http://localhost:8080/submit"

class CrashReportClient : public QObject
{
    Q_OBJECT
public:
    CrashReportClient(AppSettingsManager* settingsManager,
                      const QString& url,
                      QObject* parent = nullptr);
    ~CrashReportClient() = default;

    void startHandler();
    void setUploadsEnabled(bool enabled);
    void uploadLastReport();

Q_SIGNAL void uploadDone();

private:
    crashpad::CrashpadClient client_;
    AppSettingsManager* settingsManager_;
    base::FilePath dbPath_;
    base::FilePath metricsPath_;
    base::FilePath handlerPath_;
    QString url_;
};
