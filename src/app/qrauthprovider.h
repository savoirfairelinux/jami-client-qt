/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
#include "accountlistmodel.h"

class QrAuthImageProvider : public QuickImageProviderBase
{
public:
    QrAuthImageProvider(LRCInstance* instance = nullptr)
        : QuickImageProviderBase(QQuickImageProvider::Image,
                                 QQmlImageProviderBase::ForceAsynchronousImageLoading,
                                 instance)
    {}

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override
    {
        Q_UNUSED(size);

        if (!requestedSize.isEmpty())
            return Utils::getQRCodeImage(id, 0).scaled(requestedSize, Qt::KeepAspectRatio);
        else
            return Utils::getQRCodeImage(id, 0);
    }
};
