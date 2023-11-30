/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "videoprovider.h"
#include "utils.h"

#include <QReadLocker>
#include <QWriteLocker>

using namespace lrc::api;

VideoProvider::VideoProvider(AVModel& avModel, QObject* parent)
    : QObject(parent)
    , avModel_(avModel)
{
    connect(&avModel_,
            &AVModel::rendererStarted,
            this,
            &VideoProvider::onRendererStarted,
            Qt::DirectConnection);
    connect(&avModel_,
            &AVModel::frameBufferRequested,
            this,
            &VideoProvider::onFrameBufferRequested,
            Qt::DirectConnection);
    connect(&avModel_,
            &AVModel::frameUpdated,
            this,
            &VideoProvider::onFrameUpdated,
            Qt::DirectConnection);
    connect(&avModel_,
            &AVModel::rendererStopped,
            this,
            &VideoProvider::onRendererStopped,
            Qt::DirectConnection);
}

void
VideoProvider::subscribe(QObject* obj, const QString& id)
{
    // First remove any previously existing subscription.
    unsubscribe(obj);

    if (id.isEmpty()) {
        return;
    }

    // Make sure we're dealing with a QVideoSink object.
    auto sink = qobject_cast<QVideoSink*>(obj);
    if (sink == nullptr) {
        qWarning() << Q_FUNC_INFO << "Object must be a QVideoSink.";
        return;
    }

    // We need to detect the destruction of the QVideoSink, which is destroyed before
    // it's parent VideoOutput component emits a Component.destruction signal.
    // e.i. If we use: Component.onDestruction: videoProvider.removeSubscription(videoSink),
    // and a frame update occurs, it's possible the QVideoSink is in the process of being,
    // or has already been destroyed.
    connect(sink,
            &QVideoSink::destroyed,
            this,
            &VideoProvider::unsubscribe,
            static_cast<Qt::ConnectionType>(Qt::DirectConnection | Qt::UniqueConnection));

    QWriteLocker lock(&renderersMutex_);
    FrameObject* fo = nullptr;
    // Check if we already have a FrameObject for this id.
    auto it = renderers_.find(id);
    if (it == renderers_.end()) {
        qDebug() << "Creating new FrameObject for id:" << id;
        fo = &renderers_[id];
    } else {
        fo = &it->second;
        // Make sure it's not already subscribed to this QVideoSink.
        if (it->second.subscribers.contains(sink)) {
            qWarning() << Q_FUNC_INFO << "QVideoSink already subscribed to id:" << id;
            return;
        }
    }

    fo->subscribers.insert(sink);
    qDebug().noquote() << QString("Added sink: 0x%1 to subscribers for id: %2")
                              .arg((quintptr) obj, QT_POINTER_SIZE, 16, QChar('0'))
                              .arg(id);
}

void
VideoProvider::unsubscribe(QObject* obj)
{
    QReadLocker lk(&renderersMutex_);
    for (auto& pair : renderers_) {
        QWriteLocker lock(&pair.second.subscribersMutex);
        if (pair.second.subscribers.remove(static_cast<QVideoSink*>(obj))) {
            qDebug().noquote() << QString("Removed sink: 0x%1 from subscribers for id: %2")
                                      .arg((quintptr) obj, QT_POINTER_SIZE, 16, QChar('0'))
                                      .arg(pair.first);
            return;
        }
    }
}

QString
VideoProvider::captureVideoFrame(const QString& id)
{
    auto img = captureRawVideoFrame(id);
    return Utils::byteArrayToBase64String(Utils::QImageToByteArray(img));
}

QImage
VideoProvider::captureRawVideoFrame(const QString& id)
{
    QReadLocker lock(&renderersMutex_);
    QImage img;

    auto it = renderers_.find(id);
    if (it != renderers_.end()) {
        QReadLocker lock(&it->second.frameMutex);
        QVideoFrame& videoFrame = it->second.videoFrame;
        if (videoFrame.map(QVideoFrame::ReadOnly)) {
            auto imageFormat = QVideoFrameFormat::imageFormatFromPixelFormat(
                QVideoFrameFormat::Format_RGBA8888);
            img = QImage(videoFrame.bits(0),
                         videoFrame.width(),
                         videoFrame.height(),
                         videoFrame.bytesPerLine(0),
                         imageFormat);
        }
    }
    return img;
}

void
VideoProvider::onRendererStarted(const QString& id, const QSize& size)
{
    static const auto pixelFormat = avModel_.useDirectRenderer()
                                        ? QVideoFrameFormat::Format_RGBA8888
                                        : QVideoFrameFormat::Format_BGRA8888;
    auto frameFormat = QVideoFrameFormat(size, pixelFormat);

    renderersMutex_.lockForWrite();

    auto it = renderers_.find(id);
    if (it == renderers_.end()) {
        qDebug() << "Create new QVideoFrame" << frameFormat.frameSize();
        FrameObject& fo = renderers_[id];
        fo.videoFrame = QVideoFrame(frameFormat);
        fo.active = true;
    } else {
        it->second.videoFrame = QVideoFrame(frameFormat);
        it->second.active = true;
        qDebug() << "QVideoFrame reset to" << frameFormat.frameSize();
    }

    renderersMutex_.unlock();
    Q_EMIT activeRenderersChanged();
}

void
VideoProvider::onFrameBufferRequested(const QString& id, AVFrame* avframe)
{
    renderersMutex_.lockForRead();

    auto it = renderers_.find(id);
    if (it == renderers_.end()) {
        renderersMutex_.unlock();
        qWarning() << Q_FUNC_INFO << "Can't find renderer for id:" << id;
        return;
    }
    QVideoFrame& videoFrame = it->second.videoFrame;

    it->second.frameMutex.lockForWrite(); // because captureRawVideoFrame() can be called

    // Create a new QVideoFrame with the same format. We don't know when or if the
    // render thread will upload it, so ownership must be transferred to the
    // render thread. This is done in onFrameUpdated for shared memory frames.
    videoFrame = QVideoFrame(videoFrame.surfaceFormat());
    if (!videoFrame.map(QVideoFrame::WriteOnly)) {
        it->second.frameMutex.unlock();
        renderersMutex_.unlock();
        qWarning() << Q_FUNC_INFO << "Can't map QVideoFrame for id:" << id;
        avframe->format = AV_PIX_FMT_NONE;
        return;
    }

    // The ownership of avframe structure remains the subscriber(jamid), and
    // the videoFrame instance is owned by the VideoProvider(client). The
    // avframe structure contains only a description of the QVideoFrame
    // underlying buffer.
    // TODO: ideally, the colorspace format should likely come from jamid and
    // be the decoded format.
    avframe->format = AV_PIX_FMT_RGBA;
    avframe->width = videoFrame.width();
    avframe->height = videoFrame.height();
    avframe->data[0] = (uint8_t*) videoFrame.bits(0);
    avframe->linesize[0] = videoFrame.bytesPerLine(0);
}

void
VideoProvider::onFrameUpdated(const QString& id)
{
    if (avModel_.useDirectRenderer()) {
        auto it = renderers_.find(id);
        if (it == renderers_.end()) {
            qWarning() << Q_FUNC_INFO << "Can't find renderer for id:" << id;
            return;
        }

        QVideoFrame& videoFrame = it->second.videoFrame;
        videoFrame.unmap();
        it->second.frameMutex.unlock(); // locked by onFrameBufferRequested()

        it->second.frameMutex.lockForRead();
        it->second.subscribersMutex.lockForRead();
        for (const auto& sink : std::as_const(it->second.subscribers)) {
            sink->setVideoFrame(videoFrame);
        }
        it->second.subscribersMutex.unlock();
        it->second.frameMutex.unlock();

        renderersMutex_.unlock(); // locked by onFrameBufferRequested()
    } else {
        QReadLocker lock(&renderersMutex_);
        auto it = renderers_.find(id);
        if (it == renderers_.end()) {
            qWarning() << Q_FUNC_INFO << "Can't find renderer for id:" << id;
            return;
        }

        QVideoFrame& videoFrame = it->second.videoFrame;
        it->second.frameMutex.lockForWrite();
        videoFrame = QVideoFrame(videoFrame.surfaceFormat());
        if (!videoFrame.map(QVideoFrame::WriteOnly)) {
            it->second.frameMutex.unlock();
            qWarning() << Q_FUNC_INFO << "Can't map video frame for id:" << id;
            return;
        }

        auto srcFrame = avModel_.getRendererFrame(id);
        if (srcFrame.ptr != nullptr and srcFrame.size > 0) {
            copyUnaligned(videoFrame, srcFrame);
        }

        videoFrame.unmap();
        it->second.frameMutex.unlock();

        it->second.frameMutex.lockForRead();
        it->second.subscribersMutex.lockForRead();
        for (const auto& sink : std::as_const(it->second.subscribers)) {
            sink->setVideoFrame(videoFrame);
        }
        it->second.subscribersMutex.unlock();
        it->second.frameMutex.unlock();
    }
}

void
VideoProvider::onRendererStopped(const QString& id)
{
    renderersMutex_.lockForWrite();

    auto it = renderers_.find(id);
    if (it == renderers_.end()) {
        renderersMutex_.unlock();
        qWarning() << Q_FUNC_INFO << "Can't find renderer for id:" << id;
        return;
    }

    if (it->second.subscribers.isEmpty()) {
        renderers_.erase(id);
        renderersMutex_.unlock();
        Q_EMIT activeRenderersChanged();
        return;
    }

    it->second.frameMutex.lockForWrite();
    it->second.videoFrame = QVideoFrame();
    it->second.active = false;
    it->second.frameMutex.unlock();

    renderersMutex_.unlock();
    Q_EMIT activeRenderersChanged();
}

void
VideoProvider::copyUnaligned(QVideoFrame& dst, const video::Frame& src)
{
    // Copy from a frame residing in the shared memory.
    // Frames in shared memory have no specific line alignment
    // (i.e. stride = width), as opposed to QVideoFrame frames,
    // so the copy need to be done accordingly.

    // This helper only handles RGBA and BGRA pixel formats, so the
    // following constraints must apply.
    assert(dst.pixelFormat() == QVideoFrameFormat::Format_RGBA8888
           or dst.pixelFormat() == QVideoFrameFormat::Format_BGRA8888);
    assert(dst.planeCount() == 1);

    const int BYTES_PER_PIXEL = 4;

    // The provided source must be valid.
    assert(src.ptr != nullptr and src.size > 0);
    // The source buffer must be greater or equal to the min required
    // buffer size. The SHM buffer might be slightly larger than the
    // required size due to the 16-byte alignment.
    if (static_cast<size_t>(dst.width() * dst.height() * BYTES_PER_PIXEL) > src.size) {
        qCritical() << "The size of frame buffer " << src.size << " is smaller than expected "
                    << dst.width() * dst.height() * BYTES_PER_PIXEL;
        return;
    }

    for (int row = 0; row < dst.height(); row++) {
        auto dstPtr = dst.bits(0) + row * dst.bytesPerLine(0);
        auto srcPtr = src.ptr + row * dst.width() * BYTES_PER_PIXEL;
        std::memcpy(dstPtr, srcPtr, dst.width() * BYTES_PER_PIXEL);
    }
}

QVariantMap
VideoProvider::getActiveRenderers()
{
    QVariantMap activeRenderers;
    QReadLocker lk(&renderersMutex_);
    for (auto& r : renderers_) {
        activeRenderers[r.first] = r.second.active;
    }
    return activeRenderers;
}
