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

#include "attachmentdownloadqueue.h"

#include <algorithm>

namespace lrc {

void
AttachmentDownloadQueue::enqueue(Attachment attachment)
{
    if (isKnown(attachment.fileId))
        return;
    queue_.push_back(std::move(attachment));
}

std::vector<AttachmentDownloadQueue::Attachment>
AttachmentDownloadQueue::start(Clock::time_point now)
{
    std::vector<Attachment> started;
    while (inFlight_.size() < maxConcurrent && !queue_.empty()) {
        auto attachment = std::move(queue_.front());
        queue_.pop_front();
        const auto fileId = attachment.fileId;
        inFlight_.emplace(fileId, InFlight {attachment, 0, now});
        started.push_back(std::move(attachment));
    }
    return started;
}

void
AttachmentDownloadQueue::update(const QString& fileId, qlonglong progress, qlonglong total, Clock::time_point now)
{
    auto it = inFlight_.find(fileId);
    if (it == inFlight_.end())
        return;
    auto& inFlight = it->second;
    const bool complete = total > 0 && progress >= total;
    if (progress != inFlight.progress) {
        inFlight.progress = progress;
        inFlight.lastProgress = now;
    }
    if (complete || now - inFlight.lastProgress >= stallTimeout)
        inFlight_.erase(it);
}

void
AttachmentDownloadQueue::finish(const QString& fileId)
{
    inFlight_.erase(fileId);
}

std::vector<AttachmentDownloadQueue::Attachment>
AttachmentDownloadQueue::inFlight() const
{
    std::vector<Attachment> attachments;
    attachments.reserve(inFlight_.size());
    for (const auto& [fileId, inFlight] : inFlight_)
        attachments.push_back(inFlight.attachment);
    return attachments;
}

bool
AttachmentDownloadQueue::idle() const
{
    return queue_.empty() && inFlight_.empty();
}

bool
AttachmentDownloadQueue::hasWork(const QString& conversationId) const
{
    const auto inConversation = [&conversationId](const Attachment& attachment) {
        return attachment.conversationId == conversationId;
    };
    return std::any_of(queue_.begin(), queue_.end(), inConversation)
           || std::any_of(inFlight_.begin(), inFlight_.end(), [&](const auto& entry) {
                  return inConversation(entry.second.attachment);
              });
}

bool
AttachmentDownloadQueue::isKnown(const QString& fileId) const
{
    if (inFlight_.count(fileId))
        return true;
    return std::any_of(queue_.begin(), queue_.end(), [&fileId](const Attachment& attachment) {
        return attachment.fileId == fileId;
    });
}

} // namespace lrc
