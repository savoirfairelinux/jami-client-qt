/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
            &AvatarRegistry::connectAccount,
            Qt::DirectConnection);

    connect(&lrcInstance_->accountModel(), &AccountModel::profileUpdated, this, &AvatarRegistry::addOrUpdateImage);

    connect(lrcInstance_, &LRCInstance::base64SwarmAvatarChanged, this, [&] { addOrUpdateImage("temp"); });

    if (!lrcInstance_->get_currentAccountId().isEmpty())
        connectAccount();
}

QString
AvatarRegistry::addOrUpdateImage(const QString& id)
{
    auto uid = Utils::generateUid();
    auto it = uidMap_.find(id);
    if (it == uidMap_.end()) {
        uidMap_.insert(id, uid);
    } else {
        it.value() = uid;
        Q_EMIT avatarUidChanged(id);
    }
    return uid;
}
// HACK: There is still a timing issue with when this function is called.
// The reason that avatar duplication was happening is that when the LRC account id is changed via
// the account combobox, the ui updates itself and calls getUID for the avatars that it needs to
// load, although by this point, the cache has not yet been cleared here. This ends up executing
// after the getUID calls.
void
AvatarRegistry::connectAccount()
{
    clearCache();
    connect(lrcInstance_->getCurrentContactModel(),
            &ContactModel::profileUpdated,
            this,
            &AvatarRegistry::onProfileUpdated,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::profileUpdated,
            this,
            &AvatarRegistry::addOrUpdateImage,
            Qt::UniqueConnection);
}

void
AvatarRegistry::onProfileUpdated(const QString& uri)
{
    auto& convInfo = lrcInstance_->getConversationFromPeerUri(uri);
    addOrUpdateImage(uri);
    if (convInfo.uid.isEmpty())
        return;

    addOrUpdateImage(convInfo.uid);
}

QString
AvatarRegistry::getUid(const QString& id)
{
    auto it = uidMap_.find(id);
    if (it == uidMap_.end()) {
        return addOrUpdateImage(id);
    }
    return it.value();
}

void
AvatarRegistry::clearCache()
{
    uidMap_.clear();
}
