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
    QObject::connect(reply, &QNetworkReply::finished, this, [reply, onDoneCallback]() {
        if (reply->error() == QNetworkReply::NoError) {
            onDoneCallback(reply->readAll());
        } else {
            onDoneCallback(reply->errorString().toUtf8());
        }
        reply->deleteLater();
    });
}

void
NetworkManager::download(const QUrl& url,
                         std::function<void(bool, const QString&)> onDoneCallback,
                         const QString& filePath)
{
    // If there is already a download in progress, return.
    if (downloadStatus_ && downloadStatus_->isRunning()) {
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
    downloadStatus_ = manager_->get(request);

    connect(downloadStatus_, &QNetworkReply::readyRead, this, [=]() {
        if (file_ && file_->isOpen()) {
            file_->write(downloadStatus_->readAll());
        }
    });

    connect(downloadStatus_,
            QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this,
            [this](QNetworkReply::NetworkError error) {
                downloadStatus_->disconnect();
                resetDownload();
                qWarning() << Q_FUNC_INFO
                           << QMetaEnum::fromType<QNetworkReply::NetworkError>().valueToKey(error);
                Q_EMIT errorOccured(GetError::NETWORK_ERROR);
            });

    connect(downloadStatus_, &QNetworkReply::finished, this, [this, onDoneCallback]() {
        bool success = false;
        QString errorMessage;
        if (downloadStatus_->error() == QNetworkReply::NoError) {
            resetDownload();
            success = true;
        } else {
            errorMessage = downloadStatus_->errorString();
            resetDownload();
        }
        onDoneCallback(success, errorMessage);
    });
}

void
NetworkManager::resetDownload()
{
    if (downloadStatus_) {
        downloadStatus_->deleteLater();
        downloadStatus_ = nullptr;
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
