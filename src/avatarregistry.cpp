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
    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &AvatarRegistry::onCurrentAccountIdChanged);
}

void
AvatarRegistry::addOrUpdateImage(const QString& id)
{
    qDebug() << "addOrUpdateImage" << id;
    auto uid = Utils::generateUid();
    auto it = uidMap_.find(id);
    if (it == uidMap_.end()) {
        uidMap_.insert(id, uid);
    } else {
        it.value() = uid;
    }
    Q_EMIT avatarUidChanged(id);
}

void
AvatarRegistry::onCurrentAccountIdChanged()
{
    qDebug() << "onCurrentAccountIdChanged";
    connect(lrcInstance_->getCurrentContactModel(),
            &ContactModel::profileUpdated,
            this,
            &AvatarRegistry::onProfileUpdated,
            Qt::UniqueConnection);
}

void
AvatarRegistry::onProfileUpdated(const QString& id)
{
    qDebug() << "onProfileUpdated2" << id;
    addOrUpdateImage(id);
}

QString
AvatarRegistry::getUid(const QString& id)
{
    auto it = uidMap_.find(id);
    if (it == uidMap_.end()) {
        addOrUpdateImage(id);
        return {};
    }
    return it.value();
}
