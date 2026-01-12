/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

#include "connectioninfolistmodel.h"

#include <algorithm>

ConnectionInfoListModel::ConnectionInfoListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, this, &ConnectionInfoListModel::resetData);
}

int
ConnectionInfoListModel::rowCount(const QModelIndex& parent) const
{
    return peerIds_.size();
}

QVariant
ConnectionInfoListModel::data(const QModelIndex& index, int role) const
{
    const auto accountId = lrcInstance_->get_currentAccountId();

    if (accountId.isEmpty()) {
        qWarning() << "ConnectionInfoListModel::data: accountId or peerID is empty";
        return {};
    }
    const auto& peerId = peerIds_[index.row()];
    const auto& peerData = peerData_[peerId];
    switch (role) {
    case ConnectionInfoList::ChannelsMap: {
        QVariantMap channelsMapMap;
        int i = 0;
        for (const auto& data : peerData) {
            QVariantMap channelsMap;
            const auto channelInfoList = lrcInstance_->getChannelList(accountId, data["id"].toString());
            for (const auto& channelInfo : channelInfoList) {
                channelsMap.insert(channelInfo["id"], channelInfo["name"]);
            }
            channelsMapMap.insert(QString::number(i++), channelsMap);
        }
        return QVariant(channelsMapMap);
    }
    case ConnectionInfoList::ConnectionDatas: {
        QString peerString;
        peerString += "Peer: " + peerId;
        for (const auto& [connectionId, data] : peerData.asKeyValueRange()) {
            peerString += ",\n    {";
            peerString += "Device: " + data["device"].toString();
            peerString += ", Status: " + data["status"].toString();
            peerString += ", Channel(s): " + data["channels"].toString();
            peerString += ", Remote IP address: " + data["remoteAddress"].toString();
            peerString += "}";
        }
        return peerString;
    }
    case ConnectionInfoList::PeerId:
        return peerId;
    case ConnectionInfoList::RemoteAddress: {
        QVariantMap remoteAddressMap;
        int i = 0;
        for (const auto& data : peerData) {
            remoteAddressMap.insert(QString::number(i++), data["remoteAddress"]);
        }
        return QVariant(remoteAddressMap);
    }
    case ConnectionInfoList::DeviceId: {
        QVariantMap deviceMap;
        int i = 0;
        for (const auto& data : peerData) {
            deviceMap.insert(QString::number(i++), data["device"]);
        }
        return QVariant(deviceMap);
    }
    case ConnectionInfoList::Status: {
        QVariantMap statusMap;
        int i = 0;
        for (const auto& data : peerData) {
            statusMap.insert(QString::number(i++), data["status"]);
        }
        return QVariantMap(statusMap);
    }
    case ConnectionInfoList::Channels: {
        QVariantMap channelsMap;
        int i = 0;
        for (const auto& data : peerData) {
            channelsMap.insert(QString::number(i++), data["channels"]);
        }
        return QVariant(channelsMap);
    }
    case ConnectionInfoList::Count:
        return peerData.size();
    }
    return {};
}

QHash<int, QByteArray>
ConnectionInfoListModel::roleNames() const
{
    using namespace ConnectionInfoList;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    CONNECTONINFO_ROLES
#undef X
    return roles;
}

void
ConnectionInfoListModel::update()
{
    aggregateData();
}

template<typename T>
std::tuple<QVector<T>, QVector<T>>
getSetDiff(QVector<T> u, QVector<T> v)
{
    using namespace std;
    QVector<T> a, r;
    set_difference(v.begin(), v.end(), u.begin(), u.end(), inserter(a, a.begin()));
    set_difference(u.begin(), u.end(), v.begin(), v.end(), inserter(r, r.begin()));
    return {a, r};
}

void
ConnectionInfoListModel::aggregateData()
{
    const auto accountId = lrcInstance_->get_currentAccountId();
    if (accountId.isEmpty()) {
        return;
    }

    connectionInfoList_ = lrcInstance_->getConnectionList(accountId);

    peerData_ = {};

    QSet<QString> newPeerIds;
    for (const auto& connectionInfo : connectionInfoList_) {
        const auto& peerId = connectionInfo["peer"];
        if (peerId.isEmpty())
            continue;
        newPeerIds.insert(peerId);
        const auto& id = connectionInfo["id"];
        peerData_[peerId][id] = {
            {"id", id},
            {"device", connectionInfo["device"]},
            {"status", connectionInfo["status"].toUInt()},
            {"channels", lrcInstance_->getChannelList(accountId, id).size()},
            {"remoteAddress", connectionInfo["remoteAddress"]},
        };
    }

    QVector<QString> oldVector;
    oldVector.reserve(peerIds_.size());
    for (const auto& peerId : peerIds_) {
        oldVector << peerId;
    }
    std::sort(oldVector.begin(), oldVector.end());

    QVector<QString> newVector;
    newVector.reserve(newPeerIds.size());
    for (const auto& peerId : newPeerIds) {
        newVector << peerId;
    }
    std::sort(newVector.begin(), newVector.end());

    auto [added, removed] = getSetDiff(oldVector, newVector);
    Q_FOREACH (const auto& key, removed) {
        auto index = peerIds_.indexOf(key);
        if (index < 0)
            continue;
        beginRemoveRows(QModelIndex(), index, index);
        peerIds_.remove(index);
        endRemoveRows();
    }
    Q_FOREACH (const auto& key, added) {
        auto it = std::lower_bound(peerIds_.cbegin(), peerIds_.cend(), key);
        auto index = std::distance(peerIds_.cbegin(), it);
        beginInsertRows(QModelIndex(), index, index);
        peerIds_.insert(index, key);
        endInsertRows();
    }

    // HACK: loop through all the peerIds_ and update the data for each one.
    // This is not efficient, but it works.
    Q_FOREACH (const auto& peerId, peerIds_) {
        auto index = std::distance(peerIds_.begin(), std::find(peerIds_.begin(), peerIds_.end(), peerId));
        Q_EMIT dataChanged(this->index(index), this->index(index));
    }
}

void
ConnectionInfoListModel::resetData()
{
    beginResetModel();
    peerIds_.clear();
    peerData_.clear();
    endResetModel();
}
