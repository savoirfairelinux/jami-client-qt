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

#pragma once

#include "crashreportclient.h"

#include <client/crashpad_client.h>

class AppSettingsManager;

class CrashPadClient final : public CrashReportClient
{
    Q_OBJECT

public:
    explicit CrashPadClient(AppSettingsManager* settingsManager, QObject* parent = nullptr);
    ~CrashPadClient();

    void syncHandlerWithSettings() override;
    void uploadLastReport() override;
    void clearReports() override;

protected:
    void setUploadsEnabled(bool enabled) override;

private:
    void startHandler();

    crashpad::CrashpadClient client_;
    base::FilePath dbPath_;
    base::FilePath handlerPath_;
};
