/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

#include "appversionmanager.h"

#include "lrcinstance.h"
#include "version.h"

#include <QProcess>
#include <QTimer>
#include <QDir>

#ifdef BETA
static constexpr bool isBeta = true;
#else
static constexpr bool isBeta = false;
#endif

static constexpr int updatePeriod = 1000 * 60 * 60 * 24; // one day in millis
static constexpr char downloadUrl[] = "https://dl.jami.net/windows";
static constexpr char versionSubUrl[] = "/version";
static constexpr char betaVersionSubUrl[] = "/beta/version";
static constexpr char msiSubUrl[] = "/jami.release.x64.msi";
static constexpr char betaMsiSubUrl[] = "/beta/jami.beta.x64.msi";

struct AppVersionManager::Impl : public QObject
{
    Impl(const QString& url, LRCInstance* instance, AppVersionManager& parent)
        : QObject(nullptr)
        , parent_(parent)
        , lrcInstance_(instance)
        , baseUrlString_(url.isEmpty() ? downloadUrl : url)
        , updateTimer_(new QTimer(this))
    {
        connect(updateTimer_, &QTimer::timeout, this, [this] {
            // Quiet period update check.
            parent_.checkForUpdates(true);
        });
    };
    ~Impl() = default;

    void checkForUpdates(bool quiet)
    {
        parent_.disconnect();
        // Fail without UI if this is a programmatic check.
        if (!quiet)
            connect(&parent_,
                    &NetworkManager::errorOccurred,
                    &parent_,
                    &AppVersionManager::networkErrorOccurred);

        cleanUpdateFiles();
        const QUrl versionUrl {isBeta ? QUrl::fromUserInput(baseUrlString_ + betaVersionSubUrl)
                                      : QUrl::fromUserInput(baseUrlString_ + versionSubUrl)};
        parent_.sendGetRequest(versionUrl, [this, quiet](const QByteArray& latestVersionString) {
            if (latestVersionString.isEmpty()) {
                qWarning() << "Error checking version";
                if (!quiet)
                    Q_EMIT parent_.updateCheckReplyReceived(false);
                return;
            }
            auto currentVersion = QString(VERSION_STRING).toULongLong();
            auto latestVersion = latestVersionString.toULongLong();
            const QString channelStr = isBeta ? "beta" : "stable";
            const auto newVersionFound = latestVersion > currentVersion;
            qInfo().noquote() << "--------- Version info ------------"
                              << QString("\n - Current: %1 (%2)").arg(currentVersion).arg(channelStr);
            if (newVersionFound) {
                qDebug() << " - Latest: " << latestVersion;
                Q_EMIT parent_.updateCheckReplyReceived(true, true);
            } else if (!quiet) {
                Q_EMIT parent_.updateCheckReplyReceived(true, false);
            }
        });
    };

    void applyUpdates(bool beta = false)
    {
        parent_.disconnect();
        connect(&parent_,
                &NetworkManager::errorOccurred,
                &parent_,
                &AppVersionManager::networkErrorOccurred);

        const QUrl downloadUrl {(beta || isBeta)
                                    ? QUrl::fromUserInput(baseUrlString_ + betaMsiSubUrl)
                                    : QUrl::fromUserInput(baseUrlString_ + msiSubUrl)};

        const auto lastDownloadReplyId = parent_.replyId_;
        parent_.replyId_ = parent_.downloadFile(
            downloadUrl,
            lastDownloadReplyId,
            [downloadUrl](bool success, const QString& errorMessage) {
                Q_UNUSED(success)
                Q_UNUSED(errorMessage)
                QProcess process;
                auto basePath = QDir::tempPath() + QDir::separator();
                auto msiPath = QDir::toNativeSeparators(basePath + downloadUrl.fileName());
                auto logPath = QDir::toNativeSeparators(basePath + "jami_x64_install.log");
                process.startDetached("msiexec",
                                      QStringList() << "/i" << msiPath << "/passive"
                                                    << "/norestart"
                                                    << "WIXNONUILAUNCH=1"
                                                    << "/L*V" << logPath);
            },
            QDir::tempPath());
    };

    void cancelUpdate()
    {
        parent_.cancelDownload(parent_.replyId_);
    };

    void setAutoUpdateCheck(bool state)
    {
        // Quiet check for updates periodically, if set to.
        if (!state) {
            updateTimer_->stop();
            return;
        }
        updateTimer_->start(updatePeriod);
    };

    void cleanUpdateFiles()
    {
        // Delete all logs and msi in the temporary directory before launching.
        const QString dir = QDir::tempPath();
        QDir log_dir(dir, {"jami*.log"});
        for (const QString& filename : log_dir.entryList()) {
            log_dir.remove(filename);
        }
        QDir msi_dir(dir, {"jami*.msi"});
        for (const QString& filename : msi_dir.entryList()) {
            msi_dir.remove(filename);
        }
        QDir version_dir(dir, {"version"});
        for (const QString& filename : version_dir.entryList()) {
            version_dir.remove(filename);
        }
    };

    AppVersionManager& parent_;

    LRCInstance* lrcInstance_ {nullptr};
    QString baseUrlString_;
    QTimer* updateTimer_;
};

AppVersionManager::AppVersionManager(const QString& url,
                                     ConnectivityMonitor* cm,
                                     LRCInstance* instance,
                                     QObject* parent)
    : NetworkManager(cm, parent)
    , replyId_(0)
    , pimpl_(std::make_unique<Impl>(url, instance, *this))
{}

AppVersionManager::~AppVersionManager()
{
    cancelDownload(replyId_);
}

void
AppVersionManager::checkForUpdates(bool quiet)
{
    pimpl_->checkForUpdates(quiet);
}

void
AppVersionManager::applyUpdates(bool beta)
{
    pimpl_->applyUpdates(beta);
}

void
AppVersionManager::cancelUpdate()
{
    pimpl_->cancelUpdate();
}

void
AppVersionManager::setAutoUpdateCheck(bool state)
{
    pimpl_->setAutoUpdateCheck(state);
}

bool
AppVersionManager::isCurrentVersionBeta()
{
    return isBeta;
}

bool
AppVersionManager::isUpdaterEnabled()
{
#ifdef Q_OS_WIN
    return true;
#endif
    return false;
}

bool
AppVersionManager::isAutoUpdaterEnabled()
{
    return false;
}
