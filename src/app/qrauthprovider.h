/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

class AsyncQrAuthImageResponseRunnable : public AsyncImageResponseRunnable
{
    Q_OBJECT
public:
    AsyncQrAuthImageResponseRunnable(const QString& uri,
                                     const QSize& requestedSize,
                                     LRCInstance* lrcInstance)
        : AsyncImageResponseRunnable(uri, requestedSize, lrcInstance)
    {}

    void run() override
    {
        if (requestedSize_ == QSize(0, 0) || requestedSize_.width() != requestedSize_.height()) {
            return;
        }
        QImage image = Utils::getQRCodeImage(/*uri is just the id*/ id_, 0);
        Q_EMIT done(image);
    }

    // void run() override
    // {
    //     // For avatar images, the requested size should be a square. Anything else
    //     // is a request made prior to an aspect ratio guard calculation.
    //     if (requestedSize_ == QSize(0, 0) || requestedSize_.width() != requestedSize_.height()) {
    //         return;
    //     }
    //
    //     // // the first string is the item uri and the second is a uid
    //     // // that is used for trigger a reload of the underlying image
    //     // // data and can be discarded at this point
    //     // auto idInfo = uri_.split("_");
    //
    //     // if (idInfo.size() < 2) {
    //     //     qWarning() << Q_FUNC_INFO << "Missing element(s) in the image url";
    //     //     return;
    //     // }
    //
    //     // // const auto& imageId = idInfo.at(1);
    //     // if (!uri.size()) {
    //     // // if (!imageId.size()) {
    //     //     qWarning() << Q_FUNC_INFO << "Missing id in the image url";
    //     //     return;
    //     // }
    //
    //     QImage image;
    //     // const auto& type = idInfo.at(0);
    //
    //     image = Utils::getQRCodeImage(/*QString data*/ uri, 0/*int margin*/);
    //
    //     Q_EMIT done(image);
    // }
};

class QrAuthImageProvider : public AsyncImageProviderBase
{
public:
    QrAuthImageProvider(LRCInstance* instance = nullptr)
        : AsyncImageProviderBase(instance)
    {}

    QQuickImageResponse* requestImageResponse(const QString& id, const QSize& requestedSize) override
    {
        auto response = new AsyncImageResponse<AsyncQrAuthImageResponseRunnable>(id,
                                                                                 requestedSize,
                                                                                 &pool_,
                                                                                 lrcInstance_);
        return response;
    }
};
