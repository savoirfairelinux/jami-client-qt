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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include "qtutils.h"

#include "api/avmodel.h"

extern "C" {
#include "libavutil/frame.h"
}

#include <QVideoSink>
#include <QVideoFrame>
#include <QQmlEngine>
#include <QMutex>

using namespace lrc::api;

class VideoProvider final : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_PROPERTY(QVariantMap, activeRenderers)
public:
    explicit VideoProvider(AVModel& avModel, QObject* parent = nullptr);
    ~VideoProvider() = default;

    Q_INVOKABLE void subscribe(QObject* obj, const QString& id = {});
    Q_INVOKABLE void unsubscribe(QObject* obj);
    Q_INVOKABLE QString captureVideoFrame(const QString& id);
    Q_INVOKABLE QImage captureRawVideoFrame(const QString& id);

private Q_SLOTS:
    void onRendererStarted(const QString& id, const QSize& size);
    void onFrameBufferRequested(const QString& id, AVFrame* avframe);
    void onFrameUpdated(const QString& id);
    void onRendererStopped(const QString& id);

private:
    void copyUnaligned(QVideoFrame* dst, const video::Frame& src);
    AVModel& avModel_;

    // Use a double buffering to avoid failed reads from the QML renderer thread.
    struct FrameObject
    {
        std::array<std::unique_ptr<QVideoFrame>, 2> videoFrames;
        // Swap the current writable frame with the current readable frame.
        // Change the current writeable frame index.
        void swapFrames()
        {
            QMutexLocker locker(&mutex);
            videoFrames[0].swap(videoFrames[1]);
        }
        // Get a pointer to frame (regardless of its state).
        QVideoFrame* getFrame(QVideoFrame::MapMode mode)
        {
            QMutexLocker locker(&mutex);
            auto idx = mode == QVideoFrame::ReadOnly ? 0 : 1;
            return videoFrames[idx].get();
        }
        // Get a pointer to a mapped frame.
        QVideoFrame* getMappedFrame(QVideoFrame::MapMode mode)
        {
            auto videoFrame = getFrame(mode);
            QMutexLocker locker(&mutex);
            if (!videoFrame || !videoFrame->isValid() || subscribers.isEmpty()) {
                return nullptr;
            }
            if (videoFrame->isMapped() || videoFrame->map(mode)) {
                return videoFrame;
            }
            qWarning() << "Failed to map video frame";
            return nullptr;
        }
        QRecursiveMutex mutex;
        QSet<QVideoSink*> subscribers;
    };
    std::map<QString, std::unique_ptr<FrameObject>> framesObjects_;
    QMutex framesObjsMutex_;
};
