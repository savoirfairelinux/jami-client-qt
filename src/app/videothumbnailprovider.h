/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

#include <QCache>
#include <QHash>
#include <QImage>
#include <QObject>
#include <QQuickImageProvider>
#include <QStringList>

class VideoFrameGrabber;

/*
 * Extracts a still image from local video files with Qt Multimedia, one file
 * at a time, and keeps the results in memory until the files change. Like
 * Qt Multimedia, it must be used from the thread it lives in.
 */
class VideoThumbnailer : public QObject
{
    Q_OBJECT

public:
    // Thumbnails are scaled down to fit in a square of this size.
    static constexpr int maxSize = 640;

    explicit VideoThumbnailer(QObject* parent = nullptr);

    // Emits ready() for filePath once its thumbnail is known.
    void request(const QString& filePath);

Q_SIGNALS:
    // The image is null if no frame of the file could be decoded.
    void ready(const QString& filePath, const QImage& image);

private:
    struct Thumbnail
    {
        QString fileVersion;
        QImage image;
    };

    void startNext();
    void onFrameGrabbed(const QString& version, const QImage& frame);

    QStringList pending_;
    QString current_;
    VideoFrameGrabber* grabber_ {nullptr};
    QCache<QString, Thumbnail> cache_;
    // Last version of each file from which no frame could be decoded.
    QHash<QString, QString> failed_;
};

/*
 * Serves "image://videothumbnail/<percent-encoded local file path>".
 */
class VideoThumbnailProvider : public QQuickAsyncImageProvider
{
public:
    VideoThumbnailProvider();
    ~VideoThumbnailProvider() override;

    QQuickImageResponse* requestImageResponse(const QString& id, const QSize& requestedSize) override;

private:
    VideoThumbnailer* thumbnailer_;
};
