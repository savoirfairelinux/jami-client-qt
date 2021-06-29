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

#pragma once

#include <QObject>
#include <QMap>

class LRCInstance;

class AvatarRegistry : public QObject
{
    Q_OBJECT
public:
    enum class Type { Default, Fallback, Base64, Account, Conv };
    Q_ENUM(Type)
    Q_INVOKABLE QString typeToString(const Type& type);

    explicit AvatarRegistry(LRCInstance* instance, QObject* parent = nullptr);
    ~AvatarRegistry() = default;

    // fill for contacts, conversations, and accounts
    void loadAllImages();

    // add or update a specific image in the cache
    void addOrUpdateImage();

private:
    // AvatarImageProvider image uid cache helper
    QMap<QString, QString> avatarUidMap_;

    LRCInstance* lrcInstance_;
};
