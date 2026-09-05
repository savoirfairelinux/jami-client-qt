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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

#include <QString>

#include <chrono>
#include <cstddef>
#include <deque>
#include <map>
#include <vector>

namespace lrc {

/**
 * Paces the attachment downloads of a synchronized account so that a source
 * device is never asked for too many files at once.
 *
 * Pure bookkeeping: the caller starts the downloads it is given by start(),
 * reports their progress through update() and the daemon's verdict through
 * finish() or suspend(). A download occupies one of the maxConcurrent slots
 * while in flight; it frees it once complete, or once it has not progressed
 * for stallTimeout, in which case it stays pending: the daemon still holds the
 * request and retries it on the next sync with the device, so the attachment
 * is only over once finish() says so.
 */
class AttachmentDownloadQueue
{
public:
    using Clock = std::chrono::steady_clock;

    struct Attachment
    {
        QString conversationId;
        QString interactionId;
        QString fileId;
    };

    static constexpr std::size_t maxConcurrent = 3;
    static constexpr unsigned maxAttempts = 3;
    static constexpr std::chrono::seconds stallTimeout {10};

    void enqueue(Attachment attachment);
    /**
     * Moves as many queued attachments as there are free slots to in-flight.
     * @return the attachments whose download must be started now
     */
    std::vector<Attachment> start(Clock::time_point now);
    void update(const QString& fileId, qlonglong progress, qlonglong total, Clock::time_point now);
    /**
     * The daemon is done with the request (file received, path conflict, or
     * canceled by the user): the attachment is over.
     */
    void finish(const QString& fileId);
    /**
     * The daemon lost the peer but keeps the request for a later retry: the
     * attachment frees its slot and stays pending.
     */
    void suspend(const QString& fileId);
    /**
     * The download request never reached the daemon: put the attachment back
     * in the queue.
     * @return false if the attachment is given up after maxAttempts
     */
    bool requeue(const QString& fileId);
    /** Forgets every attachment of a removed conversation. */
    void discard(const QString& conversationId);

    std::vector<Attachment> inFlight() const;
    /** @return whether the daemon has been asked for the file (in flight or pending) */
    bool isRequested(const QString& fileId) const;
    /** @return whether nothing is left to poll or to start (pending attachments need neither) */
    bool idle() const;
    /** @return whether the conversation still has attachments queued, in flight or pending */
    bool hasWork(const QString& conversationId) const;

private:
    struct Queued
    {
        Attachment attachment;
        unsigned attempts;
    };
    struct InFlight
    {
        Attachment attachment;
        unsigned attempts;
        qlonglong progress;
        Clock::time_point lastProgress;
    };

    bool isKnown(const QString& fileId) const;

    std::deque<Queued> queue_;
    std::map<QString, InFlight> inFlight_;
    std::map<QString, Attachment> pending_;
};

} // namespace lrc
