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

#pragma once

#include "networkmanager.h"

#include <memory>

class LRCInstance;
class ConnectivityMonitor;

class UpdateManager final : public NetworkManager
{
    Q_OBJECT
    Q_DISABLE_COPY(UpdateManager)
public:
    explicit UpdateManager(const QString& url,
                           ConnectivityMonitor* cm,
                           LRCInstance* instance = nullptr,
                           QObject* parent = nullptr);
    ~UpdateManager();

    enum Status { STARTED, FINISHED };
    Q_ENUM(Status)

    Q_INVOKABLE void checkForUpdates(bool quiet = false);
    Q_INVOKABLE void applyUpdates(bool beta = false);
    Q_INVOKABLE void cancelUpdate();
    Q_INVOKABLE void setAutoUpdateCheck(bool state);
    Q_INVOKABLE bool isCurrentVersionBeta();
    Q_INVOKABLE bool isUpdaterEnabled();
    Q_INVOKABLE bool isAutoUpdaterEnabled();
    Q_INVOKABLE void cancelDownload();

    void downloadFile(const QUrl& url,
                      std::function<void(bool, const QString&)> onDoneCallback,
                      const QString& filePath);

Q_SIGNALS:
    void statusChanged(UpdateManager::Status status);
    void downloadProgressChanged(qint64 bytesRead, qint64 totalBytes);

    void updateCheckReplyReceived(bool ok, bool found = false);
    void updateErrorOccurred(const NetworkManager::GetError& error);
    void updateDownloadStarted();
    void updateDownloadProgressChanged(qint64 bytesRead, qint64 totalBytes);
    void updateDownloadFinished();
    void appCloseRequested();

private:
    void resetDownload();
    QNetworkReply* downloadReply_ {nullptr};
    QScopedPointer<QFile> file_;

private:
    struct Impl;
    std::unique_ptr<Impl> pimpl_;
};
Q_DECLARE_METATYPE(UpdateManager*)
