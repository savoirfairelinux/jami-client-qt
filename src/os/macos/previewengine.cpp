/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
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

#include "previewengine.h"

PreviewEngine::PreviewEngine(QObject* parent) {}

void
PreviewEngine::parseMessage(const QString& messageId, const QString& msg, bool showPreview)
{}

void
PreviewEnginePrivate::log(const QString& str)
{}

void
PreviewEnginePrivate::infoReady(const QString& messageId, const QVariantMap& info)
{}

void
PreviewEnginePrivate::linkifyReady(const QString& messageId, const QString& linkified)
{}
