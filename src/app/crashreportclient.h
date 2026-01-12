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

#include "version_info.h"

#include <QVariantMap>

class AppSettingsManager;

/**
 * In the context of Jami where we employ GnuTLS, OpenSSL, and other cryptographic
 * components as part of secure communication protocols, it is essential to configure
 * crash reports with security in mind to prevent sensitive data from being exposed in crash
 * reports. We must assume that attackers may attempt to exploit vulnerabilities based on
 * stack data including values of cryptographic keys, certificates, etc. that may be used
 * in some way to compromise the security of the user's account.
 *
 * We attempt to mitigate this risk by configuring crash reports to avoid collecting stack
 * data beyond the offending function that caused the crash. We make the assumption that
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
 * Further considerations:
 *
 * - **Annotations**:
 *   Allows the inclusion of custom metadata in crash reports, such as the application version
 *   and build number, without exposing sensitive information. We must include this information
 *   to use the crash reports constructively.
 */

class CrashReportClient : public QObject
{
    Q_OBJECT

public:
    explicit CrashReportClient(AppSettingsManager* settingsManager, QObject* parent = nullptr)
        : QObject(parent)
        , settingsManager_(settingsManager)
        , crashReportUrl_(CRASH_REPORT_URL)
    {}
    ~CrashReportClient() = default;

    virtual void syncHandlerWithSettings() = 0;
    virtual void uploadLastReport() = 0;
    virtual void clearReports() = 0;

    // Used by the QML interface to query whether the application crashed last run.
    bool getHasPendingReport()
    {
        // In builds that do not support crashpad, this will always return false, and
        // thus will never trigger the dialog asking the user to upload the last report.
        return crashedLastRun_;
    }

protected:
    // This function is used to toggle automatic crash reporting.
    virtual void setUploadsEnabled(bool enabled) = 0;

    // We will need to access the crash report related settings.
    AppSettingsManager* settingsManager_;

    // The endpoint URL that crash reports will be uploaded to.
    QString crashReportUrl_;

    // We store if the last run resulted in
    bool crashedLastRun_ {false};

    // This is the metadata that will be sent with each crash report.
    // This data is required to correlate crash reports with the build so we can
    // effectively load and analyze the mini-dumps.
    QVariantMap metaData_ {
        {"platform", QSysInfo::prettyProductName() + "_" + QSysInfo::currentCpuArchitecture()},
        {"client_sha", APP_VERSION_STRING},
        {"jamicore_sha", CORE_VERSION_STRING},
        {"build_id", BUILD_VERSION_STRING},
#if defined(Q_OS_WIN) && defined(BETA)
        {"build_variant", "beta"},
#endif
    };
};

// Null implementation of the crash report client
class NullCrashReportClient : public CrashReportClient
{
    Q_OBJECT

public:
    explicit NullCrashReportClient(AppSettingsManager* settingsManager, QObject* parent = nullptr)
        : CrashReportClient(settingsManager, parent)
    {}

    void syncHandlerWithSettings() override {}
    void uploadLastReport() override {}
    void clearReports() override {}

protected:
    void setUploadsEnabled(bool enabled) override {}
};
