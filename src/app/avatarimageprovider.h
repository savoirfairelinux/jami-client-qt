/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

#pragma once

#include "quickimageproviderbase.h"
#include "utils.h"
#include "lrcinstance.h"

#include <QImage>
#include <QRegularExpression>

class AsyncAvatarImageResponseRunnable : public AsyncImageResponseRunnable
{
    Q_OBJECT
public:
    AsyncAvatarImageResponseRunnable(const QString& id, const QSize& requestedSize, LRCInstance* lrcInstance)
        : AsyncImageResponseRunnable(id, requestedSize, lrcInstance)
    {}

    void run() override
    {
        // For avatar images, the requested size should be a square. Anything else
        // is a request made prior to an aspect ratio guard calculation.
        if (requestedSize_ == QSize(0, 0) || requestedSize_.width() != requestedSize_.height()) {
            return;
        }

        // the first string is the item uri and the second is a uid
        // that is used for trigger a reload of the underlying image
        // data and can be discarded at this point
        auto idInfo = id_.split("_");

        if (idInfo.size() < 2) {
            qWarning() << Q_FUNC_INFO << "Missing element(s) in the image url";
            return;
        }

        const auto& imageId = idInfo.at(1);
        if (!imageId.size()) {
            qWarning() << Q_FUNC_INFO << "Missing id in the image url";
            return;
        }

        QImage image;
        const auto& type = idInfo.at(0);

        if (type == "conversation") {
            if (imageId == "temp")
                image = Utils::tempConversationAvatar(requestedSize_);
            else
                image = Utils::conversationAvatar(lrcInstance_, imageId, requestedSize_);
        } else if (type == "account") {
            image = Utils::accountPhoto(lrcInstance_, imageId, requestedSize_);
        } else if (type == "contact") {
            image = Utils::contactPhoto(lrcInstance_, imageId, requestedSize_);
        } else if (type == "temporaryAccount") {
            // Check if imageId is a SHA-1 hash (jamiId or registered name)
            static const QRegularExpression sha1Pattern("^[0-9a-fA-F]{40}$");
            if (sha1Pattern.match(imageId).hasMatch()) {
                // If we only have a jamiId use default avatar
                image = Utils::fallbackAvatar("jami:" + imageId, QString(), requestedSize_);
            } else {
                // For registered usernames, use fallbackAvatar avatar with the name
                image = Utils::fallbackAvatar(QString(), imageId, requestedSize_);
            }
        } else {
            qWarning() << Q_FUNC_INFO << "Missing valid prefix in the image url";
            return;
        }

        Q_EMIT done(image);
    }
};

class AvatarImageProvider : public AsyncImageProviderBase
{
public:
    AvatarImageProvider(LRCInstance* instance = nullptr)
        : AsyncImageProviderBase(instance)
    {}

    QQuickImageResponse* requestImageResponse(const QString& id, const QSize& requestedSize) override
    {
        auto response = new AsyncImageResponse<AsyncAvatarImageResponseRunnable>(id,
                                                                                 requestedSize,
                                                                                 &pool_,
                                                                                 lrcInstance_);
        return response;
    }
};
