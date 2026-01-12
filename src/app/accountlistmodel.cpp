/*
 * Copyright (C) 2019-2026 Savoir-faire Linux Inc.
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

#include "accountlistmodel.h"

#include "lrcinstance.h"

#include "api/account.h"

#include <QDateTime>

AccountListModel::AccountListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;

    // Avoid resetting/redrawing the model when the account status changes.
    QObject::connect(&lrcInstance_->accountModel(),
                     &AccountModel::accountStatusChanged,
                     this,
                     [&](const QString& accountId) {
                         auto accountList = lrcInstance_->accountModel().getAccountList();
                         auto index = accountList.indexOf(accountId);
                         if (index != -1) {
                             QModelIndex modelIndex = QAbstractListModel::index(index, 0);
                             Q_EMIT dataChanged(modelIndex, modelIndex /*, ALL ROLES */);
                         }
                     });
    // If there's a reorder, it's reasonable to reset the model for simplicity, instead
    // of computing the difference. The same goes for accounts being added and removed.
    // These operations will only occur when the list is hidden, unless dbus is used while
    // the list is visible.
    QObject::connect(&lrcInstance_->accountModel(), &AccountModel::accountsReordered, this, &AccountListModel::reset);
    QObject::connect(&lrcInstance_->accountModel(), &AccountModel::accountAdded, this, &AccountListModel::reset);
    QObject::connect(&lrcInstance_->accountModel(), &AccountModel::accountRemoved, this, &AccountListModel::reset);
}

int
AccountListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return lrcInstance_->accountModel().getAccountCount();
    }
    return 0;
}

QVariant
AccountListModel::data(const QModelIndex& index, int role) const
{
    auto accountList = lrcInstance_->accountModel().getAccountList();
    if (!index.isValid() || accountList.size() <= index.row()) {
        return QVariant();
    }

    auto accountId = accountList.at(index.row());
    auto& accountInfo = lrcInstance_->accountModel().getAccountInfo(accountId);

    switch (role) {
    case Role::Alias:
        return QVariant(lrcInstance_->accountModel().bestNameForAccount(accountId));
    case Role::Username:
        return QVariant(lrcInstance_->accountModel().bestIdForAccount(accountId));
    case Role::Type:
        return QVariant(static_cast<int>(accountInfo.profileInfo.type));
    case Role::Status:
        return QVariant(static_cast<int>(accountInfo.status));
    case Role::NotificationCount:
        return QVariant(static_cast<int>(accountInfo.conversationModel->notificationsCount()));
    case Role::ID:
        return QVariant(accountInfo.id);
    }
    return QVariant();
}

void
AccountListModel::updateNotifications()
{
    for (int i = 0; i < lrcInstance_->accountModel().getAccountCount(); ++i) {
        QModelIndex modelIndex = QAbstractListModel::index(i, 0);
        Q_EMIT dataChanged(modelIndex, modelIndex, {Role::NotificationCount});
    }
}

QHash<int, QByteArray>
AccountListModel::roleNames() const
{
    using namespace AccountList;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    ACC_ROLES
#undef X
    return roles;
}

void
AccountListModel::reset()
{
    // Used to invalidate proxy models.
    beginResetModel();
    endResetModel();
}
