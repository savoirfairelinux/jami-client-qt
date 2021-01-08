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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include "api/avmodel.h"
#include "api/lrc.h"

#include <libavutil/pixfmt.h>

#include <QImage>
#include <QMutex>
#include <QObject>

extern "C" {
struct AVFrame;
struct SwsContext;
}

using namespace lrc::api;

/*
 * This class acts as a QImage / AVFrame rendering sink depending on
 * whether to use old video pipeline and manages
 * signal/slot connections to it's underlying (AVModel) renderer
 * corresponding to the object's renderer id.
 * A QImage / AVFrame pointer is provisioned and updated once rendering
 * starts.
 */

struct RenderConnections
{
    QMetaObject::Connection started, stopped, updated;
};

class FrameWrapper final : public QObject
{
    Q_OBJECT;

public:
    FrameWrapper(AVModel& avModel, const QString& id = video::PREVIEW_RENDERER_ID);
    ~FrameWrapper();

    /*
     * Reconnect the started rendering connection for this object.
     */
    void connectStartRendering();

    /*
     * Get a pointer to the renderer and reconnect the update/stopped
     * rendering connections for this object.
     * @return whether the start succeeded or not
     */
    bool startRendering();

    /*
     * Locally disable frame access to this FrameWrapper
     */
    void stopRendering();

    /*
     * Get the most recently rendered frame as a QImage.
     * @return the rendered image of this object's id
     */
    QImage* getFrame();

    /*
     * Get the most recently rendered AVFrame.
     * @return the rendered image of this object's id
     */
    AVFrame* getAVFrame();

    /*
     * Check if the object is updating actively.
     */
    bool isRendering();

    bool frameMutexTryLock();

    void frameMutexUnlock();

    /*
     * Set whether to use old pipline
     * @param use
     */
    void useOldPipline(bool use)
    {
        useOldPipline_ = use;
    }

signals:
    /*
     * Emitted each time a frame is ready to be displayed.
     * @param id of the renderer
     */
    void frameUpdated(const QString& id);
    /*
     * Emitted each time an av frame is ready to be displayed.
     * @param id of the renderer
     */
    void avFrameUpdated(const QString& id);
    /*
     * Emitted once in slotRenderingStopped.
     * @param id of the renderer
     */
    void renderingStopped(const QString& id);

public slots:
    /*
     * Used to listen to AVModel::rendererStarted.
     * @param id of the renderer
     */
    void slotRenderingStarted(const QString& id = video::PREVIEW_RENDERER_ID);
    /*
     * Used to listen to AVModel::frameUpdated.
     * @param id of the renderer
     */
    void slotFrameUpdated(const QString& id = video::PREVIEW_RENDERER_ID);
    /*
     * Used to listen to AVModel::renderingStopped.
     * @param id of the renderer
     */
    void slotRenderingStopped(const QString& id = video::PREVIEW_RENDERER_ID);

private:
    bool isHardwareAccelFormat(AVPixelFormat format);
    AVFrame* transferToMainMemory(AVFrame* frame, int format);

    /*
     * Decide whether to use old video pipline
     */
    bool useOldPipline_ {false};

    /*
     * The id of the renderer.
     */
    QString id_;

    /*
     * A pointer to the lrc renderer object.
     */
    video::Renderer* renderer_;

    /*
     * A local copy of the renderer's current frame.
     */
    video::Frame frame_;

    /*
     * A local copy of the renderer's current avframe.
     */
    std::unique_ptr<AVFrame, void (*)(AVFrame*)> avFrame_;

    /*
     * A the frame's storage data used to set the image.
     */
    std::vector<uint8_t> buffer_;

    /*
     * The frame's paint ready QImage.
     */
    std::unique_ptr<QImage> image_;

    /*
     * Used to protect the buffer during QImage creation routine.
     */
    QMutex mutex_;

    /*
     * True if the object is rendering
     */
    std::atomic_bool isRendering_;

    /*
     * Convenience ref to avmodel
     */
    AVModel& avModel_;

    /*
     * Connections to the underlying renderer signals in avmodel
     */
    RenderConnections renderConnections_;

    /*
     * Temporary variables for converting frame by using SWS
     */
    std::unique_ptr<AVFrame, void (*)(AVFrame*)> supportedFormatFrame_;
    std::unique_ptr<SwsContext, void (*)(SwsContext*)> imgConvertCtx_;
    std::unique_ptr<uint8_t, void (*)(uint8_t*)> convertedFrameBuffer_;
};

/**
 * RenderManager filters signals and ecapsulates preview and distant
 * frame wrappers. Depending on whether to use old video pipeline,
 * it provides access to QImages or moved AVFrames for each and simplified
 * start/stop mechanisms for renderers depending on whether to use old video pipeline.
 * It should contain as much renderer control logic as possible and prevent
 * ui widgets from directly interfacing the rendering logic.
 */
class RenderManager final : public QObject
{
    Q_OBJECT;

public:
    explicit RenderManager(AVModel& avModel);
    ~RenderManager();

    using DrawFrameCallback = std::function<void(QImage*)>;

    /*
     * Set whether to use old pipline
     * @param use
     */
    void useOldPipline(bool use)
    {
        useOldPipline_ = use;
        avModel_.useAVFrame(!useOldPipline_);
    }

    /*
     * Check if the preview is active.
     */
    bool isPreviewing();
    /*
     * Start capturing and rendering preview frames.
     * @param force if the capture device should be started
     */
    void startPreviewing(bool force = false);
    /*
     * Stop capturing.
     */
    void stopPreviewing();
    /*
     * Add and connect a distant renderer for a given id
     * to a FrameWrapper object
     * @param id
     */
    void addDistantRenderer(const QString& id);
    /*
     * Disconnect and remove a FrameWrapper object connected to a
     * distant renderer for a given id
     * @param id
     */
    void removeDistantRenderer(const QString& id);

    /*
     * Get the most recently rendered distant frame for a given id
     * as an AVFrame pointer.
     * @return the rendered preview image
     */
    AVFrame* getAVFrame(const QString& id);

    /*
     * Get the most recently rendered preview frame as a QImage (none thread safe).
     * @return the rendered preview image
     */
    QImage* getPreviewFrame();

    /*
     * Get the most recently rendered preview AVFrame.
     * @return the rendered preview image
     */
    AVFrame* getPreviewAVFrame();

signals:

    /*
     * Emitted when the preview has a new frame ready.
     */
    void previewFrameUpdated();

    /*
     * Emitted when the preview has a new frame object for OpenGL ready.
     */
    void previewAvFrameUpdated();

    /*
     * Emitted when the preview is stopped.
     */
    void previewRenderingStopped();

    /*
     * Emitted when a distant renderer has a new frame ready for a given id.
     */
    void distantFrameUpdated(const QString& id);

    /*
     * Emitted when a distant renderer has a new avframe frame ready for a given id.
     */
    void distantAVFrameUpdated(const QString& id);

    /*
     * Emitted when a distant renderer is stopped for a given id.
     */
    void distantRenderingStopped(const QString& id);

private:
    /*
     * Decide whether to use old video pipline
     */
    bool useOldPipline_ {false};

    /*
     * One preview frame.
     */
    std::unique_ptr<FrameWrapper> previewFrameWrapper_;

    /*
     * Distant for each call/conf/conversation.
     */
    std::map<QString, std::unique_ptr<FrameWrapper>> distantFrameWrapperMap_;
    std::map<QString, RenderConnections> distantConnectionMap_;

    /*
     * Convenience ref to avmodel.
     */
    AVModel& avModel_;
};
