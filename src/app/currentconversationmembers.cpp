/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

#include "currentconversationmembers.h"

#include <algorithm>
#include <random>

CurrentConversationMembers::CurrentConversationMembers(LRCInstance* lrcInstance, QObject* parent)
    : QAbstractListModel(parent)
    , lrcInstance_(lrcInstance)
{}

int
CurrentConversationMembers::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return members_.size();
}

void
CurrentConversationMembers::setMembers(const QString& accountId,
                                       const QString& convId,
                                       const QStringList& members)
{
    beginResetModel();
    accountId_ = accountId;
    convId_ = convId;
    members_ = members;
    set_count(members.size());
    endResetModel();
}

QVariant
CurrentConversationMembers::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    auto member = members_.at(index.row());

    switch (role) {
    case Members::Role::MemberUri:
        return QVariant::fromValue(member);
    case Members::Role::MemberRole:
        return QVariant::fromValue(
            lrcInstance_->getAccountInfo(accountId_).conversationModel->memberRole(convId_, member));
    }
    return QVariant();
}

QHash<int, QByteArray>
CurrentConversationMembers::roleNames() const
{
    using namespace Members;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    MEMBERS_ROLES
#undef X
    return roles;
}
