/*
 * Copyright (C) 2019 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

#include <QtCore>
#include <QtNetwork>

class NetWorkManager : public QObject
{
    Q_OBJECT
public:
    explicit NetWorkManager(QObject *parent = nullptr);
    ~NetWorkManager();

    /**
     * using qt get request to store the reply in file
     * @param fileUrl - network address
     * @param path - file saving path
     * @param withUI - with download progress bar
     * @param doneCbRequestInFile - done callback
     */
    void getRequestFile(const QUrl &fileUrl,
                        const QString &path,
                        bool withUI,
                        std::function<void(int)> doneCbRequestInFile = {});

    /**
     * using qt get request to return the reply (QString format) in callback
     * @param fileUrl - network address
     * @param path - file saving path
     * @param withUI - with download progress bar
     * @param doneCbRequest - done callback
     */
    void getRequestReply(const QUrl &fileUrl, std::function<void(int, QString)> doneCbRequest = {});

    /*
     * manually abort the current request
     */
    void cancelRequest();

private slots:
    void slotDownloadProgress(qint64 bytesRead, qint64 totalBytes);
    void slotHttpReadyRead();

private:
    void refresh(bool requestInFile);
    void getRequestFileResetStatus(int code,
                                   bool withUI,
                                   std::function<void(int)> doneCbRequestInFile);
    void getRequestReplyResetStatus(const QString &response,
                                    int code,
                                    std::function<void(int, QString)> doneCbRequest);

    QNetworkAccessManager manager_;
    QNetworkReply *reply_;
    QScopedPointer<QFile> file_;
};
