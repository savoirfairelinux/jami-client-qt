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
#include <libavutil/frame.h>
}

#include <QSignalSpy>
#include <QThread>
#include <QVideoSink>

namespace {

void
emitFrameUpdatedFromWorkerThread(lrc::api::AVModel& avModel, const QString& id)
{
    auto* worker = QThread::create([&avModel, id] {
        if (avModel.useDirectRenderer()) {
            auto* frame = av_frame_alloc();
            Q_EMIT avModel.frameBufferRequested(id, frame);
            Q_EMIT avModel.frameUpdated(id);
            av_frame_free(&frame);
            return;
        }

        Q_EMIT avModel.frameUpdated(id);
    });

    worker->start();
    worker->wait();
    delete worker;
}

} // namespace

TEST(VideoProvider, UpdatesVideoSinkOnSinkThread)
{
    auto& avModel = globalEnv.lrcInstance->avModel();
    VideoProvider provider(avModel);
    QVideoSink sink;
    const QString id = "video-provider-thread-test";

    Q_EMIT avModel.rendererStarted(id, QSize(2, 2));
    provider.subscribe(&sink, id);

    bool notifiedOnSinkThread = false;
    QSignalSpy frameChangedSpy(&sink, &QVideoSink::videoFrameChanged);
    QObject::connect(
        &sink,
        &QVideoSink::videoFrameChanged,
        &sink,
        [&] { notifiedOnSinkThread = QThread::currentThread() == sink.thread(); },
        Qt::DirectConnection);

    emitFrameUpdatedFromWorkerThread(avModel, id);

    ASSERT_TRUE(frameChangedSpy.wait(1000));
    EXPECT_TRUE(notifiedOnSinkThread);

    Q_EMIT avModel.rendererStopped(id);
}
