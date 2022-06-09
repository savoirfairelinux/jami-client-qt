/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

#include "activecallsmodel.h"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QQuickItem>

#include "currentconversation.h"

ActiveCallsModel::ActiveCallsModel(QObject* parent, LRCInstance* lrcInstance)
    : QAbstractListModel(parent)
    , lrcInstance_(lrcInstance)
{}

int
ActiveCallsModel::rowCount(const QModelIndex& idx) const
{
    if (idx.isValid())
        return 0;
    // Internal call, so no need to protect participants_ as locked higher
    return static_cast<CurrentConversation*>(parent())->activeCalls().size();
}

QVariant
ActiveCallsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    using namespace ActiveCalls;
    auto& call = static_cast<CurrentConversation*>(parent())->activeCalls().at(index.row());

    switch (role) {
    case Role::Id:
        return QVariant(call["id"]);
    case Role::Uri:
        return QVariant(call["uri"]);
    case Role::Device:
        return QVariant(call["device"]);
    case Role::Ignored:
        return QVariant(ignored_.indexOf(MapStringString {{"id", call["id"]},
                                                          {"uri", call["uri"]},
                                                          {"device", call["device"]}})
                        != -1);
    }
    return QVariant();
}

QHash<int, QByteArray>
ActiveCallsModel::roleNames() const
{
    using namespace ActiveCalls;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    ACTIVE_CALLS_ROLES
#undef X
    return roles;
}

void
ActiveCallsModel::reset()
{
    beginResetModel();
    endResetModel();
}

void
ActiveCallsModel::ignore(const QString& id, const QString& uri, const QString& deviceId)
{
    auto commit = MapStringString {{"id", id}, {"uri", uri}, {"device", deviceId}};
    ignored_.append(commit);
    auto index = lrcInstance_->indexOfActiveCall(id, uri, deviceId);
    if (index != -1)
        Q_EMIT dataChanged(createIndex(index, 0), createIndex(index, 0));
}