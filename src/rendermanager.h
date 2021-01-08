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

#include <QImage>
#include <QObject>

extern "C" {
enum AVPixelFormat;
struct AVFrame;
struct SwsContext;
}

class FrameWrapper;
struct RenderConnections;

using namespace lrc::api;

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

    // Set whether to use old pipline
    // @param use
    void useOldPipline(bool use)
    {
        useOldPipline_ = use;
        avModel_.useAVFrame(!useOldPipline_);
    }

    // Check if the preview is active.
    bool isPreviewing();

    // Start capturing and rendering preview frames.
    // @param force if the capture device should be started
    void startPreviewing(bool force = false);

    // Stop capturing.
    void stopPreviewing();

    // Add and connect a distant renderer for a given id
    // to a FrameWrapper object
    // @param id
    void addDistantRenderer(const QString& id);

    // Disconnect and remove a FrameWrapper object connected to a
    // distant renderer for a given id
    // @param id
    void removeDistantRenderer(const QString& id);

    // Get the most recently rendered distant frame for a given id
    // as an AVFrame pointer.
    // @return the rendered preview image
    AVFrame* getAVFrame(const QString& id);

    // Get the most recently rendered preview frame as a QImage (none thread safe).
    // @return the rendered preview image
    QImage* getPreviewFrame();

    // Get the most recently rendered preview AVFrame.
    // @return the rendered preview image
    AVFrame* getPreviewAVFrame();

signals:

    // Emitted when the preview has a new frame ready.
    void previewFrameUpdated();

    // Emitted when the preview has a new frame object for OpenGL ready.
    void previewAvFrameUpdated();

    // Emitted when the preview is stopped.
    void previewRenderingStopped();

    // Emitted when a distant renderer has a new frame ready for a given id.
    void distantFrameUpdated(const QString& id);

    // Emitted when a distant renderer has a new avframe frame ready for a given id.
    void distantAVFrameUpdated(const QString& id);

    // Emitted when a distant renderer is stopped for a given id.
    void distantRenderingStopped(const QString& id);

private:
    // Decide whether to use old video pipline
    bool useOldPipline_ {false};

    // One preview frame.
    std::unique_ptr<FrameWrapper> previewFrameWrapper_;

    // Distant for each call/conf/conversation.
    std::map<QString, std::unique_ptr<FrameWrapper>> distantFrameWrapperMap_;
    std::map<QString, RenderConnections> distantConnectionMap_;

    // Convenience ref to avmodel.
    AVModel& avModel_;
};
