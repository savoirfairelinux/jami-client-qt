/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

#include <QPainter>

using namespace lrc::api;

VideoProvider::VideoProvider(AVModel& avModel, QObject* parent)
    : QObject(parent)
    , avModel_(avModel)
{
    connect(&avModel_, &AVModel::rendererStarted, this, &VideoProvider::onRendererStarted);
    connect(&avModel_, &AVModel::rendererStopped, this, &VideoProvider::onRendererStopped);
    connect(&avModel_, &AVModel::frameBufferRequested, this, &VideoProvider::onFrameBufferRequested);
    connect(&avModel_, &AVModel::frameUpdated, this, &VideoProvider::onFrameUpdated);
}

void
VideoProvider::registerSink(const QString& id, QVideoSink* obj)
{
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        auto fo = std::make_unique<FrameObject>();
        fo->subscribers.insert(obj);
        framesObjects_.emplace(id, std::move(fo));
        return;
    }
    it->second->subscribers.insert(obj);
}

void
VideoProvider::unregisterSink(QVideoSink* obj)
{
    for (auto& frameObjIt : qAsConst(framesObjects_)) {
        auto& subs = frameObjIt.second->subscribers;
        auto it = subs.constFind(obj);
        if (it != subs.cend()) {
            subs.erase(it);
        }
    }
}

QString
VideoProvider::captureVideoFrame(QVideoSink* obj)
{
    QImage img;
    QVideoFrame currentFrame = obj->videoFrame();
    FrameObject* frameObj {nullptr};
    for (auto& frameObjIt : qAsConst(framesObjects_)) {
        auto& subs = frameObjIt.second->subscribers;
        auto it = subs.constFind(obj);
        if (it != subs.cend()) {
            frameObj = frameObjIt.second.get();
        }
    }
    if (frameObj) {
        QMutexLocker lk(&frameObj->mutex);
        auto imageFormat = QVideoFrameFormat::imageFormatFromPixelFormat(
            QVideoFrameFormat::Format_RGBA8888);
        img = QImage(currentFrame.bits(0),
                     currentFrame.width(),
                     currentFrame.height(),
                     currentFrame.bytesPerLine(0),
                     imageFormat);
    }
    return Utils::byteArrayToBase64String(Utils::QImageToByteArray(img));
}

void
VideoProvider::onRendererStarted(const QString& id)
{
    try {
        auto size = avModel_.getRendererSize(id);
        auto format = QVideoFrameFormat(size, QVideoFrameFormat::Format_RGBA8888);
        auto it = framesObjects_.find(id);
        if (it == framesObjects_.end()) {
            auto fo = std::make_unique<FrameObject>();
            fo->videoFrame = std::make_unique<QVideoFrame>(format);
            framesObjects_.emplace(id, std::move(fo));
        } else {
            it->second->videoFrame.reset(new QVideoFrame(format));
        }

        activeRenderers_[id] = QVariant::fromValue(true);
        Q_EMIT activeRenderersChanged();

    } catch (std::out_of_range& e) {
        qWarning() << e.what();
        return;
    }
}

void
VideoProvider::onFrameBufferRequested(const QString& id, AVFrame* avframe)
{
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return;
    }
    QMutexLocker lk(&it->second->mutex);
    if (it->second->subscribers.empty()) {
        return;
    }
    auto videoFrame = it->second->videoFrame.get();
    if (!videoFrame || !videoFrame->isValid()
        || (!videoFrame->isMapped() && !videoFrame->map(QVideoFrame::WriteOnly))) {
        qWarning() << "QVideoFrame can't be mapped";
        return;
    }
    avframe->format = AV_PIX_FMT_RGBA;
    avframe->width = videoFrame->width();
    avframe->height = videoFrame->height();
    avframe->data[0] = (uint8_t*) videoFrame->bits(0);
    avframe->linesize[0] = videoFrame->bytesPerLine(0);
}

void
VideoProvider::onFrameUpdated(const QString& id)
{
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return;
    }
    QMutexLocker lk(&it->second->mutex);
    if (it->second->subscribers.empty()) {
        return;
    }
    publishFrame(id, *it->second);
}

void
VideoProvider::onRendererStopped(const QString& id)
{
    auto it = framesObjects_.find(id);
    if (it == framesObjects_.end()) {
        return;
    }

    activeRenderers_.remove(id);
    Q_EMIT activeRenderersChanged();

    QMutexLocker lk(&it->second->mutex);
    if (it->second->subscribers.empty()) {
        lk.unlock();
        framesObjects_.erase(it);
        return;
    }
    it->second->videoFrame.reset();
}

void
VideoProvider::publishFrame(const QString& id, FrameObject& frameObject)
{
    auto videoFrame = frameObject.videoFrame.get();
    if (videoFrame == nullptr) {
        qWarning() << "QVideoFrame has not been initialized.";
        return;
    }
    if (videoFrame->isMapped()) {
        videoFrame->unmap();
    }
    for (const auto& sink : qAsConst(frameObject.subscribers)) {
        sink->setVideoFrame(*videoFrame);
        Q_EMIT sink->videoFrameChanged(*videoFrame);
    }
}
