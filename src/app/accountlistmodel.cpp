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

#include "api/accountmodel.h"

AccountListModel::AccountListModel(LRCInstance* instance, QObject* parent)
    : QIdentityProxyModel(parent)
    , lrcInstance_(instance)
{
    setSourceModel(&lrcInstance_->accountModel());
}

void
AccountListModel::updateNotifications()
{
    auto* src = sourceModel();
    if (!src)
        return;
    for (int i = 0; i < src->rowCount(); ++i) {
        QModelIndex modelIndex = src->index(i, 0);
        Q_EMIT src->dataChanged(modelIndex, modelIndex, {AccountList::NotificationCount});
    }
}

void
AccountListModel::reset()
{
    // Force proxy invalidation
    beginResetModel();
    endResetModel();
}
