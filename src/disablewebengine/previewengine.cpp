/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
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

#include "previewengine.h"

class PreviewEngine::Impl : public QObject
{
public:
    Impl(PreviewEngine& parent)
        : QObject(nullptr)
    {}
};

PreviewEngine::PreviewEngine(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(*this))
{}

PreviewEngine::~PreviewEngine() {}

void
PreviewEngine::parseMessage(const QString& messageId, const QString& msg, bool showPreview)
{}

void
PreviewEngine::log(const QString& str)
{}

void
PreviewEngine::infoReady(const QString& messageId, const QVariantMap& info)
{}

void
PreviewEngine::linkifyReady(const QString& messageId, const QString& linkified)
{}
