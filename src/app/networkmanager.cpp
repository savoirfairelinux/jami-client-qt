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
#include <QScopedPointer>

namespace {
NetworkManager::GetError
translateErrorCode(QNetworkReply::NetworkError error)
{
    // From qnetworkreply.h:
    // network layer errors (1-99): / proxy errors (101-199):
    // content errors (201-299): ContentAccessDenied = 201,
    // protocol errors / Server side errors (401-499)
    static auto inRange = [](int value, int min, int max) -> bool {
        return (value >= min && value <= max);
    };
    if (inRange(error, 1, 199))
        return NetworkManager::NETWORK_ERROR;
    if (inRange(error, 201, 201))
        return NetworkManager::ACCESS_DENIED;
    if (inRange(error, 202, 299))
        return NetworkManager::CONTENT_NOT_FOUND;
    return NetworkManager::NETWORK_ERROR;
}

} // namespace

NetworkManager::NetworkManager(ConnectivityMonitor* cm, QObject* parent)
    : QObject(parent)
    , manager_(new QNetworkAccessManager(this))
    , connectivityMonitor_(cm)
    , lastConnectionState_(cm->isOnline())
    , rng_(std::random_device {}())
{
#if QT_CONFIG(ssl)
    QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();
    sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    QSslConfiguration::setDefaultConfiguration(sslConfig);
    connect(manager_,
            &QNetworkAccessManager::sslErrors,
            this,
            [this](QNetworkReply* reply, const QList<QSslError>& errors) {
                Q_UNUSED(reply);
                Q_FOREACH (const QSslError& error, errors) {
                    qWarning() << Q_FUNC_INFO << error.errorString();
                    Q_EMIT errorOccurred(GetError::SSL_ERROR, error.errorString());
                }
            });
#endif
    connect(connectivityMonitor_, &ConnectivityMonitor::connectivityChanged, this, [this] {
        const auto connected = connectivityMonitor_->isOnline();
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
                               std::function<void(const QByteArray&)>&& onDoneCallback)
{
    const QNetworkRequest request = QNetworkRequest(url);
    sendGetRequest(request, std::move(onDoneCallback));
}

void
NetworkManager::sendGetRequest(const QUrl& url,
                               const QMap<QString, QByteArray>& header,
                               std::function<void(const QByteArray&)>&& onDoneCallback)
{
    QNetworkRequest request = QNetworkRequest(url);
    for (auto it = header.begin(); it != header.end(); ++it) {
        request.setRawHeader(QByteArray(it.key().toStdString().c_str(), it.key().size()),
                             it.value());
    }
    sendGetRequest(request, std::move(onDoneCallback));
}

void
NetworkManager::sendGetRequest(const QNetworkRequest& request,
                               std::function<void(const QByteArray&)>&& onDoneCallback)
{
    auto* const reply = manager_->get(request);
    QObject::connect(reply, &QNetworkReply::finished, this, [reply, onDoneCallback, this]() {
        if (reply->error() == QNetworkReply::NoError) {
            onDoneCallback(reply->readAll());
        } else {
            Q_EMIT errorOccurred(GetError::NETWORK_ERROR, reply->errorString());
        }
        reply->deleteLater();
    });
}

int
NetworkManager::downloadFile(const QUrl& url,
                             int replyId,
                             std::function<void(bool, const QString&)>&& onDoneCallback,
                             const QString& filePath,
                             const QString& extension)
{
    // Don't replace the download if there is already a download in progress for this id.
    if (downloadReplies_.contains(replyId) && downloadReplies_.value(replyId)->isRunning()) {
        qWarning() << Q_FUNC_INFO << "Download already in progress";
        return replyId;
    }

    // Clean up any previous download.
    resetDownload(replyId);

    // If the url is invalid, return.
    if (!url.isValid()) {
        Q_EMIT errorOccurred(GetError::NETWORK_ERROR, "Invalid url");
        return 0;
    }

    // If the file path is empty, return.
    if (filePath.isEmpty()) {
        Q_EMIT errorOccurred(GetError::NETWORK_ERROR, "Invalid file path");
        return 0;
    }

    // set the id for the request
    // NOLINTNEXTLINE(misc-const-correctness)
    std::uniform_int_distribution<int> dist(1, std::numeric_limits<int>::max());
    auto uuid = dist(rng_);

    const QDir dir;
    if (!dir.exists(filePath)) {
        dir.mkpath(filePath);
    }

    // Create the file. Return if it cannot be created.
    const QFileInfo fileInfo(url.path());
    const QString fileName = fileInfo.fileName();
    auto& file = files_[uuid];
    file = new QFile(filePath + QDir::separator() + fileName + extension);
    if (!file->open(QIODevice::WriteOnly)) {
        Q_EMIT errorOccurred(GetError::ACCESS_DENIED);
        files_.remove(uuid);
        qWarning() << Q_FUNC_INFO << "Could not open file for writing";
        return 0;
    }

    // Start the download.
    const QNetworkRequest request(url);

    auto* const reply = manager_->get(request);
    downloadReplies_[uuid] = reply;
    connect(reply, &QNetworkReply::readyRead, this, [file, reply]() {
        if (file && file->isOpen()) {
            file->write(reply->readAll());
        }
    });

    connect(reply,
            &QNetworkReply::downloadProgress,
            this,
            [this](qint64 bytesReceived, qint64 bytesTotal) {
                Q_EMIT downloadProgressChanged(bytesReceived, bytesTotal);
            });

    connect(reply,
            QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this,
            [this, uuid, reply](QNetworkReply::NetworkError error) {
                reply->disconnect();
                resetDownload(uuid);
                qWarning() << Q_FUNC_INFO
                           << QMetaEnum::fromType<QNetworkReply::NetworkError>().valueToKey(error);
                Q_EMIT errorOccurred(translateErrorCode(error));
            });

    connect(reply, &QNetworkReply::finished, this, [this, uuid, onDoneCallback, reply, file]() {
        bool success = false;
        file->close();
        reply->deleteLater();
        QString errorMessage;
        if (reply->error() == QNetworkReply::NoError) {
            resetDownload(uuid);
            success = true;
        } else {
            errorMessage = reply->errorString();
            resetDownload(uuid);
        }
        onDoneCallback(success, errorMessage);
        Q_EMIT downloadFinished(uuid);
    });
    Q_EMIT downloadStarted(uuid);
    return uuid;
}

void
NetworkManager::cancelDownload(int replyId)
{
    if (downloadReplies_.value(replyId) != NULL) {
        Q_EMIT errorOccurred(GetError::CANCELED);
        downloadReplies_[replyId]->abort();
        resetDownload(replyId);
    }
}

void
NetworkManager::resetDownload(int replyId)
{
    files_.remove(replyId);
    downloadReplies_.remove(replyId);
}
