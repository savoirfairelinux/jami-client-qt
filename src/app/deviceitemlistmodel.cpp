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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "deviceitemlistmodel.h"

#include "lrcinstance.h"

#include "api/devicemodel.h"

DeviceItemListModel::DeviceItemListModel(LRCInstance* instance, QObject* parent)
    : QIdentityProxyModel(parent)
    , lrcInstance_(instance)
{
    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &DeviceItemListModel::connectAccount,
            Qt::UniqueConnection);

    connectAccount();
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
        setSourceModel(nullptr);
        return;
    }
    setSourceModel(lrcInstance_->getCurrentAccountInfo().deviceModel.get());
}
