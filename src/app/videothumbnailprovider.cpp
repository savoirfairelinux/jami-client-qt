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

#include "videothumbnailprovider.h"

#include <QDateTime>
#include <QFileInfo>
#include <QMediaPlayer>
#include <QTimer>
#include <QUrl>
#include <QVideoFrame>
#include <QVideoSink>

#include <algorithm>
#include <functional>
#include <utility>

namespace {

// Memory available to the cached thumbnails, in KiB.
constexpr int cacheCapacityKiB = 64 * 1024;
// Files that do not present a frame within this delay are given up on.
constexpr int grabTimeoutMs = 10000;
// Average luminance, out of 255, under which a frame is deemed black.
constexpr int blackFrameLuminance = 16;
// Furthest position looked at when the first frame is black.
constexpr qint64 maxSeekMs = 3000;

// Identifies a version of a file, so that a file that appears or changes is
// looked at again.
QString
cacheKey(const QString& filePath)
{
    const QFileInfo fileInfo(filePath);
    const auto modified = fileInfo.exists() ? QString::number(fileInfo.lastModified().toMSecsSinceEpoch()) : QString();
    return filePath + QLatin1Char('\n') + modified;
}

bool
isMostlyBlack(const QImage& image)
{
    const auto sample = image.scaled(16, 16, Qt::IgnoreAspectRatio, Qt::FastTransformation)
                            .convertToFormat(QImage::Format_Grayscale8);
    int sum = 0;
    for (int y = 0; y < sample.height(); ++y) {
        const auto* line = sample.constScanLine(y);
        for (int x = 0; x < sample.width(); ++x)
            sum += line[x];
    }
    return sum < blackFrameLuminance * sample.width() * sample.height();
}

class VideoThumbnailResponse : public QQuickImageResponse
{
public:
    VideoThumbnailResponse(VideoThumbnailer* thumbnailer, const QString& filePath)
    {
        connect(thumbnailer, &VideoThumbnailer::ready, this, [this, filePath](const QString& path, const QImage& image) {
            if (path != filePath || done_)
                return;
            done_ = true;
            image_ = image;
            Q_EMIT finished();
        });
        // Queued so that the response is complete before it can be answered.
        QMetaObject::invokeMethod(
            thumbnailer, [thumbnailer, filePath] { thumbnailer->request(filePath); }, Qt::QueuedConnection);
    }

    QQuickTextureFactory* textureFactory() const override
    {
        return QQuickTextureFactory::textureFactoryForImage(image_);
    }

    QString errorString() const override
    {
        return done_ && image_.isNull() ? QStringLiteral("No frame could be decoded from the video") : QString();
    }

private:
    QImage image_;
    bool done_ {false};
};

} // namespace

/*
 * Decodes the first frame of a video file, or a later one when the first is
 * black as in a fade-in, and reports it once.
 */
class VideoFrameGrabber : public QObject
{
public:
    VideoFrameGrabber(std::function<void(const QImage&)> onGrabbed, QObject* parent)
        : QObject(parent)
        , onGrabbed_(std::move(onGrabbed))
    {
        player_.setVideoSink(&sink_);
        connect(&player_, &QMediaPlayer::mediaStatusChanged, this, &VideoFrameGrabber::onMediaStatusChanged);
        connect(&player_, &QMediaPlayer::errorOccurred, this, [this] { report(firstFrame_); });
        connect(&sink_, &QVideoSink::videoFrameChanged, this, &VideoFrameGrabber::onVideoFrameChanged);
        timeout_.setSingleShot(true);
        connect(&timeout_, &QTimer::timeout, this, [this] { report(firstFrame_); });
    }

    // Some backends may report a failure before this returns.
    void start(const QString& filePath)
    {
        timeout_.start(grabTimeoutMs);
        player_.setSource(QUrl::fromLocalFile(filePath));
    }

private:
    void onMediaStatusChanged(QMediaPlayer::MediaStatus status)
    {
        if (!onGrabbed_)
            return;
        switch (status) {
        case QMediaPlayer::LoadedMedia:
            // Pausing presents the current frame without playing the media.
            if (player_.hasVideo())
                player_.pause();
            else
                report({});
            break;
        case QMediaPlayer::InvalidMedia:
        case QMediaPlayer::EndOfMedia:
            report(firstFrame_);
            break;
        default:
            break;
        }
    }

    void onVideoFrameChanged(const QVideoFrame& frame)
    {
        if (!onGrabbed_ || !frame.isValid())
            return;
        auto image = frame.toImage();
        if (image.isNull())
            return;
        if (firstFrame_.isNull() && isMostlyBlack(image) && player_.duration() > 0) {
            firstFrame_ = std::move(image);
            player_.setPosition(std::min(player_.duration() / 3, maxSeekMs));
            return;
        }
        report(image);
    }

    void report(const QImage& image)
    {
        if (!onGrabbed_)
            return;
        timeout_.stop();
        std::exchange(onGrabbed_, nullptr)(image);
    }

    QVideoSink sink_;
    QMediaPlayer player_;
    QTimer timeout_;
    QImage firstFrame_;
    std::function<void(const QImage&)> onGrabbed_;
};

VideoThumbnailer::VideoThumbnailer(QObject* parent)
    : QObject(parent)
{
    cache_.setMaxCost(cacheCapacityKiB);
}

void
VideoThumbnailer::request(const QString& filePath)
{
    const auto key = cacheKey(filePath);
    if (const auto* thumbnail = cache_.object(key)) {
        Q_EMIT ready(filePath, *thumbnail);
        return;
    }
    if (failed_.contains(key)) {
        Q_EMIT ready(filePath, {});
        return;
    }
    if (filePath != current_ && !pending_.contains(filePath))
        pending_.append(filePath);
    startNext();
}

void
VideoThumbnailer::startNext()
{
    if (grabber_ || pending_.isEmpty())
        return;
    current_ = pending_.takeFirst();
    const auto key = cacheKey(current_);
    grabber_ = new VideoFrameGrabber([this, key](const QImage& frame) { onFrameGrabbed(key, frame); }, this);
    grabber_->start(current_);
}

void
VideoThumbnailer::onFrameGrabbed(const QString& key, const QImage& frame)
{
    std::exchange(grabber_, nullptr)->deleteLater();
    const auto filePath = std::exchange(current_, {});
    QImage thumbnail;
    if (frame.isNull()) {
        failed_.insert(key);
    } else {
        thumbnail = frame.width() > maxSize || frame.height() > maxSize
                        ? frame.scaled(maxSize, maxSize, Qt::KeepAspectRatio, Qt::SmoothTransformation)
                        : frame;
        cache_.insert(key, new QImage(thumbnail), thumbnail.sizeInBytes() / 1024);
    }
    Q_EMIT ready(filePath, thumbnail);
    QMetaObject::invokeMethod(this, &VideoThumbnailer::startNext, Qt::QueuedConnection);
}

VideoThumbnailProvider::VideoThumbnailProvider()
    : thumbnailer_(new VideoThumbnailer)
{}

VideoThumbnailProvider::~VideoThumbnailProvider()
{
    // Image responses keep the provider alive, so it may be released from a
    // QML image loading thread rather than from the thumbnailer's.
    thumbnailer_->deleteLater();
}

QQuickImageResponse*
VideoThumbnailProvider::requestImageResponse(const QString& id, const QSize& requestedSize)
{
    Q_UNUSED(requestedSize)
    return new VideoThumbnailResponse(thumbnailer_, QUrl::fromPercentEncoding(id.toUtf8()));
}
