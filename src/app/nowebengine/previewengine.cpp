/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

struct PreviewEngine::Impl : public QObject
{
    Impl(PreviewEngine&)
        : QObject(nullptr)
    {}
};

PreviewEngine::PreviewEngine(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(*this))
{}

PreviewEngine::~PreviewEngine() {}

void
PreviewEngine::parseMessage(const QString&, const QString&, bool, QColor)
{}

void
PreviewEngine::log(const QString&)
{}

void
PreviewEngine::emitInfoReady(const QString&, const QVariantMap&)
{}

#include "moc_previewengine.cpp"
#include "previewengine.moc"
