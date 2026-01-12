/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

#pragma once

#include "networkmanager.h"
#include "connectivitymonitor.h"
#include "qtutils.h"

#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class FileDownloader : public NetworkManager
{
    Q_OBJECT
    QML_SINGLETON

    QML_PROPERTY(QString, cachePath)

public:
    static FileDownloader* create(QQmlEngine*, QJSEngine*)
    {
        return new FileDownloader(qApp->property("ConnectivityMonitor").value<ConnectivityMonitor*>());
    }

    explicit FileDownloader(ConnectivityMonitor* cm, QObject* parent = nullptr);
    ~FileDownloader() = default;

    // Download an image and call onDownloadFileFinished when done
    Q_INVOKABLE void downloadFile(const QUrl& url, const QString& localPath);

Q_SIGNALS:
    void downloadFileSuccessful(const QString& localPath);
    void downloadFileFailed(const QString& localPath);

private Q_SLOTS:
    // Saves the image to the localPath and emits the appropriate signal
    void onDownloadFileFinished(const QByteArray& reply, const QString& localPath);
};
