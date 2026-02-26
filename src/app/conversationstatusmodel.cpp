/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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

#include "conversationstatusmodel.h"

#include <algorithm>

ConversationStatusModel::ConversationStatusModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, this, &ConversationStatusModel::resetData);
}

int
ConversationStatusModel::rowCount(const QModelIndex& parent) const
{
    return peerIds_.size();
}

QVariant
ConversationStatusModel::data(const QModelIndex& index, int role) const
{
    const auto accountId = lrcInstance_->get_currentAccountId();

    if (accountId.isEmpty()) {
        qWarning() << "ConversationStatusModel::data: accountId or peerID is empty";
        return {};
    }
    const auto& peerId = peerIds_[index.row()];
    const auto& peerData = peerData_[peerId];
    switch (role) {
    case ConversationStatus::ConnectionDatas: {
        QString peerString;
        peerString += "Peer: " + peerId;
        for (const auto& [connectionId, data] : peerData.asKeyValueRange()) {
            peerString += ",\n    {";
            peerString += "Device: " + data["device"].toString();
            peerString += ", Status: " + data["status"].toString();
            peerString += ", Remote IP address: " + data["remoteAddress"].toString();
            peerString += "}";
        }
        return peerString;
    }
    case ConversationStatus::PeerId:
        return peerId;
    case ConversationStatus::RemoteAddress: {
        QVariantMap remoteAddressMap;
        int i = 0;
        for (const auto& data : peerData) {
            remoteAddressMap.insert(QString::number(i++), data["remoteAddress"]);
        }
        return QVariant(remoteAddressMap);
    }
    case ConversationStatus::DeviceId: {
        QVariantMap deviceMap;
        int i = 0;
        for (const auto& data : peerData) {
            deviceMap.insert(QString::number(i++), data["device"]);
        }
        return QVariant(deviceMap);
    }
    case ConversationStatus::Status: {
        QVariantMap statusMap;
        int i = 0;
        for (const auto& data : peerData) {
            auto status = data["status"].toString();
            int statusInt = 4;
            if (status == "connected") {
                statusInt = 0;
            } else if (status == "connecting") {
                statusInt = 3;
            }
            statusMap.insert(QString::number(i++), statusInt);
        }
        return QVariantMap(statusMap);
    }
    case ConversationStatus::IsMobile: {
        QVariantMap mobileMap;
        int i = 0;
        for (const auto& data : peerData) {
            mobileMap.insert(QString::number(i++), data["mobile"]);
        }
        return QVariant(mobileMap);
    }
    case ConversationStatus::ConnectionTime: {
        QVariantMap connectionTimeMap;
        int i = 0;
        for (const auto& data : peerData) {
            connectionTimeMap.insert(QString::number(i++), data["connectionTime"]);
        }
        return QVariant(connectionTimeMap);
    }
    case ConversationStatus::Count:
        return peerData.size();
    }
    return {};
}

QHash<int, QByteArray>
ConversationStatusModel::roleNames() const
{
    using namespace ConversationStatus;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    CONVERSATIONSTATUS_ROLES
#undef X
    return roles;
}

void
ConversationStatusModel::update()
{
    aggregateData();
}

QString
ConversationStatusModel::conversationId() const
{
    return conversationId_;
}

void
ConversationStatusModel::setConversationId(const QString& conversationId)
{
    if (conversationId_ != conversationId) {
        conversationId_ = conversationId;
        Q_EMIT conversationIdChanged();
        aggregateData();
    }
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
ConversationStatusModel::aggregateData()
{
    const auto accountId = lrcInstance_->get_currentAccountId();
    if (accountId.isEmpty() || conversationId_.isEmpty()) {
        resetData();
        return;
    }

    connectionInfoList_ = lrcInstance_->getConversationConnectivity(accountId, conversationId_);

    peerData_ = {};

    QSet<QString> newPeerIds;
    for (const auto& connectionInfo : connectionInfoList_) {
        const auto& peerId = connectionInfo["id"];
        if (peerId.isEmpty())
            continue;

        newPeerIds.insert(peerId);
        const auto& id = peerId;
        peerData_[peerId][id]["id"] = id;
        peerData_[peerId][id]["device"] = connectionInfo["device"];
        peerData_[peerId][id]["status"] = connectionInfo["status"];
        peerData_[peerId][id]["remoteAddress"] = connectionInfo["remoteAddress"];
        peerData_[peerId][id]["mobile"] = connectionInfo["mobile"];
        peerData_[peerId][id]["connectionTime"] = connectionInfo["connectionTime"];
    }

    QVector<QString> newPeerIdsVec(newPeerIds.begin(), newPeerIds.end());
    std::sort(newPeerIdsVec.begin(), newPeerIdsVec.end());

    auto [added, removed] = getSetDiff(peerIds_, newPeerIdsVec);

    if (!removed.isEmpty()) {
        for (const auto& peerId : removed) {
            int row = peerIds_.indexOf(peerId);
            beginRemoveRows(QModelIndex(), row, row);
            peerIds_.removeAt(row);
            endRemoveRows();
        }
    }

    if (!added.isEmpty()) {
        for (const auto& peerId : added) {
            // Find the correct insertion point to keep the list sorted
            auto it = std::lower_bound(peerIds_.begin(), peerIds_.end(), peerId);
            int row = std::distance(peerIds_.begin(), it);
            beginInsertRows(QModelIndex(), row, row);
            peerIds_.insert(row, peerId);
            endInsertRows();
        }
    }

    // Emit dataChanged for existing rows that might have updated data
    if (!peerIds_.isEmpty()) {
        Q_EMIT dataChanged(index(0, 0), index(peerIds_.size() - 1, 0));
    }
}

void
ConversationStatusModel::resetData()
{
    beginResetModel();
    peerIds_.clear();
    peerData_.clear();
    endResetModel();
}
