
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

    enum GetError { DISCONNECTED, NETWORK_ERROR, ACCESS_DENIED, SSL_ERROR, CANCELED };
    Q_ENUM(GetError)

    void sendGetRequest(const QUrl& url, std::function<void(const QByteArray&)> onDoneCallback);

Q_SIGNALS:
    void errorOccured(GetError error, const QString& msg = {});

protected:
    QNetworkAccessManager* manager_;

private:
    ConnectivityMonitor* connectivityMonitor_;
    bool lastConnectionState_;
};
Q_DECLARE_METATYPE(NetworkManager*)
