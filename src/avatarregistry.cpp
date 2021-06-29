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

QString
AvatarRegistry::typeToString(const AvatarRegistry::Type& type)
{
    switch (type) {
    case Type::Default:
        return "d_";
    case Type::Fallback:
        return "f_";
    case Type::Base64:
        return "b_";
    case Type::Account:
        return "a_";
    case Type::Conv:
        return "c_";
    }
}

AvatarRegistry::AvatarRegistry(LRCInstance* instance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(instance)
{
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, [this] { loadAllImages(); });
}

void
AvatarRegistry::loadAllImages()
{
    //    auto contacts = lrcInstance_->getCurrentAccountInfo().contactModel->getAllContacts();
    //    avatarUidMap_.clear();
    //    auto contactsKeys = contacts.keys();
    //    Q_FOREACH(const auto& key, contactsKeys) {
    //        auto uid = typeToString(Type::C) + Utils::generateUid();
    //        avatarUidMap_.insert(key, );
    //    }
}

void
AvatarRegistry::addOrUpdateImage()
{}
