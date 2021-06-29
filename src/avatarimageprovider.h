/*
 * Copyright (C) 2020-2021 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

class AvatarImageProvider : public QuickImageProviderBase
{
public:
    AvatarImageProvider(LRCInstance* instance = nullptr)
        : QuickImageProviderBase(QQuickImageProvider::Image,
                                 QQmlImageProviderBase::ForceAsynchronousImageLoading,
                                 instance)
    {}

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override
    {
        Q_UNUSED(size)

        // the first string is the item uri and the second is a uid
        // that is used for trigger a reload of the underlying image
        // data and can be discarded at this point
        auto idInfo = id.split("_");

        if (idInfo.size() < 1) {
            qWarning() << Q_FUNC_INFO << "Missing element in the image url";
            return {};
        }

        auto avatarId = idInfo.at(0);
        if (avatarId.size() == 40)
            return Utils::contactPhoto(lrcInstance_, avatarId, requestedSize);
        else
            return Utils::accountPhoto(lrcInstance_, avatarId, requestedSize);
    }
};
