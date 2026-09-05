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
 * Pure bookkeeping: the caller starts the downloads it is given by start() and
 * reports their progress through update(). A download leaves the in-flight set
 * once complete, or once it has not progressed for stallTimeout; in the latter
 * case the daemon still holds the request and retries it on the next sync with
 * the device, so nothing is lost.
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
    static constexpr std::chrono::seconds stallTimeout {10};

    void enqueue(Attachment attachment);
    /**
     * Moves as many queued attachments as there are free slots to in-flight.
     * @return the attachments whose download must be started now
     */
    std::vector<Attachment> start(Clock::time_point now);
    void update(const QString& fileId, qlonglong progress, qlonglong total, Clock::time_point now);
    std::vector<Attachment> inFlight() const;
    bool idle() const;

private:
    struct InFlight
    {
        Attachment attachment;
        qlonglong progress;
        Clock::time_point lastProgress;
    };

    bool isKnown(const QString& fileId) const;

    std::deque<Attachment> queue_;
    std::map<QString, InFlight> inFlight_;
};

} // namespace lrc
