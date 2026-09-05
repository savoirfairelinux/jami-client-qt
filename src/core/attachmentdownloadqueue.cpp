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
#include <iterator>

namespace lrc {

void
AttachmentDownloadQueue::enqueue(Attachment attachment)
{
    if (isKnown(attachment.fileId))
        return;
    queue_.push_back({std::move(attachment), 0});
}

std::vector<AttachmentDownloadQueue::Attachment>
AttachmentDownloadQueue::start(Clock::time_point now)
{
    std::vector<Attachment> started;
    while (inFlight_.size() < maxConcurrent && !queue_.empty()) {
        auto queued = std::move(queue_.front());
        queue_.pop_front();
        const auto fileId = queued.attachment.fileId;
        inFlight_.emplace(fileId, InFlight {queued.attachment, queued.attempts + 1, 0, now});
        started.push_back(std::move(queued.attachment));
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
    if (progress != inFlight.progress) {
        inFlight.progress = progress;
        inFlight.lastProgress = now;
    }
    if (total > 0 && progress >= total)
        inFlight_.erase(it);
    else if (now - inFlight.lastProgress >= stallTimeout)
        suspend(fileId);
}

void
AttachmentDownloadQueue::finish(const QString& fileId)
{
    inFlight_.erase(fileId);
    pending_.erase(fileId);
}

void
AttachmentDownloadQueue::suspend(const QString& fileId)
{
    auto it = inFlight_.find(fileId);
    if (it == inFlight_.end())
        return;
    pending_.emplace(fileId, std::move(it->second.attachment));
    inFlight_.erase(it);
}

bool
AttachmentDownloadQueue::requeue(const QString& fileId)
{
    auto it = inFlight_.find(fileId);
    if (it == inFlight_.end())
        return false;
    const auto attempts = it->second.attempts;
    auto attachment = std::move(it->second.attachment);
    inFlight_.erase(it);
    if (attempts >= maxAttempts)
        return false;
    queue_.push_back({std::move(attachment), attempts});
    return true;
}

void
AttachmentDownloadQueue::discard(const QString& conversationId)
{
    const auto inConversation = [&conversationId](const Attachment& attachment) {
        return attachment.conversationId == conversationId;
    };
    queue_.erase(std::remove_if(queue_.begin(),
                                queue_.end(),
                                [&](const Queued& queued) { return inConversation(queued.attachment); }),
                 queue_.end());
    for (auto it = inFlight_.begin(); it != inFlight_.end();)
        it = inConversation(it->second.attachment) ? inFlight_.erase(it) : std::next(it);
    for (auto it = pending_.begin(); it != pending_.end();)
        it = inConversation(it->second) ? pending_.erase(it) : std::next(it);
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
AttachmentDownloadQueue::isRequested(const QString& fileId) const
{
    return inFlight_.count(fileId) || pending_.count(fileId);
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
    return std::any_of(queue_.begin(),
                       queue_.end(),
                       [&](const Queued& queued) { return inConversation(queued.attachment); })
           || std::any_of(inFlight_.begin(),
                          inFlight_.end(),
                          [&](const auto& entry) { return inConversation(entry.second.attachment); })
           || std::any_of(pending_.begin(), pending_.end(), [&](const auto& entry) {
                  return inConversation(entry.second);
              });
}

bool
AttachmentDownloadQueue::isKnown(const QString& fileId) const
{
    return isRequested(fileId) || std::any_of(queue_.begin(), queue_.end(), [&fileId](const Queued& queued) {
               return queued.attachment.fileId == fileId;
           });
}

} // namespace lrc
