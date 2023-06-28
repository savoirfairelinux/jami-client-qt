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

#include <QMap>
#include <QDir>
#include <QMetaEnum>
#include <QtNetwork>
#include <random>

NetworkManager::NetworkManager(ConnectivityMonitor* cm, QObject* parent)
    : QObject(parent)
    , manager_(new QNetworkAccessManager(this))
    , connectivityMonitor_(cm)
    , lastConnectionState_(cm->isOnline())
{
#if QT_CONFIG(ssl)
    connect(manager_,
            &QNetworkAccessManager::sslErrors,
            this,
            [this](QNetworkReply* reply, const QList<QSslError>& errors) {
                Q_UNUSED(reply);
                Q_FOREACH (const QSslError& error, errors) {
                    qWarning() << Q_FUNC_INFO << error.errorString();
                    Q_EMIT errorOccured(GetError::SSL_ERROR, error.errorString());
                }
            });
#endif
    connect(connectivityMonitor_, &ConnectivityMonitor::connectivityChanged, this, [this] {
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
NetworkManager::sendGetRequest(const QUrl& url,
                               std::function<void(const QByteArray&)> onDoneCallback)
{
    auto reply = manager_->get(QNetworkRequest(url));
    QObject::connect(reply, &QNetworkReply::finished, this, [reply, onDoneCallback, this]() {
        if (reply->error() == QNetworkReply::NoError) {
            onDoneCallback(reply->readAll());
        } else {
            Q_EMIT errorOccured(GetError::NETWORK_ERROR, reply->errorString());
        }
        reply->deleteLater();
    });
}

unsigned int
NetworkManager::downloadFile(const QUrl& url,
                             unsigned int replyId,
                             std::function<void(bool, const QString&)> onDoneCallback,
                             const QString& filePath)
{
    // If there is already a download in progress, return.
    if ((downloadReplies_.value(replyId) != NULL || !(replyId == 0))
        && downloadReplies_[replyId]->isRunning()) {
        qWarning() << Q_FUNC_INFO << "Download already in progress";
        return replyId;
    }

    // Clean up any previous download.
    resetDownload(replyId);

    // If the url is invalid, return.
    if (!url.isValid()) {
        Q_EMIT errorOccured(GetError::NETWORK_ERROR, "Invalid url");
        return 0;
    }

    // If the file path is empty, return.
    if (filePath.isEmpty()) {
        Q_EMIT errorOccured(GetError::NETWORK_ERROR, "Invalid file path");
        return 0;
    }

    // set the id for the request
    std::mt19937 rng(std::random_device {}());
    std::uniform_int_distribution<unsigned int> dist(1, std::numeric_limits<unsigned int>::max());
    unsigned int uuid = dist(rng);

    QDir dir;
    if (!dir.exists(filePath)) {
        dir.mkpath(filePath);
    }

    // Create the file. Return if it cannot be created.
    QFileInfo fileInfo(url.path());
    QString fileName = fileInfo.fileName();
    files_[uuid] = new QFile(filePath + fileName + ".jpl");
    if (!files_[uuid]->open(QIODevice::WriteOnly)) {
        Q_EMIT errorOccured(GetError::ACCESS_DENIED);
        files_.remove(uuid);
        qWarning() << Q_FUNC_INFO << "Could not open file for writing";
        return 0;
    }

    // Start the download.
    QNetworkRequest request(url);

    downloadReplies_[uuid] = manager_->get(request);

    connect(downloadReplies_[uuid], &QNetworkReply::readyRead, this, [=]() {
        if (files_[uuid] && files_[uuid]->isOpen()) {
            files_[uuid]->write(downloadReplies_[uuid]->readAll());
        }
    });

    connect(downloadReplies_[uuid],
            &QNetworkReply::downloadProgress,
            this,
            [=](qint64 bytesReceived, qint64 bytesTotal) {
                Q_EMIT downloadProgressChanged(bytesReceived, bytesTotal);
            });

    connect(downloadReplies_[uuid],
            QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this,
            [this, uuid](QNetworkReply::NetworkError error) {
                downloadReplies_[uuid]->disconnect();
                resetDownload(uuid);
                qWarning() << Q_FUNC_INFO
                           << QMetaEnum::fromType<QNetworkReply::NetworkError>().valueToKey(error);
                Q_EMIT errorOccured(GetError::NETWORK_ERROR);
            });

    connect(downloadReplies_[uuid], &QNetworkReply::finished, this, [this, uuid, onDoneCallback]() {
        bool success = false;
        QString errorMessage;
        if (this->downloadReplies_[uuid]->error() == QNetworkReply::NoError) {
            resetDownload(uuid);
            success = true;
        } else {
            errorMessage = downloadReplies_[uuid]->errorString();
            resetDownload(uuid);
        }
        onDoneCallback(success, errorMessage);
        Q_EMIT downloadFinished(uuid);
    });
    Q_EMIT downloadStarted(uuid);
    return uuid;
}

void
NetworkManager::cancelDownload(unsigned int replyId)
{
    if (downloadReplies_.value(replyId) != NULL) {
        Q_EMIT errorOccured(GetError::CANCELED);
        downloadReplies_[replyId]->abort();
        resetDownload(replyId);
    }
}

void
NetworkManager::resetDownload(unsigned int replyId)
{
    files_.remove(replyId);
    downloadReplies_.remove(replyId);
}
