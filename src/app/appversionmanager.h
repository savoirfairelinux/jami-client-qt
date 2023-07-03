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

#include <memory>
#include "abstractupdatemanager.h"

class LRCInstance;
class ConnectivityMonitor;

class AppVersionManager final : public AbstractUpdateManager
{
    Q_OBJECT
    Q_DISABLE_COPY(AppVersionManager)
public:
    explicit AppVersionManager(const QString& url,
                               ConnectivityMonitor* cm,
                               LRCInstance* instance = nullptr,
                               QObject* parent = nullptr);
    ~AppVersionManager();

    Q_INVOKABLE void checkForUpdates(bool quiet = false);
    Q_INVOKABLE void applyUpdates(bool beta = false);
    Q_INVOKABLE bool isUpdaterEnabled();
    Q_INVOKABLE bool isAutoUpdaterEnabled() override;
    Q_INVOKABLE void setAutoUpdateCheck(bool state);
    Q_INVOKABLE void cancelUpdate();
    Q_INVOKABLE bool isCurrentVersionBeta();

Q_SIGNALS:
    void appCloseRequested();
    void updateCheckReplyReceived(bool ok, bool found = false);
    void updateDownloadProgressChanged(qint64 bytesRead, qint64 totalBytes);
    void updateErrorOccurred(const NetworkManager::GetError& error);

private:
    QScopedPointer<QFile> file_;
    QScopedPointer<unsigned int> replyId;

private:
    struct Impl;
    std::unique_ptr<Impl> pimpl_;
};
Q_DECLARE_METATYPE(AppVersionManager*)
