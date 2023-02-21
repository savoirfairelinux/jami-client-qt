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

using namespace lrc::api;

static bool
mapVideoFrame(QVideoFrame* videoFrame)
{
    if (!videoFrame || !videoFrame->isValid()
        || (!videoFrame->isMapped() && !videoFrame->map(QVideoFrame::WriteOnly))) {
        return false;
    }
    return true;
}

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
VideoProvider::registerSink(const QString& id, QVideoSink* obj)
{
    disconnect(obj);
    connect(obj, &QVideoSink::destroyed, this, [this, id, obj] {
            qWarning() << "DESTROYED" << id  << obj;
            unregisterSink(obj);
        }, Qt::DirectConnection);
    QMutexLocker lk(&framesObjsMutex_);
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        auto fo = std::make_unique<FrameObject>();
        QMutexLocker subsLk(&fo->mutex);
        fo->subscribers.insert(obj);
        qDebug() << "Creating new FrameObject for id:" << id;
        auto emplaced = framesObjects_.emplace(id, std::move(fo));
        if (!emplaced.second) {
            qWarning() << "Couldn't create FrameObject for id:" << id;
            return;
        }
        it = emplaced.first;
    }
    qDebug().noquote() << QString("Adding sink: 0x%1 to subscribers for id: %2")
                              .arg((quintptr) obj, QT_POINTER_SIZE * 2, 16, QChar('0'))
                              .arg(id);
    QMutexLocker subsLk(&it->second->mutex);
    it->second->subscribers.insert(obj);
}

void
VideoProvider::unregisterSink(QVideoSink* obj)
{
    QMutexLocker lk(&framesObjsMutex_);
    for (auto& frameObjIt : qAsConst(framesObjects_)) {
        QMutexLocker subsLk(&frameObjIt.second->mutex);
        auto& subs = frameObjIt.second->subscribers;
        auto it = subs.constFind(obj);
        if (it != subs.cend()) {
            qDebug().noquote() << QString("Removing sink: 0x%1 from subscribers for id: %2")
                                      .arg((quintptr) obj, QT_POINTER_SIZE * 2, 16, QChar('0'))
                                      .arg(frameObjIt.first);
            subs.erase(it);
            return;
        }
    }
}

QVideoFrame*
VideoProvider::frame(const QString& id)
{
    // framesObjsMutex_ MUST be locked
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return {};
    }
    QMutexLocker lk(&it->second->mutex);
    if (it->second->subscribers.empty()) {
        return {};
    }
    auto videoFrame = it->second->videoFrame.get();
    if (!mapVideoFrame(videoFrame)) {
        qWarning() << "QVideoFrame can't be mapped" << id;
        return {};
    }
    return videoFrame;
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
    QMutexLocker framesLk(&framesObjsMutex_);
    if (auto* videoFrame = frame(id)) {
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
        QMutexLocker lk(&framesObjsMutex_);
        auto it = framesObjects_.find(id);
        if (it == framesObjects_.end()) {
            auto fo = std::make_unique<FrameObject>();
            fo->videoFrame = std::make_unique<QVideoFrame>(frameFormat);
            qDebug() << "Create new QVideoFrame" << frameFormat.frameSize();
            framesObjects_.emplace(id, std::move(fo));
        } else {
            it->second->videoFrame.reset(new QVideoFrame(frameFormat));
            qDebug() << "QVideoFrame reset to" << frameFormat.frameSize();
        }
    }

    activeRenderers_[id] = size;
    Q_EMIT activeRenderersChanged();
}

void
VideoProvider::onFrameBufferRequested(const QString& id, AVFrame* avframe)
{
    QMutexLocker framesLk(&framesObjsMutex_);
    if (auto* videoFrame = frame(id)) {
        // The ownership of avframe structure remains the subscriber(jamid), and
        // the videoFrame instance is owned by the VideoProvider(client). The
        // avframe structure contains only a description of the QVideoFrame
        // underlying buffer.
        // TODO: ideally, the colorspace format should likely come from jamid and
        // be the decoded format.
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
    QMutexLocker framesLk(&framesObjsMutex_);
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return;
    }
    QMutexLocker lk(&it->second->mutex);
    if (it->second->subscribers.empty()) {
        return;
    }
    auto videoFrame = it->second->videoFrame.get();
    if (videoFrame == nullptr) {
        qWarning() << "QVideoFrame has not been initialized.";
        return;
    }
    if (!avModel_.useDirectRenderer()) {
        // Shared memory renderering.
        if (!mapVideoFrame(videoFrame)) {
            qWarning() << "QVideoFrame can't be mapped" << id;
            return;
        }
        auto srcFrame = avModel_.getRendererFrame(id);
        if (srcFrame.ptr != nullptr and srcFrame.size > 0) {
            copyUnaligned(videoFrame, srcFrame);
        }
    }
    if (videoFrame->isMapped()) {
        videoFrame->unmap();
        // qWarning() << "&&&&&&&&&&&& n-subs" << id << it->second->subscribers.size() << framesObjects_.size();
        for (const auto& sink : qAsConst(it->second->subscribers)) {
            if (!qobject_cast<QVideoSink*>(sink)) continue;
            qWarning() << "&&&&&&&&&&&&" << id << sink << (qobject_cast<QVideoSink*>(sink) != nullptr ? "TRUE" : "FALSE");
            sink->setVideoFrame(*videoFrame);
            Q_EMIT sink->videoFrameChanged(*videoFrame);
        }
    }
}

void
VideoProvider::onRendererStopped(const QString& id)
{
    QMutexLocker framesLk(&framesObjsMutex_);
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return;
    }

    activeRenderers_.remove(id);
    Q_EMIT activeRenderersChanged();

    QMutexLocker lk(&it->second->mutex);
    if (it->second->subscribers.empty()) {
        //lk.unlock();
        framesObjects_.erase(it);
        return;
    }
    it->second->videoFrame.reset();
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
    if (dst->width() * dst->height() * BYTES_PER_PIXEL > src.size) {
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
