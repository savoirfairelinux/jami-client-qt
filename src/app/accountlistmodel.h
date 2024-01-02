/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Mingrui Zhang   <mingrui.zhang@savoirfairelinux.com>
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

#pragma once

#include "abstractlistmodelbase.h"

#define ACC_ROLES \
    X(Alias) \
    X(Username) \
    X(Type) \
    X(Status) \
    X(NotificationCount) \
    X(ID)

namespace AccountList {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    ACC_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace AccountList

class AccountListModel final : public AbstractListModelBase
{
    Q_OBJECT

public:
    explicit AccountListModel(LRCInstance* instance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // reset the model when there's new account added
    Q_INVOKABLE void reset();

    void updateNotifications();

protected:
    using Role = AccountList::Role;
};
