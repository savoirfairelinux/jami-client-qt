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

    QWriteLocker framesLk(&framesObjsMutex_);
    // Check if we already have a FrameObject for this id.
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        it = framesObjects_.emplace(id, std::make_unique<FrameObject>()).first;
    } else {
        // Make sure it's not already subscribed to this QVideoSink.
        QReadLocker subsLk(&it->second->subscribersMutex);
        if (it->second->subscribers.contains(sink)) {
            qWarning() << Q_FUNC_INFO << "QVideoSink already subscribed to id:" << id;
            return;
        }
    }
    QWriteLocker subsLk(&it->second->subscribersMutex);
    it->second->subscribers.insert(sink);
    qDebug().noquote() << QString("Added sink: 0x%1 to subscribers for id: %2")
                              .arg((quintptr) obj, QT_POINTER_SIZE, 16, QChar('0'))
                              .arg(id);
}

void
VideoProvider::unsubscribe(QObject* obj)
{
    QReadLocker framesLk(&framesObjsMutex_);
    for (auto& frameObjIt : qAsConst(framesObjects_)) {
        QWriteLocker subsLk(&frameObjIt.second->subscribersMutex);
        auto& subs = frameObjIt.second->subscribers;
        auto it = subs.constFind(static_cast<QVideoSink*>(obj));
        if (it != subs.cend()) {
            subs.erase(it);
            qDebug().noquote() << QString("Removed sink: 0x%1 from subscribers for id: %2")
                                      .arg((quintptr) obj, QT_POINTER_SIZE, 16, QChar('0'))
                                      .arg(frameObjIt.first);
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
    QReadLocker framesLk(&framesObjsMutex_);
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return {};
    }

    if (auto* videoFrame = it->second->getMappedFrame(QVideoFrame::ReadOnly)) {
        auto imageFormat = QVideoFrameFormat::imageFormatFromPixelFormat(
            QVideoFrameFormat::Format_RGBA8888);
        auto img = QImage(videoFrame->bits(0),
                          videoFrame->width(),
                          videoFrame->height(),
                          videoFrame->bytesPerLine(0),
                          imageFormat);
        return img;
    }
    return {};
}

void
VideoProvider::onRendererStarted(const QString& id, const QSize& size)
{
    static const auto pixelFormat = avModel_.useDirectRenderer()
                                        ? QVideoFrameFormat::Format_RGBA8888
                                        : QVideoFrameFormat::Format_BGRA8888;
    auto frameFormat = QVideoFrameFormat(size, pixelFormat);
    {
        QWriteLocker lk(&framesObjsMutex_);
        auto it = framesObjects_.find(id);
        if (it == framesObjects_.end()) {
            it = framesObjects_.emplace(id, std::make_unique<FrameObject>()).first;
        }
        it->second->frame1 = QVideoFrame(frameFormat);
        it->second->frame2 = QVideoFrame(frameFormat);
    }
    qDebug() << "FrameObject set to" << frameFormat.frameSize() << id;

    activeRenderers_[id] = size;
    Q_EMIT activeRenderersChanged();
}

void
VideoProvider::onFrameBufferRequested(const QString& id, AVFrame* avframe)
{
    QReadLocker framesLk(&framesObjsMutex_);
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return;
    }

    if (auto* videoFrame = it->second->getMappedFrame(QVideoFrame::WriteOnly)) {
        // The ownership of avframe structure remains the subscriber(jamid), and
        // the videoFrame instance is owned by the VideoProvider(client). The
        // avframe structure contains only a description of the QVideoFrame
        // underlying buffer.
        avframe->format = AV_PIX_FMT_RGBA;
        avframe->width = videoFrame->width();
        avframe->height = videoFrame->height();
        avframe->data[0] = (uint8_t*) videoFrame->bits(0);
        avframe->linesize[0] = videoFrame->bytesPerLine(0);
    }
}

void
VideoProvider::onFrameUpdated(const QString& id)
{
    QReadLocker framesLk(&framesObjsMutex_);
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return;
    }

    QVideoFrame* videoFrame = nullptr;
    if (!avModel_.useDirectRenderer()) { // Shared memory renderering.
        videoFrame = it->second->getMappedFrame(QVideoFrame::WriteOnly);
        if (!videoFrame) {
            return;
        }
        auto srcFrame = avModel_.getRendererFrame(id);
        if (srcFrame.ptr != nullptr and srcFrame.size > 0) {
            copyUnaligned(videoFrame, srcFrame);
        } else {
            return;
        }
    }
    // Swap then get the new readable frame. This is done to avoid to minimize
    // reallocation of the underlying buffer and to avoid manual emitting of
    // QVideoSink::videoFrameUpdated signal, which is done automatically when
    // changing the frame pointer. Previous manual emitting of the signal was
    // queueing superfluous and ill-timed draw events in the QSGRender loop.
    it->second->swapFrames();
    videoFrame = it->second->getFrame(QVideoFrame::ReadOnly);
    if (videoFrame->isMapped()) {
        videoFrame->unmap();
    }
    QReadLocker subsLk(&it->second->subscribersMutex);
    for (const auto& sink : qAsConst(it->second->subscribers)) {
        sink->setVideoFrame(*videoFrame);
    }
}

void
VideoProvider::onRendererStopped(const QString& id)
{
    QWriteLocker framesLk(&framesObjsMutex_);
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return;
    }

    activeRenderers_.remove(id);
    Q_EMIT activeRenderersChanged();

    QWriteLocker subsLk(&it->second->subscribersMutex);
    if (it->second->subscribers.empty()) {
        subsLk.unlock();
        framesObjects_.erase(it);
        return;
    }
    it->second->frame1 = {};
    it->second->frame2 = {};
}

void
VideoProvider::copyUnaligned(QVideoFrame* dst, const video::Frame& src)
{
    // Copy from a frame residing in the shared memory.
    // Frames in shared memory have no specific line alignment
    // (i.e. stride = width), as opposed to QVideoFrame frames,
    // so the copy need to be done accordingly.

    // This helper only handles RGBA and BGRA pixel formats, so the
    // following constraints must apply.
    assert(dst->pixelFormat() == QVideoFrameFormat::Format_RGBA8888
           or dst->pixelFormat() == QVideoFrameFormat::Format_BGRA8888);
    assert(dst->planeCount() == 1);

    const int BYTES_PER_PIXEL = 4;

    // The provided source must be valid.
    assert(src.ptr != nullptr and src.size > 0);
    // The source buffer must be greater or equal to the min required
    // buffer size. The SHM buffer might be slightly larger than the
    // required size due to the 16-byte alignment.
    if (static_cast<unsigned>(dst->width() * dst->height() * BYTES_PER_PIXEL) > src.size) {
        qCritical() << "The size of frame buffer " << src.size << " is smaller than expected "
                    << dst->width() * dst->height() * BYTES_PER_PIXEL;
        return;
    }

    for (int row = 0; row < dst->height(); row++) {
        auto dstPtr = dst->bits(0) + row * dst->bytesPerLine(0);
        auto srcPtr = src.ptr + row * dst->width() * BYTES_PER_PIXEL;
        std::memcpy(dstPtr, srcPtr, dst->width() * BYTES_PER_PIXEL);
    }
}
