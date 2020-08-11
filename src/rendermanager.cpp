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

#include "rendermanager.h"

#include "lrcinstance.h"
#include <QtConcurrent/QtConcurrent>
#include <QtMultimedia/QVideoFrame>

extern "C" {
#include "libavcodec/avcodec.h"
#include "libavdevice/avdevice.h"
#include "libavformat/avformat.h"
#include "libavutil/frame.h"
#include "libswscale/swscale.h"
#include <libavutil/display.h>
}

#include <stdexcept>

using namespace lrc::api;

FrameWrapper::FrameWrapper(AVModel &avModel, const QString &id)
    : avModel_(avModel)
    , id_(id)
    , isRendering_(false)
    , avFrame_{nullptr, [](AVFrame *frame) { av_frame_free(&frame); }}
    , pFrameCorrectFormat{av_frame_alloc(), [](AVFrame *frame) { av_frame_free(&frame); }}
    , img_convert_ctx{nullptr,
                      [](SwsContext *context) {
                          if (context)
                              sws_freeContext(context);
                      }}
    , convertedFrameBuffer{nullptr, [](uint8_t *buffer) {
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
    try {
        renderer_ = const_cast<video::Renderer *>(&avModel_.getRenderer(id_));
    } catch (std::out_of_range &e) {
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
                                                  &FrameWrapper::slotRenderingStopped);

    return true;
}

QImage *
FrameWrapper::getFrame()
{
    return image_.get();
}

AVFrame *
FrameWrapper::getAVFrame()
{
    return avFrame_.get();
}

bool
FrameWrapper::isRendering()
{
    return isRendering_;
}

void
FrameWrapper::slotRenderingStarted(const QString &id)
{
    if (id != id_) {
        return;
    }

    if (!startRendering()) {
        qWarning() << "Couldn't start rendering for id: " << id_;
        return;
    }

    isRendering_ = true;

    emit renderingStarted(id);
}

void
FrameWrapper::slotFrameUpdated(const QString &id)
{
    if (id != id_) {
        return;
    }

    if (!renderer_ || !renderer_->isRendering()) {
        return;
    }

    {
        QMutexLocker lock(&mutex_);

        bool isToUseOldpipline = false;
        auto avFrame = renderer_->currentAVFrame();
        if (!avFrame || !avFrame->width || !avFrame->height) {
            isToUseOldpipline = true;
        }

        frame_ = renderer_->currentFrame();

        unsigned int width = renderer_->size().width();
        unsigned int height = renderer_->size().height();

        unsigned int size = frame_.storage.size();

        if (isToUseOldpipline) {
            goto OLD_FRAME_PIPLINE;
        }

        AVPixelFormat currentFormat = AVPixelFormat(avFrame->format);
        AVPixelFormat targetFormat = AVPixelFormat::AV_PIX_FMT_YUV420P;

        if (currentFormat == targetFormat || currentFormat == AVPixelFormat::AV_PIX_FMT_YUV422P
            || currentFormat == AVPixelFormat::AV_PIX_FMT_YUV444P
            || currentFormat == AVPixelFormat::AV_PIX_FMT_NV12
            || isHardwareAccelFormat(currentFormat)) {
            avFrame_ = std::move(avFrame);
        } else if (!isHardwareAccelFormat(currentFormat)) {
            pFrameCorrectFormat.reset(av_frame_alloc());
            int numBytes = avpicture_get_size(targetFormat, avFrame->width, avFrame->height);
            convertedFrameBuffer.reset((uint8_t *) av_malloc(numBytes * sizeof(uint8_t)));
            avpicture_fill((AVPicture *) (pFrameCorrectFormat.get()),
                           convertedFrameBuffer.get(),
                           targetFormat,
                           avFrame->width,
                           avFrame->height);

            // set up SWS context, which is used to convert the video format
            img_convert_ctx.reset(sws_getContext(avFrame->width,
                                                 avFrame->height,
                                                 currentFormat,
                                                 avFrame->width,
                                                 avFrame->height,
                                                 targetFormat,
                                                 SWS_BICUBIC,
                                                 NULL,
                                                 NULL,
                                                 NULL));

            //convert the format from YUV to RGB with sws_scale
            sws_scale(img_convert_ctx.get(),
                      avFrame->data,
                      avFrame->linesize,
                      0,
                      avFrame->height,
                      pFrameCorrectFormat->data,
                      pFrameCorrectFormat->linesize);
            pFrameCorrectFormat->height = avFrame->height;
            pFrameCorrectFormat->width = avFrame->width;
            pFrameCorrectFormat->format = targetFormat;
            av_frame_copy_props(pFrameCorrectFormat.get(), avFrame.get());
            avFrame_.release();
            avFrame_ = std::move(pFrameCorrectFormat);
        }

        emit d3dFrameUpdated(id);

    OLD_FRAME_PIPLINE:
        /**
         * If the frame is empty or not the expected size,
         * do nothing and keep the last rendered QImage.
         */
        if (isToUseOldpipline) {
            if (size != 0 && size == width * height * 4) {
                buffer_ = std::move(frame_.storage);
                image_.reset(new QImage((uchar *) buffer_.data(),
                                        width,
                                        height,
                                        QImage::Format_ARGB32_Premultiplied));
            }
            emit frameUpdated(id);
        }
    }
}

void
FrameWrapper::slotRenderingStopped(const QString &id)
{
    if (id != id_) {
        return;
    }

    QObject::disconnect(renderConnections_.updated);
    QObject::disconnect(renderConnections_.stopped);
    renderer_ = nullptr;

    /*
     * The object's QImage pointer is reset before renderingStopped
     * is emitted, allowing the listener to invoke specific behavior
     * like clearing the widget or changing the UI entirely.
     */
    image_.reset();

    isRendering_ = false;

    emit renderingStopped(id);
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

RenderManager::RenderManager(AVModel &avModel)
    : avModel_(avModel)
{
    deviceListSize_ = avModel_.getDevices().size();
    connect(&avModel_, &lrc::api::AVModel::deviceEvent, this, &RenderManager::slotDeviceEvent);

    previewFrameWrapper_ = std::make_unique<FrameWrapper>(avModel_);

    avModel_.useAVFrame(true);

    QObject::connect(previewFrameWrapper_.get(),
                     &FrameWrapper::renderingStarted,
                     [this](const QString &id) {
                         Q_UNUSED(id);
                         emit previewRenderingStarted();
                     });
    QObject::connect(previewFrameWrapper_.get(),
                     &FrameWrapper::frameUpdated,
                     [this](const QString &id) {
                         Q_UNUSED(id);
                         emit previewFrameUpdated();
                     });
    QObject::connect(previewFrameWrapper_.get(),
                     &FrameWrapper::renderingStopped,
                     [this](const QString &id) {
                         Q_UNUSED(id);
                         emit previewRenderingStopped();
                     });
    QObject::connect(previewFrameWrapper_.get(),
                     &FrameWrapper::d3dFrameUpdated,
                     [this](const QString &id) {
                         Q_UNUSED(id);
                         emit previewD3DFrameUpdated();
                     });

    previewFrameWrapper_->connectStartRendering();
}

RenderManager::~RenderManager()
{
    previewFrameWrapper_.reset();

    for (auto &dfw : distantFrameWrapperMap_) {
        dfw.second.reset();
    }
}

bool
RenderManager::isPreviewing()
{
    return previewFrameWrapper_->isRendering();
}

QImage *
RenderManager::getPreviewFrame()
{
    return previewFrameWrapper_->getFrame();
}

AVFrame *
RenderManager::getPreviewAVFrame()
{
    return previewFrameWrapper_->getAVFrame();
}

void
RenderManager::stopPreviewing(bool async)
{
    if (!previewFrameWrapper_->isRendering()) {
        return;
    }

    if (async) {
        QtConcurrent::run([this] { avModel_.stopPreview(); });
    } else {
        avModel_.stopPreview();
    }
}

void
RenderManager::startPreviewing(bool force, bool async)
{
    if (previewFrameWrapper_->isRendering() && !force) {
        return;
    }

    auto restart = [this] {
        if (previewFrameWrapper_->isRendering()) {
            avModel_.stopPreview();
        }
        avModel_.startPreview();
    };
    if (async) {
        QtConcurrent::run(restart);
    } else {
        restart();
    }
}

QImage *
RenderManager::getFrame(const QString &id)
{
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
        return dfwIt->second->getFrame();
    }
    return nullptr;
}

AVFrame *
RenderManager::getAVFrame(const QString &id)
{
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
        return dfwIt->second->getAVFrame();
    }
    return nullptr;
}

void
RenderManager::addDistantRenderer(const QString &id)
{
    /*
     * Check if a FrameWrapper with this id exists.
     */
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
        if (!dfwIt->second->startRendering()) {
            qWarning() << "Couldn't start rendering for id: " << id;
        }
    } else {
        auto dfw = std::make_unique<FrameWrapper>(avModel_, id);

        /*
         * Connect this to the FrameWrapper.
         */
        distantConnectionMap_[id].started = QObject::connect(dfw.get(),
                                                             &FrameWrapper::renderingStarted,
                                                             [this](const QString &id) {
                                                                 emit distantRenderingStarted(id);
                                                             });
        distantConnectionMap_[id].updated = QObject::connect(dfw.get(),
                                                             &FrameWrapper::frameUpdated,
                                                             [this](const QString &id) {
                                                                 emit distantFrameUpdated(id);
                                                             });
        distantConnectionMap_[id].updated = QObject::connect(dfw.get(),
                                                             &FrameWrapper::d3dFrameUpdated,
                                                             [this](const QString &id) {
                                                                 emit d3dDistantFrameUpdated(id);
                                                             });
        distantConnectionMap_[id].stopped = QObject::connect(dfw.get(),
                                                             &FrameWrapper::renderingStopped,
                                                             [this](const QString &id) {
                                                                 emit distantRenderingStopped(id);
                                                             });

        /*
         * Connect FrameWrapper to avmodel.
         */
        dfw->connectStartRendering();

        /*
         * Add to map.
         */
        distantFrameWrapperMap_.insert(std::make_pair(id, std::move(dfw)));
    }
}

void
RenderManager::removeDistantRenderer(const QString &id)
{
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
        /*
         * Disconnect FrameWrapper from this.
         */
        auto dcIt = distantConnectionMap_.find(id);
        if (dcIt != distantConnectionMap_.end()) {
            QObject::disconnect(dcIt->second.started);
            QObject::disconnect(dcIt->second.updated);
            QObject::disconnect(dcIt->second.stopped);
        }

        /*
         * Erase.
         */
        distantFrameWrapperMap_.erase(dfwIt);
    }
}

void
RenderManager::slotDeviceEvent()
{
    auto defaultDevice = avModel_.getDefaultDevice();
    auto currentCaptureDevice = avModel_.getCurrentVideoCaptureDevice();
    /*
     * Decide whether a device has plugged, unplugged, or nothing has changed.
     */
    auto deviceList = avModel_.getDevices();
    auto currentDeviceListSize = deviceList.size();

    DeviceEvent deviceEvent{DeviceEvent::None};
    if (currentDeviceListSize > deviceListSize_) {
        deviceEvent = DeviceEvent::Added;
    } else if (currentDeviceListSize < deviceListSize_) {
        /*
         * Check if the currentCaptureDevice is still in the device list.
         */
        if (std::find(std::begin(deviceList), std::end(deviceList), currentCaptureDevice)
            == std::end(deviceList)) {
            deviceEvent = DeviceEvent::RemovedCurrent;
        }
    }

    if (previewFrameWrapper_->isRendering()) {
        if (currentDeviceListSize == 0) {
            avModel_.clearCurrentVideoCaptureDevice();
            avModel_.switchInputTo({});
            stopPreviewing();
        } else if (deviceEvent == DeviceEvent::RemovedCurrent && currentDeviceListSize > 0) {
            avModel_.setCurrentVideoCaptureDevice(defaultDevice);
            startPreviewing(true);
        } else {
            startPreviewing();
        }
    } else if (deviceEvent == DeviceEvent::Added && currentDeviceListSize == 1) {
        avModel_.setCurrentVideoCaptureDevice(defaultDevice);
    }

    emit videoDeviceListChanged();

    deviceListSize_ = currentDeviceListSize;
}
