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
#include "app/videoprovider.h"

#include <QMetaObject>
#include <QSignalSpy>
#include <QThread>
#include <QVideoFrameFormat>
#include <QVideoSink>

TEST(VideoProviderTest, DeliversFrameOnSinkThread)
{
    QThread sinkThread;
    sinkThread.start();

    auto* sink = new QVideoSink;
    sink->moveToThread(&sinkThread);
    QSignalSpy frameChangedSpy(sink, &QVideoSink::videoFrameChanged);

    const QVideoFrame frame(QVideoFrameFormat(QSize(2, 2), QVideoFrameFormat::Format_RGBA8888));
    VideoProvider::deliverVideoFrameForTest(sink, frame);

    EXPECT_EQ(frameChangedSpy.count(), 0);
    if (frameChangedSpy.count() == 0) {
        EXPECT_TRUE(frameChangedSpy.wait(1000));
    }
    EXPECT_EQ(frameChangedSpy.count(), 1);

    bool frameIsValid = false;
    QMetaObject::invokeMethod(
        sink,
        [sink, &frameIsValid] { frameIsValid = sink->videoFrame().isValid(); },
        Qt::BlockingQueuedConnection);
    EXPECT_TRUE(frameIsValid);

    sink->deleteLater();
    sinkThread.quit();
    sinkThread.wait();
}
