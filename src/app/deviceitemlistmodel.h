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

#pragma once

#include <QIdentityProxyModel>

class LRCInstance;

class DeviceItemListModel final : public QIdentityProxyModel
{
    Q_OBJECT

public:
    explicit DeviceItemListModel(LRCInstance* instance, QObject* parent = nullptr);

    Q_INVOKABLE void revokeDevice(QString deviceId, QString password);

public Q_SLOTS:
    void connectAccount();

private:
    LRCInstance* lrcInstance_ {nullptr};
};
