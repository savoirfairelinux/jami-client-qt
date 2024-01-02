/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

#include "api/avmodel.h"

extern "C" {
#include "libavutil/frame.h"
}

#include <QSet>
#include <QVariantMap>
#include <QVideoSink>
#include <QVideoFrame>
#include <QQmlEngine>
#include <QReadWriteLock>

#include <map>
#include <atomic>

using namespace lrc::api;

class VideoProvider final : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVariantMap activeRenderers READ getActiveRenderers NOTIFY activeRenderersChanged)
public:
    explicit VideoProvider(AVModel& avModel, QObject* parent = nullptr);
    ~VideoProvider() = default;

    Q_INVOKABLE void subscribe(QObject* obj, const QString& id = {});
    Q_INVOKABLE void unsubscribe(QObject* obj);
    Q_INVOKABLE QString captureVideoFrame(const QString& id);
    Q_INVOKABLE QImage captureRawVideoFrame(const QString& id);

    QVariantMap getActiveRenderers();
    Q_SIGNAL void activeRenderersChanged();

private Q_SLOTS:
    void onRendererStarted(const QString& id, const QSize& size);
    void onFrameBufferRequested(const QString& id, AVFrame* avframe);
    void onFrameUpdated(const QString& id);
    void onRendererStopped(const QString& id);

private:
    AVModel& avModel_;
    void copyUnaligned(QVideoFrame& dst, const video::Frame& src);

    struct FrameObject
    {
        QVideoFrame videoFrame;
        QReadWriteLock frameMutex;
        QSet<QVideoSink*> subscribers;
        QReadWriteLock subscribersMutex;
        bool active {false};
    };
    std::map<QString, FrameObject> renderers_;
    QReadWriteLock renderersMutex_;
};
