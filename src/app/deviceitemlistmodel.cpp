/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

#include "deviceitemlistmodel.h"

#include "lrcinstance.h"

#include "api/account.h"
#include "api/contact.h"
#include "api/conversation.h"
#include "api/devicemodel.h"

DeviceItemListModel::DeviceItemListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;

    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &DeviceItemListModel::connectAccount,
            Qt::UniqueConnection);

    connectAccount();
}

int
DeviceItemListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return lrcInstance_->getCurrentAccountInfo().deviceModel->getAllDevices().size();
    }
    return 0;
}

QVariant
DeviceItemListModel::data(const QModelIndex& index, int role) const
{
    auto deviceList = lrcInstance_->getCurrentAccountInfo().deviceModel->getAllDevices();
    if (!index.isValid() || deviceList.size() <= index.row()) {
        return QVariant();
    }

    switch (role) {
    case Role::DeviceName:
        return QVariant(deviceList.at(index.row()).name);
    case Role::DeviceID:
        return QVariant(deviceList.at(index.row()).id);
    case Role::IsCurrent:
        return QVariant(deviceList.at(index.row()).isCurrent);
    }
    return QVariant();
}

QHash<int, QByteArray>
DeviceItemListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[DeviceName] = "DeviceName";
    roles[DeviceID] = "DeviceID";
    roles[IsCurrent] = "IsCurrent";
    return roles;
}

Qt::ItemFlags
DeviceItemListModel::flags(const QModelIndex& index) const
{
    auto flags = QAbstractItemModel::flags(index) | Qt::ItemNeverHasChildren | Qt::ItemIsSelectable;
    if (!index.isValid()) {
        return QAbstractItemModel::flags(index);
    }
    return flags;
}

void
DeviceItemListModel::reset()
{
    beginResetModel();
    endResetModel();
}

void
DeviceItemListModel::revokeDevice(QString deviceId, QString password)
{
    lrcInstance_->getCurrentAccountInfo().deviceModel->revokeDevice(deviceId, password);
}

void
DeviceItemListModel::connectAccount()
{
    if (lrcInstance_->get_currentAccountId().isEmpty()) {
        return;
    }

    reset();

    auto* deviceModel = lrcInstance_->getCurrentAccountInfo().deviceModel.get();

    connect(deviceModel,
            &lrc::api::DeviceModel::deviceAdded,
            this,
            &DeviceItemListModel::reset,
            Qt::UniqueConnection);

    connect(deviceModel,
            &lrc::api::DeviceModel::deviceRevoked,
            this,
            &DeviceItemListModel::reset,
            Qt::UniqueConnection);

    connect(deviceModel,
            &lrc::api::DeviceModel::deviceUpdated,
            this,
            &DeviceItemListModel::reset,
            Qt::UniqueConnection);
}
