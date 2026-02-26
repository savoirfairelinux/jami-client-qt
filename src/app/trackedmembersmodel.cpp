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

#include "trackedmembersmodel.h"

#include <QDebug>

#include <algorithm>
#include <iterator>

TrackedMembersModel::TrackedMembersModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, this, &TrackedMembersModel::resetData);
}

int
TrackedMembersModel::rowCount(const QModelIndex& /* parent */) const
{
    return peerUris_.size();
}

QVariant
TrackedMembersModel::data(const QModelIndex& index, int role) const
{
    const auto accountId = lrcInstance_->get_currentAccountId();

    if (accountId.isEmpty()) {
        qWarning() << "TrackedMembersModel::data: accountId is empty";
        return {};
    }
    const auto& peerUri = peerUris_[index.row()];
    const auto& peerData = peerData_[peerUri];

    switch (role) {
    case TrackedMembers::PeerUri:
        return peerUri;
    case TrackedMembers::Devices:
        return peerData["devices"];
    case TrackedMembers::Details: {
        QString details = "URI: " + peerUri;
        details += "\nDevices: " + peerData["devices"].toString();
        return details;
    }
    case TrackedMembers::Count: {
        auto devices = peerData["devices"].toString();
        if (devices.isEmpty()) {
            return 0;
        }
        return devices.split(";").size();
    }
    }
    return {};
}

QHash<int, QByteArray>
TrackedMembersModel::roleNames() const
{
    using namespace TrackedMembers;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    TRACKEDMEMBERS_ROLES
#undef X
    return roles;
}

void
TrackedMembersModel::update()
{
    aggregateData();
}

QString
TrackedMembersModel::conversationId() const
{
    return conversationId_;
}

void
TrackedMembersModel::setConversationId(const QString& conversationId)
{
    if (conversationId_ != conversationId) {
        conversationId_ = conversationId;
        Q_EMIT conversationIdChanged();
        aggregateData();
    }
}

template<typename T>
std::tuple<QVector<T>, QVector<T>>
getSetDiff(const QVector<T>& u, const QVector<T>& v)
{
    using namespace std;
    QVector<T> a, r;
    set_difference(v.begin(), v.end(), u.begin(), u.end(), inserter(a, a.begin()));
    set_difference(u.begin(), u.end(), v.begin(), v.end(), inserter(r, r.begin()));
    return {a, r};
}

void
TrackedMembersModel::aggregateData()
{
    const auto accountId = lrcInstance_->get_currentAccountId();
    if (accountId.isEmpty() || conversationId_.isEmpty()) {
        resetData();
        return;
    }

    trackedMembersList_ = lrcInstance_->getConversationTrackedMembers(accountId, conversationId_);

    peerData_ = {};

    QSet<QString> newPeerUris;
    for (const auto& member : trackedMembersList_) {
        const auto& uri = member["uri"];
        if (uri.isEmpty())
            continue;

        newPeerUris.insert(uri);
        peerData_[uri]["uri"] = uri;
        peerData_[uri]["devices"] = member["devices"];
    }

    QVector<QString> newPeerUrisVec(newPeerUris.begin(), newPeerUris.end());
    std::sort(newPeerUrisVec.begin(), newPeerUrisVec.end());

    auto [added, removed] = getSetDiff(peerUris_, newPeerUrisVec);

    if (!removed.isEmpty()) {
        for (const auto& uri : removed) {
            int row = peerUris_.indexOf(uri);
            beginRemoveRows(QModelIndex(), row, row);
            peerUris_.removeAt(row);
            endRemoveRows();
        }
    }

    if (!added.isEmpty()) {
        for (const auto& uri : added) {
            auto it = std::lower_bound(peerUris_.begin(), peerUris_.end(), uri);
            int row = std::distance(peerUris_.begin(), it);
            beginInsertRows(QModelIndex(), row, row);
            peerUris_.insert(row, uri);
            endInsertRows();
        }
    }

    if (!peerUris_.isEmpty()) {
        Q_EMIT dataChanged(index(0, 0), index(peerUris_.size() - 1, 0));
    }
}

void
TrackedMembersModel::resetData()
{
    beginResetModel();
    peerUris_.clear();
    peerData_.clear();
    endResetModel();
}
