/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "distantrenderer.h"

#include "lrcinstance.h"

DistantRenderer::DistantRenderer(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
    setFillColor(Qt::black);
    setRenderTarget(QQuickPaintedItem::FramebufferObject);
    setPerformanceHint(QQuickPaintedItem::FastFBOResizing);

    connect(LRCInstance::renderer(), &RenderManager::distantFrameUpdated, [this](const QString &id) {
        if (distantRenderId_ == id)
            update(QRect(0, 0, width(), height()));
    });

    connect(LRCInstance::renderer(),
            &RenderManager::distantRenderingStopped,
            [this](const QString &id) {
                if (distantRenderId_ == id)
                    update(QRect(0, 0, width(), height()));
            });
}

DistantRenderer::~DistantRenderer() {}

void
DistantRenderer::setRendererId(const QString &id)
{
    distantRenderId_ = id;
    update(QRect(0, 0, width(), height()));
}

void
DistantRenderer::paint(QPainter *painter)
{
    auto distantImage = LRCInstance::renderer()->getFrame(distantRenderId_);
    if (distantImage) {
        auto scaledDistant = distantImage->scaled(size().toSize(), Qt::KeepAspectRatio);
        auto tSW = static_cast<int>(scaledW_*1000);
        auto tSH = static_cast<int>(scaledH_*1000);
        auto tXD = xDiff_;
        auto tYD = yDiff_;
        scaledW_ = static_cast<double>(scaledDistant.width())/static_cast<double>(distantImage->width());
        scaledH_ = static_cast<double>(scaledDistant.height())/static_cast<double>(distantImage->height());
        xDiff_ = (width() - scaledDistant.width()) / 2;
        yDiff_ = (height() - scaledDistant.height()) / 2;
        if (tXD != xDiff_ or tYD != yDiff_ or static_cast<int>(scaledW_*1000) != tSW or static_cast<int>(scaledH_*1000) != tSH) {
            emit offsetChanged();
        }
        painter->drawImage(QRect(xDiff_, yDiff_, scaledDistant.width(), scaledDistant.height()),
                           scaledDistant);
    }
}