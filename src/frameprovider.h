#pragma once

#include "../../daemon/src/jami/videomanager_interface.h"
#include "../../daemon/src/jami/jami.h"

extern "C" {
#include <libavutil/frame.h>
}

#include <QVideoSink>
#include <QVideoFrame>
#include <QQmlEngine>

class FrameManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    FrameManager(QObject* parent = nullptr)
        : QObject(parent)
    {
        using namespace std::placeholders;
        target_.pull = std::bind(&FrameManager::pullCallback, this, _1);
        target_.push = std::bind(&FrameManager::pushCallback, this, _1);

        frameBuffer_ = std::make_unique<DRing::FrameBuffer>();
        frameBuffer_->avframe.reset(av_frame_alloc());

        auto id = DRing::openVideoInput("camera://" + DRing::getDefaultDevice());
        DRing::registerSinkTarget(id, target_);
        DRing::registerSignalHandlers(
            {DRing::exportable_callback<DRing::VideoSignal::DecodingStarted>(
                [this](const std::string& id,
                       const std::string& shmPath,
                       int width,
                       int height,
                       bool isMixer) {
                    videoFrame_.reset(new QVideoFrame(
                        QVideoFrameFormat(QSize(width, height), QVideoFrameFormat::Format_NV12)));
                })});
    }

    Q_INVOKABLE void registerSink(QVideoSink* obj)
    {
        videoSink_.append(obj);
    }

private:
    DRing::SinkTarget::FrameBufferPtr pullCallback(std::size_t bytes)
    {
        if (not frameBuffer_) {
            frameBuffer_.reset(new DRing::FrameBuffer);
            frameBuffer_->avframe.reset(av_frame_alloc());
        }
        if (!videoFrame_->isValid()
            || (!videoFrame_->isMapped() && !videoFrame_->map(QVideoFrame::WriteOnly))) {
            qWarning() << "QVideoFrame can't be mapped";
            return nullptr;
        }
        frameBuffer_->avframe->format = AV_PIX_FMT_NV12;
        frameBuffer_->avframe->width = videoFrame_->width();
        frameBuffer_->avframe->height = videoFrame_->height();
        frameBuffer_->avframe->data[0] = (uint8_t*) videoFrame_->bits(0);
        frameBuffer_->avframe->linesize[0] = videoFrame_->bytesPerLine(0);
        frameBuffer_->avframe->data[1] = (uint8_t*) videoFrame_->bits(1);
        frameBuffer_->avframe->linesize[1] = videoFrame_->bytesPerLine(1);
        //        for (int i = 0; i < videoFrame_->planeCount(); i++) {
        //            frameBuffer_->avframe->data[i] = (uint8_t*) videoFrame_->bits(i);
        //            frameBuffer_->avframe->linesize[i] = videoFrame_->bytesPerLine(i);
        //        }
        return std::move(frameBuffer_);
    };

    void pushCallback(DRing::SinkTarget::FrameBufferPtr buf)
    {
        frameBuffer_ = std::move(buf);
        videoFrame_->unmap();
        Q_FOREACH (const auto& sink, videoSink_) {
            sink->setVideoFrame(*videoFrame_);
            Q_EMIT sink->videoFrameChanged(*videoFrame_);
        }
    };

    DRing::SinkTarget::FrameBufferPtr frameBuffer_;
    DRing::SinkTarget target_;
    QVector<QVideoSink*> videoSink_;
    QScopedPointer<QVideoFrame> videoFrame_;
};
