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
#include <QNetworkReply>

class QNetworkAccessManager;
class ConnectivityMonitor;

class NetworkManager : public QObject
{
    Q_OBJECT
public:
    explicit NetworkManager(ConnectivityMonitor* cm, QObject* parent = nullptr);
    virtual ~NetworkManager() = default;

    enum GetStatus { IDLE, STARTED, FINISHED };
    Q_ENUM(GetStatus)

    enum GetError { DISCONNECTED, NETWORK_ERROR, ACCESS_DENIED, SSL_ERROR, CANCELED };
    Q_ENUM(GetError)

    using DoneCallBack = std::function<void(const QString&)>;
    void get(const QUrl& url, const DoneCallBack& doneCb = {}, const QString& path = {});

    Q_INVOKABLE void cancelRequest();

Q_SIGNALS:
    void statusChanged(GetStatus error);
    void downloadProgressChanged(qint64 bytesRead, qint64 totalBytes);
    void errorOccured(GetError error, const QString& msg = {});

private Q_SLOTS:
    void onSslErrors(QNetworkReply* reply, const QList<QSslError>& errors);
    void onHttpReadyRead();

private:
    void reset(bool flush = true);

    QNetworkAccessManager* manager_;
    QNetworkReply* reply_;
    QScopedPointer<QFile> file_;
    ConnectivityMonitor* connectivityMonitor_;
    bool lastConnectionState_;
};
Q_DECLARE_METATYPE(NetworkManager*)
