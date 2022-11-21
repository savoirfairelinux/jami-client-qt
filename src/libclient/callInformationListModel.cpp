/*
 *  Copyright (C) 2023 Savoir-faire Linux Inc.
 *
 *  Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */

#include "callInformationListModel.h"

CallInformationListModel::CallInformationListModel(QObject* parent)
    : QAbstractListModel(parent)
{}

int
CallInformationListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return callIds_.size();
}

QVariant
CallInformationListModel::data(const QModelIndex& index, int role) const
{
    switch (role) {
    case Role::CALL_ID:
        return callIds_[index.row()].first;
    case Role::PEER_NUMBER:
        return callIds_[index.row()].second["PEER_NUMBER"];
    case Role::HARDWARE_ACCELERATION:
        return callIds_[index.row()].second["HARDWARE_ACCELERATION"];
    case Role::SOCKETS:
        return callIds_[index.row()].second["SOCKETS"];
    case Role::VIDEO_CODEC:
        return callIds_[index.row()].second["VIDEO_CODEC"];
    case Role::AUDIO_CODEC:
        return callIds_[index.row()].second["AUDIO_CODEC"];
    case Role::VIDEO_BITRATE:
        return callIds_[index.row()].second["VIDEO_BITRATE"];
    }

    return QVariant();
}

void
CallInformationListModel::addElement(QPair<QString, MapStringString> callInfo)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    callIds_.append(callInfo);
    endInsertRows();
}

void
CallInformationListModel::editElement(QPair<QString, MapStringString> callInfo)
{
    auto it = std::find_if(callIds_.begin(), callIds_.end(), [&callInfo](const auto& c) {
        return callInfo.first == c.first;
    });
    if (it != callIds_.end()) {
        // update infos
        auto index = std::distance(callIds_.begin(), it);
        QModelIndex modelIndex = QAbstractListModel::index(index, 0);
        it->second = callInfo.second;
        Q_EMIT dataChanged(modelIndex, modelIndex);
    }
}

QHash<int, QByteArray>
CallInformationListModel::roleNames() const
{
    using namespace InfoList;
    QHash<int, QByteArray> roles;
#define X(var) roles[var] = #var;
    CALLINFO_ROLES
#undef X
    return roles;
}

void
CallInformationListModel::resetList()
{
    beginResetModel();
    callIds_.clear();
    endResetModel();
}

bool
CallInformationListModel::isRowAlreadyExists(QString callId)
{
    for (auto i : callIds_) {
        if (i.first == callId)
            return true;
    }
    return false;
}

void
CallInformationListModel::removeElement(QString callId)
{
    auto it = std::find_if(callIds_.begin(), callIds_.end(), [&callId](const auto& c) {
        return callId == c.first;
    });
    if (it != callIds_.end()) {
        auto elementIndex = std::distance(callIds_.begin(), it);
        beginRemoveRows(QModelIndex(), elementIndex, elementIndex);
        callIds_.remove(elementIndex);
        endRemoveRows();
    }
}
