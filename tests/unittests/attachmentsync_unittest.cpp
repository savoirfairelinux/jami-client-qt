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
 * is not lost: the daemon keeps the request and retries it on the next sync, so
 * the attachment stays pending until the daemon reports the request over.
 */
using lrc::AttachmentDownloadQueue;
using Attachment = AttachmentDownloadQueue::Attachment;
using Clock = AttachmentDownloadQueue::Clock;

namespace {
Attachment
attachment(int n, const QString& conversationId = "conv")
{
    const auto id = QString::number(n);
    return {conversationId, "msg" + id, "msg" + id + "_tid.jpg"};
}

AttachmentDownloadQueue
queueOf(int count)
{
    AttachmentDownloadQueue queue;
    for (int i = 0; i < count; ++i)
        queue.enqueue(attachment(i));
    return queue;
}
} // namespace

TEST(AttachmentDownloadQueue, StartsAtMostMaxConcurrentDownloads)
{
    auto queue = queueOf(5);

    const auto now = Clock::now();
    const auto started = queue.start(now);

    EXPECT_EQ(started.size(), AttachmentDownloadQueue::maxConcurrent);
    EXPECT_EQ(queue.inFlight().size(), AttachmentDownloadQueue::maxConcurrent);
    EXPECT_TRUE(queue.start(now).empty());
    EXPECT_FALSE(queue.idle());
}

TEST(AttachmentDownloadQueue, CompletedDownloadReleasesItsSlot)
{
    auto queue = queueOf(4);
    const auto now = Clock::now();
    queue.start(now);

    queue.update(attachment(0).fileId, 100, 100, now + std::chrono::seconds(1));

    const auto started = queue.start(now + std::chrono::seconds(1));
    ASSERT_EQ(started.size(), 1u);
    EXPECT_EQ(started[0].fileId, attachment(3).fileId);
    EXPECT_FALSE(queue.isRequested(attachment(0).fileId));
}

/**
 * A stalled download frees its slot but stays pending: the daemon still owns
 * the request, so the conversation is still being synchronized.
 */
TEST(AttachmentDownloadQueue, StalledDownloadReleasesItsSlotButStaysPending)
{
    auto queue = queueOf(4);
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
    EXPECT_TRUE(queue.isRequested(attachment(1).fileId));
    EXPECT_EQ(queue.inFlight().size(), AttachmentDownloadQueue::maxConcurrent);

    for (int i : {0, 2, 3})
        queue.finish(attachment(i).fileId);
    EXPECT_TRUE(queue.idle()) << "nothing left to poll or start";
    EXPECT_TRUE(queue.hasWork("conv")) << "the stalled attachment is still pending";

    queue.finish(attachment(1).fileId);
    EXPECT_FALSE(queue.hasWork("conv"));
}

TEST(AttachmentDownloadQueue, ProgressingDownloadKeepsItsSlot)
{
    auto queue = queueOf(4);
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
    queue.suspend("unknown_tid.jpg");
    queue.finish("unknown_tid.jpg");
    EXPECT_FALSE(queue.requeue("unknown_tid.jpg"));
    EXPECT_EQ(queue.inFlight().size(), 1u);

    queue.update(attachment(0).fileId, 10, 10, now);
    EXPECT_TRUE(queue.idle());
}

/**
 * A zero-byte attachment reports total == progress == 0 whether it is still
 * waiting or already complete, so its completion comes from the daemon's
 * terminal transfer event rather than from the progress.
 */
TEST(AttachmentDownloadQueue, FinishedDownloadReleasesItsSlotWhateverItsSize)
{
    auto queue = queueOf(4);
    const auto now = Clock::now();
    queue.start(now);

    queue.update(attachment(0).fileId, 0, 0, now + std::chrono::seconds(1));
    EXPECT_TRUE(queue.start(now + std::chrono::seconds(1)).empty());

    queue.finish(attachment(0).fileId);
    const auto started = queue.start(now + std::chrono::seconds(1));
    ASSERT_EQ(started.size(), 1u);
    EXPECT_EQ(started[0].fileId, attachment(3).fileId);
}

/**
 * When the daemon drops the channel or cannot reach the peer, it keeps the
 * request and retries later: the attachment frees its slot but stays pending.
 */
TEST(AttachmentDownloadQueue, SuspendedDownloadStaysPendingUntilFinished)
{
    auto queue = queueOf(2);
    const auto now = Clock::now();
    queue.start(now);

    queue.suspend(attachment(0).fileId);
    EXPECT_EQ(queue.inFlight().size(), 1u);
    EXPECT_TRUE(queue.isRequested(attachment(0).fileId));
    EXPECT_TRUE(queue.hasWork("conv"));

    queue.suspend(attachment(0).fileId);
    queue.finish(attachment(1).fileId);
    EXPECT_TRUE(queue.idle());
    EXPECT_TRUE(queue.hasWork("conv"));

    queue.finish(attachment(0).fileId);
    EXPECT_FALSE(queue.hasWork("conv"));
}

/**
 * A download whose request never reached the daemon has nothing to retry it:
 * it goes back to the queue, and is given up after a few failed attempts.
 */
TEST(AttachmentDownloadQueue, RequeuesDownloadThatFailedToStart)
{
    auto queue = queueOf(1);
    const auto now = Clock::now();

    for (unsigned attempt = 1; attempt < AttachmentDownloadQueue::maxAttempts; ++attempt) {
        ASSERT_EQ(queue.start(now).size(), 1u) << "attempt " << attempt;
        EXPECT_TRUE(queue.requeue(attachment(0).fileId)) << "attempt " << attempt;
        EXPECT_TRUE(queue.inFlight().empty());
        EXPECT_FALSE(queue.isRequested(attachment(0).fileId));
        EXPECT_TRUE(queue.hasWork("conv"));
    }
    ASSERT_EQ(queue.start(now).size(), 1u);
    EXPECT_FALSE(queue.requeue(attachment(0).fileId)) << "given up after maxAttempts";
    EXPECT_TRUE(queue.idle());
    EXPECT_FALSE(queue.hasWork("conv"));
}

/**
 * The history auto-accept of a conversation is only bypassed while the
 * conversation still has attachments queued, in flight or pending.
 */
TEST(AttachmentDownloadQueue, ReportsWorkPerConversation)
{
    AttachmentDownloadQueue queue;
    queue.enqueue(attachment(1, "convA"));
    queue.enqueue(attachment(2, "convB"));
    EXPECT_TRUE(queue.hasWork("convA"));
    EXPECT_TRUE(queue.hasWork("convB"));
    EXPECT_FALSE(queue.hasWork("convC"));

    const auto now = Clock::now();
    queue.start(now);
    EXPECT_TRUE(queue.hasWork("convA"));

    queue.finish(attachment(1).fileId);
    EXPECT_FALSE(queue.hasWork("convA"));
    EXPECT_TRUE(queue.hasWork("convB"));
}

/**
 * A removed conversation takes its queued, in-flight and pending attachments
 * with it.
 */
TEST(AttachmentDownloadQueue, DiscardsConversation)
{
    AttachmentDownloadQueue queue;
    for (int i = 0; i < 3; ++i)
        queue.enqueue(attachment(i, "convA"));
    queue.enqueue(attachment(3, "convA"));
    queue.enqueue(attachment(4, "convB"));
    const auto now = Clock::now();
    queue.start(now);
    queue.suspend(attachment(0).fileId);

    queue.discard("convA");

    EXPECT_FALSE(queue.hasWork("convA"));
    EXPECT_FALSE(queue.isRequested(attachment(0).fileId));
    EXPECT_TRUE(queue.hasWork("convB"));
    const auto started = queue.start(now);
    ASSERT_EQ(started.size(), 1u);
    EXPECT_EQ(started[0].conversationId, "convB");
}
