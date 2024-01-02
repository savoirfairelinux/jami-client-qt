/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "imagedownloader.h"

#include <QDir>
#include <QLockFile>

ImageDownloader::ImageDownloader(ConnectivityMonitor* cm, QObject* parent)
    : NetworkManager(cm, parent)
{}

void
ImageDownloader::downloadImage(const QUrl& url, const QString& localPath)
{
    Utils::oneShotConnect(this, &NetworkManager::errorOccurred, this, [this, localPath]() {
        onDownloadImageFinished({}, localPath);
    });

    sendGetRequest(url, [this, localPath](const QByteArray& imageData) {
        onDownloadImageFinished(imageData, localPath);
    });
}

void
ImageDownloader::onDownloadImageFinished(const QByteArray& data, const QString& localPath)
{
    if (data.isEmpty()) {
        Q_EMIT downloadImageFailed(localPath);
        return;
    }

    // Make sure the parent folders exists.
    const QString dirPath = localPath.left(localPath.lastIndexOf('/'));
    const QDir dir;
    if (!dir.mkpath(dirPath)) {
        qWarning() << Q_FUNC_INFO << "Failed to create directory" << dirPath;
        Q_EMIT downloadImageFailed(localPath);
        return;
    }

    QLockFile lf(localPath + ".lock");
    QFile file(localPath);
    if (lf.lock() && file.open(QIODevice::WriteOnly)) {
        file.write(data);
        file.close();
        Q_EMIT downloadImageSuccessful(localPath);
        return;
    }

    qWarning() << Q_FUNC_INFO << "Failed to write image to" << localPath;
    Q_EMIT downloadImageFailed(localPath);
}
