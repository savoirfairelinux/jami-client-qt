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

#include "networkmanager.h"

#include "connectivitymonitor.h"

#include <QMetaEnum>
#include <QtNetwork>

NetworkManager::NetworkManager(ConnectivityMonitor* cm, QObject* parent)
    : QObject(parent)
    , manager_(new QNetworkAccessManager(this))
    , reply_(nullptr)
    , connectivityMonitor_(cm)
    , lastConnectionState_(cm->isOnline())
{
#if QT_CONFIG(ssl)
    connect(manager_, &QNetworkAccessManager::sslErrors, this, &NetworkManager::onSslErrors);
#endif
    connect(connectivityMonitor_, &ConnectivityMonitor::connectivityChanged, this, [this] {
        cancelRequest();
        auto connected = connectivityMonitor_->isOnline();
        if (connected && !lastConnectionState_) {
            manager_->deleteLater();
            manager_ = new QNetworkAccessManager(this);
            qWarning() << "connectivity changed, reset QNetworkAccessManager";
        }
        lastConnectionState_ = connected;
    });
}

void
NetworkManager::get(const QUrl& url, const DoneCallBack& doneCb, const QString& path)
{
    //    if (!connectivityMonitor_->isOnline()) {
    //        Q_EMIT errorOccured(GetError::DISCONNECTED);
    //        return;
    //    }

    reset();

    if (!url.isValid()) {
        Q_EMIT errorOccured(GetError::NETWORK_ERROR, "Invalid url");
        return;
    }

    if (!path.isEmpty()) {
        QFileInfo fileInfo(url.path());
        QString fileName = fileInfo.fileName();
        file_.reset(new QFile(path + "/" + fileName));
        if (!file_->open(QIODevice::WriteOnly)) {
            Q_EMIT errorOccured(GetError::ACCESS_DENIED);
            file_.reset(nullptr);
            return;
        }
    }

    reply_ = manager_->get(QNetworkRequest(url));

    connect(reply_,
            QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this,
            [this, doneCb, path](QNetworkReply::NetworkError error) {
                reply_->disconnect();
                reset(true);
                qWarning() << Q_FUNC_INFO
                           << QMetaEnum::fromType<QNetworkReply::NetworkError>().valueToKey(error);
                Q_EMIT errorOccured(GetError::NETWORK_ERROR);
            });

    connect(reply_, &QNetworkReply::finished, this, [this, doneCb, path]() {
        qWarning() << Q_FUNC_INFO;
        reply_->disconnect();
        QString response = {};
        if (path.isEmpty())
            response = QString(reply_->readAll());
        reset(!path.isEmpty());
        Q_EMIT statusChanged(GetStatus::FINISHED);
        if (doneCb)
            doneCb(response);
    });

    connect(reply_,
            &QNetworkReply::downloadProgress,
            this,
            &NetworkManager::downloadProgressChanged);

    connect(reply_, &QNetworkReply::readyRead, this, &NetworkManager::onHttpReadyRead);

    Q_EMIT statusChanged(GetStatus::STARTED);
}

void
NetworkManager::reset(bool flush)
{
    if (reply_) {
        reply_->deleteLater();
        reply_ = nullptr;
    }
    if (file_) {
        if (flush) {
            file_->flush();
        }
        file_->deleteLater();
        file_.reset();
    }
}

void
NetworkManager::onSslErrors(QNetworkReply* reply, const QList<QSslError>& errors)
{
    Q_UNUSED(reply);
#if QT_CONFIG(ssl)
    Q_FOREACH (const QSslError& error, errors) {
        qDebug() << "SSL error:" << error.errorString();
        Q_EMIT errorOccured(GetError::SSL_ERROR, error.errorString());
    }
#else
    Q_UNUSED(sslErrors);
#endif
}

void
NetworkManager::onHttpReadyRead()
{
    /*
     * This slot gets called every time the QNetworkReply has new data.
     * We read all of its new data and write it into the file.
     * That way we use less RAM than when reading it at the finished()
     * signal of the QNetworkReply
     */
    if (file_)
        file_->write(reply_->readAll());
}

void
NetworkManager::cancelRequest()
{
    if (reply_) {
        reply_->abort();
        reset();
        Q_EMIT errorOccured(GetError::CANCELED);
    }
}
