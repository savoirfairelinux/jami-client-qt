/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

#include "avatarregistry.h"

#include "lrcinstance.h"

AvatarRegistry::AvatarRegistry(LRCInstance* instance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(instance)
{
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, [this] { loadAllImages(); });
}

void
AvatarRegistry::loadAllImages()
{
    auto contacts = lrcInstance_->getCurrentAccountInfo().contactModel->getAllContacts();
    avatarUidMap_.clear();
    auto peerUris = contacts.keys();
    Q_FOREACH (const auto& id, peerUris) {
        avatarUidMap_.insert(id, Utils::generateUid());
    }
}

void
AvatarRegistry::addOrUpdateImage(const QString& id, bool quiet)
{
    auto uid = Utils::generateUid();
    auto it = avatarUidMap_.find(id);
    if (it == avatarUidMap_.end()) {
        avatarUidMap_.insert(id, uid);
    } else {
        it.value() = uid;
    }
    if (!quiet)
        Q_EMIT avatarUidChanged(id);
}

QString
AvatarRegistry::getUid(const QString& id)
{
    auto it = avatarUidMap_.find(id);
    if (it == avatarUidMap_.end()) {
        addOrUpdateImage(id, true);
        return {};
    }
    return it.value();
}
