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

#pragma once

// Implementation choice
#include "crashreportclient.h"
#if not ENABLE_CRASHREPORTS
using CrashReportClientImpl = NullCrashReportClient;
#elif defined(ENABLE_CRASHPAD)
#include "crashreportclients/crashpad.h"
using CrashReportClientImpl = CrashPadClient;
#else
#pragma GCC error "No crash report client enabled, but reports are enabled."
#endif

#include <memory>

class CrashReporter : public QObject
{
    Q_OBJECT

public:
    explicit CrashReporter(AppSettingsManager* settingsManager, QObject* parent = nullptr)
        : QObject(parent)
    {
        client_ = std::make_unique<CrashReportClientImpl>(settingsManager, this);
    }

    Q_INVOKABLE void syncHandlerWithSettings()
    {
        client_->syncHandlerWithSettings();
    }
    Q_INVOKABLE void uploadLastReport()
    {
        client_->uploadLastReport();
    }
    Q_INVOKABLE void clearReports()
    {
        client_->clearReports();
    }
    Q_INVOKABLE bool getHasPendingReport()
    {
        return client_->getHasPendingReport();
    }

private:
    std::unique_ptr<CrashReportClient> client_;
};
