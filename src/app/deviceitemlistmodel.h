/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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

class DeviceItemListModel final : public AbstractListModelBase
{
    Q_OBJECT

public:
    enum Role { DeviceName = Qt::UserRole + 1, DeviceID, IsCurrent };
    Q_ENUM(Role)

    explicit DeviceItemListModel(LRCInstance* instance, QObject* parent = nullptr);

    // QAbstractListModel override.
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    // This function is to reset the model when there's new account added.
    Q_INVOKABLE void reset();
    Q_INVOKABLE void revokeDevice(QString deviceId, QString password);

public Q_SLOTS:
    void connectAccount();
};
