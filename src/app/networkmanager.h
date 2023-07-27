/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
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
#include <QFile>
#include <QSslError>
#include <QMap>
#include <QString>
#include <QNetworkReply>
#include <random>

class QNetworkAccessManager;
class ConnectivityMonitor;

class NetworkManager : public QObject
{
    Q_OBJECT
public:
    explicit NetworkManager(ConnectivityMonitor* cm, QObject* parent = nullptr);
    virtual ~NetworkManager() = default;

    enum GetError { DISCONNECTED, NETWORK_ERROR, ACCESS_DENIED, SSL_ERROR, CANCELED };
    Q_ENUM(GetError)

    void sendGetRequest(const QUrl& url, std::function<void(const QByteArray&)>&& onDoneCallback);

    unsigned int downloadFile(const QUrl& url,
                              unsigned int replyId,
                              std::function<void(bool, const QString&)>&& onDoneCallback,
                              const QString& filePath);
    void resetDownload(unsigned int replyId);
    void cancelDownload(unsigned int replyId);
Q_SIGNALS:
    void errorOccurred(GetError error, const QString& msg = {});
    void downloadProgressChanged(qint64 bytesRead, qint64 totalBytes);
    void downloadFinished(unsigned int replyId);
    void downloadStarted(unsigned int replyId);

protected:
    QNetworkAccessManager* manager_;

private:
    ConnectivityMonitor* connectivityMonitor_;
    bool lastConnectionState_;
    QMap<unsigned int, QNetworkReply*> downloadReplies_ {};
    QMap<unsigned int, QFile*> files_ {};
    std::mt19937 rng_;
};
Q_DECLARE_METATYPE(NetworkManager*)
