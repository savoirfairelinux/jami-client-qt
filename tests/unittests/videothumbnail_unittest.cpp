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

#include "messagesadapter.h"
#include "videothumbnailprovider.h"

#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>

class VideoThumbnailerFixture : public ::testing::Test
{
public:
    // The thumbnailer reads local files, not resources.
    QString localCopy(const QString& name)
    {
        const auto path = tempDir.filePath(name);
        EXPECT_TRUE(QFile::copy(":/videos/" + name, path));
        return path;
    }

    QImage thumbnail(const QString& filePath)
    {
        QSignalSpy readySpy(&thumbnailer, &VideoThumbnailer::ready);
        thumbnailer.request(filePath);
        if (readySpy.isEmpty() && !readySpy.wait(10000)) {
            ADD_FAILURE() << "No thumbnail was provided for " << filePath.toStdString();
            return {};
        }
        EXPECT_EQ(readySpy.first().at(0).toString(), filePath);
        return readySpy.first().at(1).value<QImage>();
    }

    QTemporaryDir tempDir;
    VideoThumbnailer thumbnailer;
};

/*!
 * WHEN  The thumbnail of a video is requested
 * THEN  A frame of the video is provided, at the size of the video
 */
TEST_F(VideoThumbnailerFixture, ProvidesAFrameOfTheVideo)
{
    const auto image = thumbnail(localCopy("video_test.mp4"));

    ASSERT_FALSE(image.isNull());
    EXPECT_EQ(image.size(), QSize(320, 180));
}

/*!
 * WHEN  The video is meant to be displayed rotated, as recorded by an upright phone
 * THEN  The thumbnail is rotated the same way
 */
TEST_F(VideoThumbnailerFixture, AppliesTheDisplayRotation)
{
    const auto image = thumbnail(localCopy("video_test_rotated.mp4"));

    ASSERT_FALSE(image.isNull());
    EXPECT_EQ(image.size(), QSize(180, 320));
}

/*!
 * WHEN  The video starts with a black frame, as in a fade-in
 * THEN  The thumbnail shows a later frame
 */
TEST_F(VideoThumbnailerFixture, SkipsABlackFirstFrame)
{
    const auto image = thumbnail(localCopy("video_test_black_start.mp4"));

    ASSERT_FALSE(image.isNull());
    // The video is light grey after its first half second.
    EXPECT_GT(qGray(image.pixel(image.width() / 2, image.height() / 2)), 128);
}

/*!
 * WHEN  The video is larger than the maximum thumbnail size
 * THEN  The thumbnail is scaled down to that size, keeping the aspect ratio
 */
TEST_F(VideoThumbnailerFixture, ScalesDownLargeVideos)
{
    const auto image = thumbnail(localCopy("video_test_large.mp4"));

    ASSERT_FALSE(image.isNull());
    EXPECT_EQ(image.size(), QSize(VideoThumbnailer::maxSize, VideoThumbnailer::maxSize * 9 / 16));
}

/*!
 * WHEN  The thumbnail of a file that is not a decodable video is requested
 * THEN  A null image is provided
 */
TEST_F(VideoThumbnailerFixture, ProvidesANullImageWithoutVideoFrame)
{
    const auto notAVideo = tempDir.filePath("not_a_video.mp4");
    QFile file(notAVideo);
    ASSERT_TRUE(file.open(QIODevice::WriteOnly));
    file.write("This is not a video.");
    file.close();

    EXPECT_TRUE(thumbnail(notAVideo).isNull());
    EXPECT_TRUE(thumbnail(tempDir.filePath("missing.mp4")).isNull());
}

/*!
 * WHEN  A file without a thumbnail changes, for instance once it is written
 * THEN  Its thumbnail is extracted again
 */
TEST_F(VideoThumbnailerFixture, RetriesAFailedFileOnceItChanges)
{
    const auto path = tempDir.filePath("late.mp4");
    ASSERT_TRUE(thumbnail(path).isNull());

    ASSERT_TRUE(QFile::copy(":/videos/video_test.mp4", path));

    EXPECT_FALSE(thumbnail(path).isNull());
}

/*!
 * WHEN  A file with a thumbnail is replaced by another video
 * THEN  The thumbnail of the new video is provided
 */
TEST_F(VideoThumbnailerFixture, RefreshesTheThumbnailOfAChangedFile)
{
    const auto path = localCopy("video_test.mp4");
    ASSERT_EQ(thumbnail(path).size(), QSize(320, 180));

    ASSERT_TRUE(QFile::remove(path));
    ASSERT_TRUE(QFile::copy(":/videos/video_test_rotated.mp4", path));

    EXPECT_EQ(thumbnail(path).size(), QSize(180, 320));
}

/*!
 * WHEN  The media info of a video that the web engine can't play is requested
 * THEN  It describes a video without a web player, which is shown as a thumbnail
 */
TEST(VideoMediaInfo, VideosTheWebEngineCannotPlayHaveNoWebPlayer)
{
    MessagesAdapter messagesAdapter(globalEnv.settingsManager.data(),
                                    globalEnv.previewEngine.data(),
                                    globalEnv.lrcInstance.data());

    for (const auto& name : {"clip.mp4", "clip.mov", "clip.mkv", "clip.avi"}) {
        const auto mediaInfo = messagesAdapter.getMediaInfo(QDir::temp().filePath(name));
        EXPECT_TRUE(mediaInfo["isVideo"].toBool()) << name;
        EXPECT_FALSE(mediaInfo.contains("html")) << name;
    }
}

/*!
 * WHEN  The media info of a WebM video is requested
 * THEN  It still describes a video with a web player
 */
TEST(VideoMediaInfo, WebmVideosKeepTheirWebPlayer)
{
    MessagesAdapter messagesAdapter(globalEnv.settingsManager.data(),
                                    globalEnv.previewEngine.data(),
                                    globalEnv.lrcInstance.data());

    const auto mediaInfo = messagesAdapter.getMediaInfo(QDir::temp().filePath("clip.webm"));

    EXPECT_TRUE(mediaInfo["isVideo"].toBool());
    EXPECT_TRUE(mediaInfo.contains("html"));
}
