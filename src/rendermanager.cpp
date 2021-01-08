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

#include "rendermanager.h"

#include "framewrapper.h"

#include <QtMultimedia/QVideoFrame>

#include <stdexcept>

using namespace lrc::api;

RenderManager::RenderManager(AVModel& avModel)
    : avModel_(avModel)
{
    previewFrameWrapper_ = std::make_unique<FrameWrapper>(avModel_);

    avModel_.useAVFrame(!useOldPipline_);

    QObject::connect(previewFrameWrapper_.get(),
                     &FrameWrapper::frameUpdated,
                     [this](const QString& id) {
                         Q_UNUSED(id);
                         emit previewFrameUpdated();
                     });
    QObject::connect(previewFrameWrapper_.get(),
                     &FrameWrapper::renderingStopped,
                     [this](const QString& id) {
                         Q_UNUSED(id);
                         emit previewRenderingStopped();
                     });
    QObject::connect(previewFrameWrapper_.get(),
                     &FrameWrapper::avFrameUpdated,
                     [this](const QString& id) {
                         Q_UNUSED(id);
                         emit previewAvFrameUpdated();
                     });

    previewFrameWrapper_->connectStartRendering();
}

RenderManager::~RenderManager()
{
    previewFrameWrapper_.reset();

    for (auto& dfw : distantFrameWrapperMap_) {
        dfw.second.reset();
    }
}

bool
RenderManager::isPreviewing()
{
    return previewFrameWrapper_->isRendering();
}

void
RenderManager::stopPreviewing()
{
    if (!previewFrameWrapper_->isRendering()) {
        return;
    }

    previewFrameWrapper_->stopRendering();
    avModel_.stopPreview();
}

void
RenderManager::startPreviewing(bool force)
{
    if (previewFrameWrapper_->isRendering() && !force) {
        return;
    }

    if (previewFrameWrapper_->isRendering()) {
        avModel_.stopPreview();
    }
    avModel_.startPreview();
}

void
RenderManager::addDistantRenderer(const QString& id)
{
    /*
     * Check if a FrameWrapper with this id exists.
     */
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
        if (!dfwIt->second->startRendering()) {
            qWarning() << "Couldn't start rendering for id: " << id;
        }
    } else {
        auto dfw = std::make_unique<FrameWrapper>(avModel_, id);

        /*
         * Connect this to the FrameWrapper.
         */
        distantConnectionMap_[id].updated = QObject::connect(dfw.get(),
                                                             &FrameWrapper::frameUpdated,
                                                             [this](const QString& id) {
                                                                 emit distantFrameUpdated(id);
                                                             });
        distantConnectionMap_[id].updated = QObject::connect(dfw.get(),
                                                             &FrameWrapper::avFrameUpdated,
                                                             [this](const QString& id) {
                                                                 emit distantAVFrameUpdated(id);
                                                             });

        /*
         * Connect FrameWrapper to avmodel.
         */
        dfw->connectStartRendering();
        try {
            /*
             * If the renderer has already started, then start the slot.
             */
            if (avModel_.getRenderer(id).isRendering())
                dfw->slotRenderingStarted(id);
        } catch (...) {
        }

        /*
         * Add to map.
         */
        distantFrameWrapperMap_.insert(std::make_pair(id, std::move(dfw)));
    }
}

void
RenderManager::removeDistantRenderer(const QString& id)
{
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
        /*
         * Disconnect FrameWrapper from this.
         */
        auto dcIt = distantConnectionMap_.find(id);
        if (dcIt != distantConnectionMap_.end()) {
            QObject::disconnect(dcIt->second.started);
            QObject::disconnect(dcIt->second.updated);
        }

        /*
         * Erase.
         */
        distantFrameWrapperMap_.erase(dfwIt);
    }
}

AVFrame*
RenderManager::getAVFrame(const QString& id)
{
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
        return dfwIt->second->getAVFrame();
    }
    return nullptr;
}

QImage*
RenderManager::getPreviewFrame()
{
    return previewFrameWrapper_->getFrame();
}

AVFrame*
RenderManager::getPreviewAVFrame()
{
    return previewFrameWrapper_->getAVFrame();
}

bool
RenderManager::requestPreviewFrameMutexTryLock()
{
    return previewFrameWrapper_->frameMutexTryLock();
}

void
RenderManager::requestPreviewFrameMutexUnLock()
{
    previewFrameWrapper_->frameMutexUnlock();
}

bool
RenderManager::requestDistantFrameMutexTryLock(const QString& id)
{
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
        return dfwIt->second->frameMutexTryLock();
    }
    return false;
}

void
RenderManager::requestDistantFrameMutexUnLock(const QString& id)
{
    auto dfwIt = distantFrameWrapperMap_.find(id);
    if (dfwIt != distantFrameWrapperMap_.end()) {
         dfwIt->second->frameMutexUnlock();
    }
}
