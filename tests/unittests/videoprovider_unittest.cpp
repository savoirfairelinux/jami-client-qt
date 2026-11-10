/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

#include "globaltestenvironment.h"

#include "videoprovider.h"

extern "C" {
#include "libavutil/frame.h"
}

#include <QCoreApplication>
#include <QSignalSpy>
#include <QSize>
#include <QString>
#include <QThread>
#include <QVideoSink>

#include <thread>

/*!
 * Simulates the daemon pushing a frame for the renderer id from a non-GUI
 * thread, following the same signal sequence as the real renderers.
 */
static void
pushFrameFromWorkerThread(AVModel& avModel, const QString& id)
{
    std::thread producer([&avModel, id] {
        if (avModel.useDirectRenderer()) {
            AVFrame* frame = av_frame_alloc();
            Q_EMIT avModel.frameBufferRequested(id, frame);
            Q_EMIT avModel.frameUpdated(id);
            av_frame_free(&frame);
        } else {
            Q_EMIT avModel.frameUpdated(id);
        }
    });
    producer.join();
}

/*!
 * WHEN  A frame is produced on a daemon thread for a subscribed QVideoSink
 * THEN  The sink receives it on its own (GUI) thread, so it can't race with
 *       the sink's destruction
 */
TEST(VideoProviderTest, DeliversFramesOnTheSinkThread)
{
    auto& avModel = globalEnv.lrcInstance->avModel();
    VideoProvider provider(avModel);
    const QString id = "videoprovider-test-renderer";

    Q_EMIT avModel.rendererStarted(id, QSize(16, 16));

    QVideoSink sink;
    provider.subscribe(&sink, id);

    QThread* deliveryThread = nullptr;
    QObject::connect(&sink, &QVideoSink::videoFrameChanged, &sink, [&deliveryThread] {
        deliveryThread = QThread::currentThread();
    }, Qt::DirectConnection);
    QSignalSpy frameSpy(&sink, &QVideoSink::videoFrameChanged);

    pushFrameFromWorkerThread(avModel, id);

    ASSERT_TRUE(frameSpy.count() > 0 || frameSpy.wait(5000));
    EXPECT_EQ(deliveryThread, sink.thread());

    Q_EMIT avModel.rendererStopped(id);
}

/*!
 * WHEN  A QVideoSink is destroyed while a frame for it is pending delivery
 * THEN  The frame is not delivered to the destroyed sink
 */
TEST(VideoProviderTest, DoesNotDeliverFramesToDestroyedSinks)
{
    auto& avModel = globalEnv.lrcInstance->avModel();
    VideoProvider provider(avModel);
    const QString id = "videoprovider-test-renderer-destroyed";

    Q_EMIT avModel.rendererStarted(id, QSize(16, 16));

    auto* sink = new QVideoSink;
    provider.subscribe(sink, id);

    pushFrameFromWorkerThread(avModel, id);
    delete sink;

    // Processing the pending delivery must not touch the destroyed sink.
    QCoreApplication::processEvents();
    EXPECT_TRUE(provider.getActiveRenderers().contains(id));

    Q_EMIT avModel.rendererStopped(id);
}
