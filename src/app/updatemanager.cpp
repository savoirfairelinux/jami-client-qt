/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    Impl(const QString& url, LRCInstance* instance, UpdateManager& parent)
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
                    &NetworkManager::errorOccured,
                    &parent_,
                    &UpdateManager::updateErrorOccurred);

        cleanUpdateFiles();
        QUrl versionUrl {isBeta ? QUrl::fromUserInput(baseUrlString_ + betaVersionSubUrl)
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
                &NetworkManager::errorOccured,
                &parent_,
                &UpdateManager::updateErrorOccurred);

        connect(&parent_, &UpdateManager::statusChanged, this, [this](Status status) {
            switch (status) {
            case Status::STARTED:
                Q_EMIT parent_.updateDownloadStarted();
                break;
            case Status::FINISHED:
                Q_EMIT parent_.updateDownloadFinished();
                break;
            default:
                break;
            }
        });

        QUrl downloadUrl {(beta || isBeta) ? QUrl::fromUserInput(baseUrlString_ + betaMsiSubUrl)
                                           : QUrl::fromUserInput(baseUrlString_ + msiSubUrl)};

        parent_.downloadFile(
            downloadUrl,
            [this, downloadUrl](bool success, const QString& errorMessage) {
                Q_UNUSED(success)
                Q_UNUSED(errorMessage)
                lrcInstance_->finish();
                QProcess process;
                auto msiPath = QDir::toNativeSeparators(tempPath_ + "/jami.release.x64.msi");
                auto logPath = QDir::toNativeSeparators(tempPath_ + "/jami_x64_install.log");
                process.start("msiexec",
                              QStringList() << "/i" << msiPath << "/passive"
                                            << "/norestart"
                                            << "WIXNONUILAUNCH=1"
                                            << "/L*V" << logPath);
                process.waitForFinished();
            },
            tempPath_);
    };

    void cancelUpdate()
    {
        parent_.cancelDownload();
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
    : NetworkManager(cm, parent)
    , pimpl_(std::make_unique<Impl>(url, instance, *this))
{}

UpdateManager::~UpdateManager()
{
    cancelDownload();
}

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

void
UpdateManager::cancelDownload()
{
    if (downloadReply_) {
        Q_EMIT errorOccured(GetError::CANCELED);
        downloadReply_->abort();
        resetDownload();
    }
}

void
UpdateManager::downloadFile(const QUrl& url,
                            std::function<void(bool, const QString&)> onDoneCallback,
                            const QString& filePath)
{
    // If there is already a download in progress, return.
    if (downloadReply_ && downloadReply_->isRunning()) {
        qWarning() << Q_FUNC_INFO << "Download already in progress";
        return;
    }

    // Clean up any previous download.
    resetDownload();

    // If the url is invalid, return.
    if (!url.isValid()) {
        Q_EMIT errorOccured(GetError::NETWORK_ERROR, "Invalid url");
        return;
    }

    // If the file path is empty, return.
    if (filePath.isEmpty()) {
        Q_EMIT errorOccured(GetError::NETWORK_ERROR, "Invalid file path");
        return;
    }

    // Create the file. Return if it cannot be created.
    QFileInfo fileInfo(url.path());
    QString fileName = fileInfo.fileName();
    file_.reset(new QFile(filePath + "/" + fileName));
    if (!file_->open(QIODevice::WriteOnly)) {
        Q_EMIT errorOccured(GetError::ACCESS_DENIED);
        file_.reset();
        qWarning() << Q_FUNC_INFO << "Could not open file for writing";
        return;
    }

    // Start the download.
    QNetworkRequest request(url);
    downloadReply_ = manager_->get(request);

    connect(downloadReply_, &QNetworkReply::readyRead, this, [=]() {
        if (file_ && file_->isOpen()) {
            file_->write(downloadReply_->readAll());
        }
    });

    connect(downloadReply_,
            &QNetworkReply::downloadProgress,
            this,
            [=](qint64 bytesReceived, qint64 bytesTotal) {
                Q_EMIT downloadProgressChanged(bytesReceived, bytesTotal);
            });

    connect(downloadReply_,
            QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this,
            [this](QNetworkReply::NetworkError error) {
                downloadReply_->disconnect();
                resetDownload();
                qWarning() << Q_FUNC_INFO
                           << QMetaEnum::fromType<QNetworkReply::NetworkError>().valueToKey(error);
                Q_EMIT errorOccured(GetError::NETWORK_ERROR);
            });

    connect(downloadReply_, &QNetworkReply::finished, this, [this, onDoneCallback]() {
        bool success = false;
        QString errorMessage;
        if (downloadReply_->error() == QNetworkReply::NoError) {
            resetDownload();
            success = true;
        } else {
            errorMessage = downloadReply_->errorString();
            resetDownload();
        }
        onDoneCallback(success, errorMessage);
        Q_EMIT statusChanged(Status::FINISHED);
    });

    Q_EMIT statusChanged(Status::STARTED);
}

void
UpdateManager::resetDownload()
{
    if (downloadReply_) {
        downloadReply_->deleteLater();
        downloadReply_ = nullptr;
    }
    if (file_) {
        if (file_->isOpen()) {
            file_->flush();
            file_->close();
        }
        file_->deleteLater();
        file_.reset();
    }
}
