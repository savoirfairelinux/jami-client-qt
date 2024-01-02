/*
 *  Copyright (C) 2024 Savoir-faire Linux Inc.
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
    return callsInfolist_.size();
}

QVariant
CallInformationListModel::data(const QModelIndex& index, int role) const
{
    using namespace InfoList;
    if (role == Role::CALL_ID)
        return callsInfolist_[index.row()].first;
    switch (role) {
#define X(var) \
    case Role::var: \
        return callsInfolist_[index.row()].second[#var];
        CALLINFO_ROLES
#undef X
    }

    return QVariant();
}

bool
CallInformationListModel::addElement(QPair<QString, MapStringString> callInfo)
{
    // check element existence
    auto callId = callInfo.first;
    auto it = std::find_if(callsInfolist_.begin(), callsInfolist_.end(), [&callId](const auto& c) {
        return callId == c.first;
    });
    // if element doesn't exist
    if (it == callsInfolist_.end()) {
        beginInsertRows(QModelIndex(), rowCount(), rowCount());
        callsInfolist_.append(callInfo);
        endInsertRows();
        return true;
    }
    return false;
}

void
CallInformationListModel::editElement(QPair<QString, MapStringString> callInfo)
{
    auto it = std::find_if(callsInfolist_.begin(),
                           callsInfolist_.end(),
                           [&callInfo](const auto& c) { return callInfo.first == c.first; });
    if (it != callsInfolist_.end()) {
        // update infos
        auto index = std::distance(callsInfolist_.begin(), it);
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
CallInformationListModel::reset()
{
    beginResetModel();
    callsInfolist_.clear();
    endResetModel();
}

void
CallInformationListModel::removeElement(QString callId)
{
    auto it = std::find_if(callsInfolist_.begin(), callsInfolist_.end(), [&callId](const auto& c) {
        return callId == c.first;
    });
    if (it != callsInfolist_.end()) {
        auto elementIndex = std::distance(callsInfolist_.begin(), it);
        beginRemoveRows(QModelIndex(), elementIndex, elementIndex);
        callsInfolist_.remove(elementIndex);
        endRemoveRows();
    }
}
