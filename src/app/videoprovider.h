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
#include <QReadWriteLock>

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

    struct FrameObject
    {
        QVideoFrame frame1;
        QVideoFrame frame2;
        QReadWriteLock subscribersMutex;
        QSet<QVideoSink*> subscribers;

        // To reliably swap frames, we need to make sure that both frames are
        // mapped WriteOnly. This is QVideoFrame::map is the only way we can
        // sync on the same mutex locked by the render thread when uploading the
        // data. So we map both frames for writing and then swap them.
        bool swapFrames()
        {
            static auto mapForWrite = [](QVideoFrame& frame) -> bool {
                // If the map mode is set to WriteOnly, nothing needs to be done.
                if (frame.mapMode() == QVideoFrame::WriteOnly) {
                    return true;
                }
                // Otherwise, if the frame is mapped, unmap it first (we assume at this
                // point that the map mode is ReadOnly).
                else if (frame.isMapped()) {
                    frame.unmap();
                }
                return frame.map(QVideoFrame::WriteOnly);
            };

            // frame2 is supposed to already be mapped WriteOnly, but lets just make
            // sure both are WriteOnly in case that changes at some point.
            if (!mapForWrite(frame1) || !mapForWrite(frame2)) {
                return false;
            }

            frame1.swap(frame2);
            return true;
        }

        QVideoFrame* getFrame(QVideoFrame::MapMode mode)
        {
            return mode == QVideoFrame::ReadOnly ? &frame1 : &frame2;
        }

        QVideoFrame* getMappedFrame(QVideoFrame::MapMode mode)
        {
            auto frame = getFrame(mode);
            if (!frame || !frame->isValid()) {
                return nullptr;
            }
            if (mode == QVideoFrame::WriteOnly) {
                QReadLocker subsLk(&subscribersMutex);
                if (subscribers.isEmpty()) {
                    return nullptr;
                }
            }
            if (frame->isMapped()) {
                if (frame->mapMode() != mode) {
                    frame->unmap();
                } else {
                    return frame;
                }
            }
            if (frame->map(mode)) {
                return frame;
            }
            return nullptr;
        }
    };
    std::map<QString, std::unique_ptr<FrameObject>> framesObjects_;
    QReadWriteLock framesObjsMutex_;
};
