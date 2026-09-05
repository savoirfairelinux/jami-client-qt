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

#include "api/conversationmodel.h"
#include "attachmentdownloadqueue.h"

#include <gtest/gtest.h>

using lrc::api::ConversationModel;

/**
 * When an account is imported from another device with "Synchronize attachments"
 * enabled, every attachment of the cloned conversations is downloaded, whatever
 * its size. The attachments are discovered through a search of the
 * data-transfer messages of the conversation; these tests validate which of
 * those search results end up being downloaded.
 */

TEST(AttachmentSync, DownloadsEveryAttachmentRegardlessOfSize)
{
    VectorMapStringString messages;
    messages.append({{"id", "small"}, {"fileId", "small_a.txt"}, {"totalSize", "1"}});
    messages.append({{"id", "huge"}, {"fileId", "huge_b.iso"}, {"totalSize", "4294967296"}});

    const auto attachments = ConversationModel::attachmentsToDownload(messages);

    ASSERT_EQ(attachments.size(), 2u);
    EXPECT_EQ(attachments[0].first, "small");
    EXPECT_EQ(attachments[0].second, "small_a.txt");
    EXPECT_EQ(attachments[1].first, "huge");
    EXPECT_EQ(attachments[1].second, "huge_b.iso");
}

/**
 * A deleted attachment keeps its data-transfer message but the daemon clears
 * its fileId, so there is nothing left to download.
 */
TEST(AttachmentSync, SkipsDeletedAttachments)
{
    VectorMapStringString messages;
    messages.append({{"id", "deleted"}, {"fileId", ""}, {"totalSize", "42"}});
    messages.append({{"id", "kept"}, {"fileId", "kept_c.png"}, {"totalSize", "42"}});

    const auto attachments = ConversationModel::attachmentsToDownload(messages);

    ASSERT_EQ(attachments.size(), 1u);
    EXPECT_EQ(attachments[0].first, "kept");
    EXPECT_EQ(attachments[0].second, "kept_c.png");
}

TEST(AttachmentSync, SkipsResultsWithoutIdentifiers)
{
    VectorMapStringString messages;
    messages.append({{"fileId", "orphan_d.txt"}});
    messages.append({{"id", "no-file"}});

    const auto attachments = ConversationModel::attachmentsToDownload(messages);

    EXPECT_TRUE(attachments.empty());
}

/**
 * Asking a source device for every attachment at once overloads its connection
 * (observed: 17 parallel transfers repeatedly killing the peer TLS session), so
 * the downloads are paced: a few at a time, a slot being released when a file
 * is complete or when it has not progressed for a while. A released download
 * is not lost: the daemon keeps the request and retries it on the next sync.
 */
using lrc::AttachmentDownloadQueue;
using Attachment = AttachmentDownloadQueue::Attachment;
using Clock = AttachmentDownloadQueue::Clock;

namespace {
Attachment
attachment(int n)
{
    const auto id = QString::number(n);
    return {"conv", "msg" + id, "msg" + id + "_tid.jpg"};
}
} // namespace

TEST(AttachmentDownloadQueue, StartsAtMostMaxConcurrentDownloads)
{
    AttachmentDownloadQueue queue;
    for (int i = 0; i < 5; ++i)
        queue.enqueue(attachment(i));

    const auto now = Clock::now();
    const auto started = queue.start(now);

    EXPECT_EQ(started.size(), AttachmentDownloadQueue::maxConcurrent);
    EXPECT_EQ(queue.inFlight().size(), AttachmentDownloadQueue::maxConcurrent);
    EXPECT_TRUE(queue.start(now).empty());
    EXPECT_FALSE(queue.idle());
}

TEST(AttachmentDownloadQueue, CompletedDownloadReleasesItsSlot)
{
    AttachmentDownloadQueue queue;
    for (int i = 0; i < 4; ++i)
        queue.enqueue(attachment(i));
    const auto now = Clock::now();
    queue.start(now);

    queue.update(attachment(0).fileId, 100, 100, now + std::chrono::seconds(1));

    const auto started = queue.start(now + std::chrono::seconds(1));
    ASSERT_EQ(started.size(), 1u);
    EXPECT_EQ(started[0].fileId, attachment(3).fileId);
}

TEST(AttachmentDownloadQueue, StalledDownloadReleasesItsSlotAfterTimeout)
{
    AttachmentDownloadQueue queue;
    for (int i = 0; i < 4; ++i)
        queue.enqueue(attachment(i));
    const auto now = Clock::now();
    queue.start(now);

    const auto beforeTimeout = now + AttachmentDownloadQueue::stallTimeout - std::chrono::seconds(1);
    queue.update(attachment(1).fileId, 0, 100, beforeTimeout);
    EXPECT_TRUE(queue.start(beforeTimeout).empty());

    const auto afterTimeout = now + AttachmentDownloadQueue::stallTimeout;
    queue.update(attachment(1).fileId, 0, 100, afterTimeout);
    const auto started = queue.start(afterTimeout);
    ASSERT_EQ(started.size(), 1u);
    EXPECT_EQ(started[0].fileId, attachment(3).fileId);
}

TEST(AttachmentDownloadQueue, ProgressingDownloadKeepsItsSlot)
{
    AttachmentDownloadQueue queue;
    for (int i = 0; i < 4; ++i)
        queue.enqueue(attachment(i));
    const auto now = Clock::now();
    queue.start(now);

    auto later = now;
    for (int step = 1; step <= 3; ++step) {
        later += AttachmentDownloadQueue::stallTimeout - std::chrono::seconds(1);
        queue.update(attachment(2).fileId, step * 10, 100, later);
    }

    EXPECT_TRUE(queue.start(later).empty());
    EXPECT_EQ(queue.inFlight().size(), AttachmentDownloadQueue::maxConcurrent);
}

TEST(AttachmentDownloadQueue, IgnoresDuplicatesAndUnknownFiles)
{
    AttachmentDownloadQueue queue;
    queue.enqueue(attachment(0));
    queue.enqueue(attachment(0));
    const auto now = Clock::now();

    EXPECT_EQ(queue.start(now).size(), 1u);
    queue.enqueue(attachment(0));
    EXPECT_TRUE(queue.start(now).empty());

    queue.update("unknown_tid.jpg", 5, 10, now);
    EXPECT_EQ(queue.inFlight().size(), 1u);

    queue.update(attachment(0).fileId, 10, 10, now);
    EXPECT_TRUE(queue.idle());
}
