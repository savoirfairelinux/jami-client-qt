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

using namespace lrc::api;

VideoProvider::VideoProvider(AVModel& avModel, QObject* parent)
    : QObject(parent)
    , avModel_(avModel)
{
    connect(&avModel_, &AVModel::rendererStarted, this, &VideoProvider::onRendererStarted);
    connect(&avModel_, &AVModel::frameUpdated, this, &VideoProvider::onFrameUpdated);
    connect(&avModel_, &AVModel::rendererStopped, this, &VideoProvider::onRendererStopped);
}

void
VideoProvider::registerSink(const QString& id, QVideoSink* obj)
{
    qVideoSinks_[obj] = id;
}

void
VideoProvider::unregisterSink(QVideoSink* obj)
{
    auto it = qVideoSinks_.find(obj);
    if (it != qVideoSinks_.end()) {
        qVideoSinks_.erase(it);
    }
}

QString
VideoProvider::captureVideoFrame(QVideoSink* obj)
{
    QImage img;
    obj->videoFrame().map(QVideoFrame::ReadOnly);
    QVideoFrame currentFrame = obj->videoFrame();
    auto imageFormat = QVideoFrameFormat::imageFormatFromPixelFormat(
        QVideoFrameFormat::Format_RGBA8888);
    img = QImage(currentFrame.bits(0),
                 currentFrame.width(),
                 currentFrame.height(),
                 currentFrame.bytesPerLine(0),
                 imageFormat);
    currentFrame.unmap();
    return Utils::byteArrayToBase64String(Utils::QImageToByteArray(img));
}

void
VideoProvider::onRendererStarted(const QString& id)
{
    try {
        auto& renderer = avModel_.getRenderer(id);
        auto videoFrame = new QVideoFrame(
            QVideoFrameFormat(renderer.size(), QVideoFrameFormat::Format_RGBA8888));
        qVideoFrames_.emplace(id, videoFrame);
        using namespace video;
        connect(&renderer,
                &Renderer::frameBufferRequested,
                this,
                &VideoProvider::onFrameBufferRequested,
                Qt::DirectConnection);
    } catch (std::out_of_range& e) {
        qWarning() << e.what();
        return;
    }
}

void
VideoProvider::onFrameBufferRequested(const QString& id, AVFrame* avframe)
{
    auto it = qVideoFrames_.find(id);
    if (it == qVideoFrames_.end()) {
        return;
    }
    auto videoFrame = it->second;
    if (!videoFrame->isValid()
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
    auto it = qVideoFrames_.find(id);
    if (it == qVideoFrames_.end()) {
        return;
    }
    auto videoFrame = it->second;
    if (videoFrame->isMapped()) {
        videoFrame->unmap();
    }
    for (const auto& it : qVideoSinks_) {
        if (id == it.second) {
            auto sink = it.first;
            sink->setVideoFrame(*videoFrame);
            Q_EMIT sink->videoFrameChanged(*videoFrame);
        }
    }
}

void
VideoProvider::onRendererStopped(const QString& id)
{
    // A good time to notify registered sinks that no more
    // frames will be published.
    auto it = qVideoFrames_.find(id);
    if (it != qVideoFrames_.end()) {
        qVideoFrames_.erase(it);
    }
}
