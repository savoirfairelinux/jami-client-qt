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

#include <QObject>

#ifdef ENABLE_CRASHPAD
#include <client/crash_report_database.h>
#include <client/crashpad_client.h>
#include <client/settings.h>
#endif // ENABLE_CRASHPAD

class AppSettingsManager;

class CrashReportClient : public QObject
{
    Q_OBJECT
public:
    CrashReportClient(AppSettingsManager* settingsManager,
                      QObject* parent = nullptr);
    ~CrashReportClient() = default;

    void startHandler();

    Q_INVOKABLE void setUploadsEnabled(bool enabled);
    Q_INVOKABLE void uploadLastReport();

    Q_SIGNAL void requestReportUpload();

private:
    AppSettingsManager* settingsManager_;
    QString url_;

#ifdef ENABLE_CRASHPAD
    crashpad::CrashpadClient client_;
    base::FilePath dbPath_;
    base::FilePath handlerPath_;
#endif // ENABLE_CRASHPAD
};
