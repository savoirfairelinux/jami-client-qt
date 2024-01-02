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

#pragma once

#include "abstractlistmodelbase.h"

#define CONNECTONINFO_ROLES \
    X(ConnectionDatas) \
    X(ChannelsMap) \
    X(PeerName) \
    X(PeerId) \
    X(DeviceId) \
    X(Status) \
    X(Channels) \
    X(RemoteAddress) \
    X(Count) // this is the number of connections (convenience)

namespace ConnectionInfoList {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    CONNECTONINFO_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace ConnectionInfoList

class ConnectionInfoListModel : public AbstractListModelBase
{
public:
    explicit ConnectionInfoListModel(LRCInstance* instance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void update();

private:
    using Role = ConnectionInfoList::Role;

    VectorMapStringString connectionInfoList_;

    QVector<QString> peerIds_;
    QMap<QString, QMap<QString, QMap<QString, QVariant>>> peerData_;
    void aggregateData();
    void resetData();
};
