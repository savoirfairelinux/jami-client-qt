/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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

#include "bannedlistmodel.h"

#include "lrcinstance.h"

BannedListModel::BannedListModel(QObject* parent)
    : AbstractListModelBase(parent)

{
    connect(this, &BannedListModel::lrcInstanceChanged, [this]() {
        // Listen for account change and reconnect to the new account contact model.
        connect(lrcInstance_,
                &LRCInstance::currentAccountIdChanged,
                this,
                &BannedListModel::setupForAccount);
        setupForAccount();
    });
}

BannedListModel::~BannedListModel() {}

int
BannedListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_)
        return bannedlist_.size();
    return 0;
}

QVariant
BannedListModel::data(const QModelIndex& index, int role) const
{
    try {
        auto contactList = bannedlist_;
        if (!index.isValid() || contactList.size() <= index.row()) {
            return QVariant();
        }

        auto contactInfo = lrcInstance_->getCurrentAccountInfo().contactModel->getContact(
            contactList.at(index.row()));

        switch (role) {
        case Role::ContactName:
            return QVariant(contactInfo.registeredName);
        case Role::ContactID:
            return QVariant(contactInfo.profileInfo.uri);
        }
    } catch (const std::out_of_range& e) {
        qDebug() << e.what();
    }
    return QVariant();
}

QHash<int, QByteArray>
BannedListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[ContactName] = "ContactName";
    roles[ContactID] = "ContactID";
    return roles;
}

QModelIndex
BannedListModel::index(int row, int column, const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    if (column != 0) {
        return QModelIndex();
    }

    if (row >= 0 && row < rowCount()) {
        return createIndex(row, column);
    }
    return QModelIndex();
}

Qt::ItemFlags
BannedListModel::flags(const QModelIndex& index) const
{
    auto flags = QAbstractItemModel::flags(index) | Qt::ItemNeverHasChildren | Qt::ItemIsSelectable;
    if (!index.isValid()) {
        return QAbstractItemModel::flags(index);
    }
    return flags;
}

void
BannedListModel::reset()
{
    beginResetModel();
    bannedlist_ = lrcInstance_->getCurrentAccountInfo().contactModel->getBannedContacts();
    endResetModel();
    set_count(rowCount());
}

void
BannedListModel::setupForAccount()
{
    if (lrcInstance_ && lrcInstance_->getCurrentContactModel()) {
        connect(lrcInstance_->getCurrentContactModel(),
                &ContactModel::bannedStatusChanged,
                this,
                &BannedListModel::onBannedStatusChanged,
                Qt::UniqueConnection);
    }
    reset();
}

void
BannedListModel::onBannedStatusChanged(const QString& uri, bool banned)
{
    if (banned) {
        beginInsertRows(QModelIndex(), rowCount(), rowCount());
        bannedlist_.append(uri);
        endInsertRows();
        set_count(rowCount());
    } else {
        auto it = std::find_if(bannedlist_.begin(), bannedlist_.end(), [&uri](const auto& c) {
            return uri == c;
        });
        if (it != bannedlist_.end()) {
            auto elementIndex = std::distance(bannedlist_.begin(), it);
            beginRemoveRows(QModelIndex(), elementIndex, elementIndex);
            bannedlist_.remove(elementIndex);
            endRemoveRows();
            set_count(rowCount());
        }
    }
}
