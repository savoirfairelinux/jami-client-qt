/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "updatemanager.h"

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

struct UpdateManager::Impl : public QObject
{
    Impl(const QString& url, ConnectivityMonitor* cm, LRCInstance* instance, UpdateManager& parent)
        : QObject(nullptr)
        , parent_(parent)
        , lrcInstance_(instance)
        , baseUrlString_(url.isEmpty() ? downloadUrl : url)
        , tempPath_(QDir::tempPath())
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
                    &NetWorkManager::errorOccured,
                    &parent_,
                    &UpdateManager::updateCheckErrorOccurred);

        cleanUpdateFiles();
        QUrl versionUrl {isBeta ? QUrl::fromUserInput(baseUrlString_ + betaVersionSubUrl)
                                : QUrl::fromUserInput(baseUrlString_ + versionSubUrl)};
        parent_.get(versionUrl, [this, quiet](const QString& latestVersionString) {
            if (latestVersionString.isEmpty()) {
                qWarning() << "Error checking version";
                if (!quiet)
                    Q_EMIT parent_.updateCheckReplyReceived(false);
                return;
            }
            auto currentVersion = QString(VERSION_STRING).toULongLong();
            auto latestVersion = latestVersionString.toULongLong();
            qDebug() << "latest: " << latestVersion << " current: " << currentVersion;
            if (latestVersion > currentVersion) {
                qDebug() << "New version found";
                Q_EMIT parent_.updateCheckReplyReceived(true, true);
            } else {
                qDebug() << "No new version found";
                if (!quiet)
                    Q_EMIT parent_.updateCheckReplyReceived(true, false);
            }
        });
    };

    void applyUpdates(bool beta = false)
    {
        parent_.disconnect();
        connect(&parent_,
                &NetWorkManager::errorOccured,
                &parent_,
                &UpdateManager::updateDownloadErrorOccurred);
        connect(&parent_, &NetWorkManager::statusChanged, this, [this](GetStatus status) {
            switch (status) {
            case GetStatus::STARTED:
                connect(&parent_,
                        &NetWorkManager::downloadProgressChanged,
                        &parent_,
                        &UpdateManager::updateDownloadProgressChanged);
                Q_EMIT parent_.updateDownloadStarted();
                break;
            case GetStatus::FINISHED:
                Q_EMIT parent_.updateDownloadFinished();
                break;
            default:
                break;
            }
        });

        QUrl downloadUrl {(beta || isBeta) ? QUrl::fromUserInput(baseUrlString_ + betaMsiSubUrl)
                                           : QUrl::fromUserInput(baseUrlString_ + msiSubUrl)};

        parent_.get(
            downloadUrl,
            [this, downloadUrl](const QString&) {
                lrcInstance_->finish();
                Q_EMIT lrcInstance_->quitEngineRequested();
                auto args = QString(" /passive /norestart WIXNONUILAUNCH=1");
                QProcess process;
                process.start("powershell ",
                              QStringList() << tempPath_ + "\\" + downloadUrl.fileName() << "/L*V"
                                            << tempPath_ + "\\jami_x64_install.log" + args);
                process.waitForFinished();
            },
            tempPath_);
    };

    void cancelUpdate()
    {
        parent_.cancelRequest();
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
        QString dir = QDir::tempPath();
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

    UpdateManager& parent_;

    LRCInstance* lrcInstance_ {nullptr};
    QString baseUrlString_;
    QString tempPath_;
    QTimer* updateTimer_;
};

UpdateManager::UpdateManager(const QString& url,
                             ConnectivityMonitor* cm,
                             LRCInstance* instance,
                             QObject* parent)
    : NetWorkManager(cm, parent)
    , pimpl_(std::make_unique<Impl>(url, cm, instance, *this))
{}

UpdateManager::~UpdateManager() {}

void
UpdateManager::checkForUpdates(bool quiet)
{
    pimpl_->checkForUpdates(quiet);
}

void
UpdateManager::applyUpdates(bool beta)
{
    pimpl_->applyUpdates(beta);
}

void
UpdateManager::cancelUpdate()
{
    pimpl_->cancelUpdate();
}

void
UpdateManager::setAutoUpdateCheck(bool state)
{
    pimpl_->setAutoUpdateCheck(state);
}

bool
UpdateManager::isCurrentVersionBeta()
{
    return isBeta;
}

bool
UpdateManager::isUpdaterEnabled()
{
#ifdef Q_OS_WIN
    return true;
#endif
    return false;
}

bool
UpdateManager::isAutoUpdaterEnabled()
{
    return false;
}
