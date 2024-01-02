/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
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

    enum GetError {
        DISCONNECTED,
        CONTENT_NOT_FOUND,
        ACCESS_DENIED,
        SSL_ERROR,
        CANCELED,
        NETWORK_ERROR,
    };
    Q_ENUM(GetError)

    void sendGetRequest(const QUrl& url, std::function<void(const QByteArray&)>&& onDoneCallback);
    void sendGetRequest(const QUrl& url,
                        const QMap<QString, QByteArray>& header,
                        std::function<void(const QByteArray&)>&& onDoneCallback);
    void sendGetRequest(const QNetworkRequest& request,
                        std::function<void(const QByteArray&)>&& onDoneCallback);
    int downloadFile(const QUrl& url,
                     int replyId,
                     std::function<void(bool, const QString&)>&& onDoneCallback,
                     const QString& filePath,
                     const QString& extension = {});
    void resetDownload(int replyId);
    void cancelDownload(int replyId);
Q_SIGNALS:
    void errorOccurred(GetError error, const QString& msg = {});
    void downloadProgressChanged(qint64 bytesRead, qint64 totalBytes);
    void downloadFinished(int replyId);
    void downloadStarted(int replyId);

protected:
    QNetworkAccessManager* manager_;

private:
    ConnectivityMonitor* connectivityMonitor_;
    bool lastConnectionState_;
    QMap<int, QNetworkReply*> downloadReplies_ {};
    QMap<int, QFile*> files_ {};
    std::mt19937 rng_;
};
Q_DECLARE_METATYPE(NetworkManager*)
