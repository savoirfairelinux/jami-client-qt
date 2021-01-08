/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "framewrapper.h"

#include <QtMultimedia/QVideoFrame>

#ifndef COMPILE_ONLY
extern "C" {
#include "libavcodec/avcodec.h"
#include "libavdevice/avdevice.h"
#include "libavformat/avformat.h"
#include "libavutil/frame.h"
#include "libavutil/pixdesc.h"
#include "libswscale/swscale.h"
#include "libavutil/display.h"
#include "libavutil/pixfmt.h"
}
#else
extern "C" {
void av_frame_free(AVFrame** frame);
AVFrame* av_frame_alloc(void);
void av_free(void* ptr);
void sws_freeContext(struct SwsContext* swsContext);
}
#endif

#include <stdexcept>

using namespace lrc::api;

FrameWrapper::FrameWrapper(AVModel& avModel, const QString& id)
    : avModel_(avModel)
    , id_(id)
    , isRendering_(false)
    , avFrame_ {nullptr,
                [](AVFrame* frame) {
                    av_frame_free(&frame);
                }}
    , supportedFormatFrame_ {av_frame_alloc(),
                             [](AVFrame* frame) {
                                 av_frame_free(&frame);
                             }}
    , imgConvertCtx_ {nullptr,
                      [](SwsContext* context) {
                          if (context)
                              sws_freeContext(context);
                      }}
    , convertedFrameBuffer_ {nullptr, [](uint8_t* buffer) {
                                 if (buffer)
                                     av_free(buffer);
                             }}
{}

FrameWrapper::~FrameWrapper()
{
    if (id_ == video::PREVIEW_RENDERER_ID) {
        avModel_.stopPreview();
    }
}

void
FrameWrapper::connectStartRendering()
{
    QObject::disconnect(renderConnections_.started);
    renderConnections_.started = QObject::connect(&avModel_,
                                                  &AVModel::rendererStarted,
                                                  this,
                                                  &FrameWrapper::slotRenderingStarted);
}

bool
FrameWrapper::startRendering()
{
    if (isRendering())
        return true;

    try {
        renderer_ = const_cast<video::Renderer*>(&avModel_.getRenderer(id_));
    } catch (std::out_of_range& e) {
        qWarning() << e.what();
        return false;
    }

    QObject::disconnect(renderConnections_.updated);
    QObject::disconnect(renderConnections_.stopped);

    renderConnections_.updated = QObject::connect(&avModel_,
                                                  &AVModel::frameUpdated,
                                                  this,
                                                  &FrameWrapper::slotFrameUpdated);

    renderConnections_.stopped = QObject::connect(&avModel_,
                                                  &AVModel::rendererStopped,
                                                  this,
                                                  &FrameWrapper::slotRenderingStopped,
                                                  Qt::DirectConnection);

    return true;
}

void
FrameWrapper::stopRendering()
{
    isRendering_ = false;
}

QImage*
FrameWrapper::getFrame()
{
    if (image_.get()) {
        return isRendering_ ? (image_.get()->isNull() ? nullptr : image_.get()) : nullptr;
    }
    return nullptr;
}

AVFrame*
FrameWrapper::getAVFrame()
{
    return avFrame_.release();
}

bool
FrameWrapper::isRendering()
{
    return isRendering_;
}

bool
FrameWrapper::frameMutexTryLock()
{
    return mutex_.tryLock();
}

void
FrameWrapper::frameMutexUnlock()
{
    mutex_.unlock();
}

void
FrameWrapper::slotRenderingStarted(const QString& id)
{
    if (id != id_) {
        return;
    }

    if (!startRendering()) {
        qWarning() << "Couldn't start rendering for id: " << id_;
        return;
    }

    isRendering_ = true;
}

void
FrameWrapper::slotRenderingStopped(const QString& id)
{
    if (id != id_) {
        return;
    }
    isRendering_ = false;

    QObject::disconnect(renderConnections_.updated);

    renderer_ = nullptr;

    {
        QMutexLocker lock(&mutex_);
        image_.reset();
    }

    emit renderingStopped(id);
}

#ifndef COMPILE_ONLY
void
FrameWrapper::slotFrameUpdated(const QString& id)
{
    if (id != id_) {
        return;
    }

    if (!renderer_ || !renderer_->isRendering()) {
        return;
    }

    {
        QMutexLocker lock(&mutex_);

        if (useOldPipline_) {
            frame_ = renderer_->currentFrame();

            unsigned int width = renderer_->size().width();
            unsigned int height = renderer_->size().height();
#ifndef Q_OS_LINUX
            unsigned int size = frame_.storage.size();
            auto imageFormat = QImage::Format_ARGB32_Premultiplied;
#else
            unsigned int size = frame_.size;
            auto imageFormat = QImage::Format_ARGB32;
#endif
            /*
             * If the frame is empty or not the expected size,
             * do nothing and keep the last rendered QImage.
             */
            if (size != 0 && size == width * height * 4) {
#ifndef Q_OS_LINUX
                buffer_ = std::move(frame_.storage);
#else
                buffer_.reserve(size);
                std::move(frame_.ptr, frame_.ptr + size, buffer_.begin());
#endif
                image_.reset(new QImage((uchar*) buffer_.data(), width, height, imageFormat));
            }
            emit frameUpdated(id);
        } else {
            auto avFrame = renderer_->currentAVFrame();

            if (!avFrame || !avFrame->width || !avFrame->height) {
                return;
            }

            AVPixelFormat currentFormat = AVPixelFormat(avFrame->format);
            AVPixelFormat targetFormat = AVPixelFormat::AV_PIX_FMT_YUV420P;

            if (currentFormat == targetFormat || currentFormat == AVPixelFormat::AV_PIX_FMT_YUV422P
                || currentFormat == AVPixelFormat::AV_PIX_FMT_YUV444P
                || currentFormat == AVPixelFormat::AV_PIX_FMT_NV12) {
                avFrame_ = std::move(avFrame);
            } else if (isHardwareAccelFormat(currentFormat)) {
                // TODO: should be handled instead of transferring the frame to main memory
                avFrame_.reset(transferToMainMemory(avFrame.release(), AV_PIX_FMT_NV12));
            } else {
                supportedFormatFrame_.reset(av_frame_alloc());
                int numBytes = avpicture_get_size(targetFormat, avFrame->width, avFrame->height);
                convertedFrameBuffer_.reset((uint8_t*) av_malloc(numBytes * sizeof(uint8_t)));
                avpicture_fill((AVPicture*) (supportedFormatFrame_.get()),
                               convertedFrameBuffer_.get(),
                               targetFormat,
                               avFrame->width,
                               avFrame->height);

                // set up SWS context, which is used to convert the video format
                imgConvertCtx_.reset(sws_getContext(avFrame->width,
                                                    avFrame->height,
                                                    currentFormat,
                                                    avFrame->width,
                                                    avFrame->height,
                                                    targetFormat,
                                                    SWS_BICUBIC,
                                                    NULL,
                                                    NULL,
                                                    NULL));

                // convert the format from YUV to RGB with sws_scale
                sws_scale(imgConvertCtx_.get(),
                          avFrame->data,
                          avFrame->linesize,
                          0,
                          avFrame->height,
                          supportedFormatFrame_->data,
                          supportedFormatFrame_->linesize);
                supportedFormatFrame_->height = avFrame->height;
                supportedFormatFrame_->width = avFrame->width;
                supportedFormatFrame_->format = targetFormat;
                av_frame_copy_props(supportedFormatFrame_.get(), avFrame.get());
                avFrame_.release();
                avFrame_ = std::move(supportedFormatFrame_);
            }
            emit avFrameUpdated(id);
        }
    }
}

AVFrame*
FrameWrapper::transferToMainMemory(AVFrame* frame, int format)
{
    auto desc = av_pix_fmt_desc_get(static_cast<AVPixelFormat>(frame->format));
    if (desc && not(desc->flags & AV_PIX_FMT_FLAG_HWACCEL)) {
        return frame;
    }

    auto frameFromHW = av_frame_alloc();
    frameFromHW->format = format;

    int ret = av_hwframe_transfer_data(frameFromHW, frame, 0);
    if (ret < 0) {
        qDebug() << "Cannot transfer the frame from GPU";

        return frame;
    }

    frameFromHW->pts = frame->pts;
    if (AVFrameSideData* side_data = av_frame_get_side_data(frame, AV_FRAME_DATA_DISPLAYMATRIX))
        av_frame_new_side_data_from_buf(frameFromHW,
                                        AV_FRAME_DATA_DISPLAYMATRIX,
                                        av_buffer_ref(side_data->buf));
    av_frame_free(&frame);

    return frameFromHW;
}

bool
FrameWrapper::isHardwareAccelFormat(AVPixelFormat format)
{
    bool isAccel = false;
    std::vector<AVPixelFormat> formats = {
        AV_PIX_FMT_CUDA,
        AV_PIX_FMT_QSV,
        AV_PIX_FMT_D3D11,
        AV_PIX_FMT_D3D11VA_VLD,
        AV_PIX_FMT_OPENCL,
        AV_PIX_FMT_DXVA2_VLD,
        AV_PIX_FMT_VDPAU,
        AV_PIX_FMT_MMAL,
        AV_PIX_FMT_VAAPI_IDCT,
        AV_PIX_FMT_XVMC,
        AV_PIX_FMT_VIDEOTOOLBOX,
        AV_PIX_FMT_VAAPI_MOCO,
        AV_PIX_FMT_VAAPI_IDCT,
        AV_PIX_FMT_VAAPI_VLD,
    };
    for (AVPixelFormat fmt : formats) {
        isAccel = format == fmt;
        if (isAccel)
            break;
    }
    return isAccel;
}
#else
void
FrameWrapper::slotFrameUpdated(const QString& id)
{}

AVFrame*
FrameWrapper::transferToMainMemory(AVFrame* frame, int format)
{
    return frame;
}

bool
FrameWrapper::isHardwareAccelFormat(AVPixelFormat format)
{
    return false;
}
#endif