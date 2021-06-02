/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

#include "callparticipantsmodel.h"

#include "lrcinstance.h"
#include "qtutils.h"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QQuickItem>

CallParticipantsModel::CallParticipantsModel(LRCInstance* instance, QObject* parent)
    : QAbstractListModel(parent)
    , lrcInstance_(instance)
{}

int
CallParticipantsModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return participants_.size();
}

QVariant
CallParticipantsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    using namespace CallParticipant;
    auto participant = participants_.values().at(index.row());

    switch (role) {
    case Role::Uri:
        return QVariant::fromValue(participant.item.value("uri"));
    }
    return QVariant();
}

QHash<int, QByteArray>
CallParticipantsModel::roleNames() const
{
    using namespace CallParticipant;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    CALL_PARTICIPANTS_ROLES
#undef X
    return roles;
}

void
CallParticipantsModel::addParticipant(const CallParticipant::Item& item)
{
    auto peerId = item.item.value("uri").toString();
    beginResetModel();
    auto it = participants_.find(peerId);
    if (it == participants_.end() && item.item.value("w").toInt() != 0
        && item.item.value("h").toInt() != 0) {
        participants_.insert(peerId, item);
    } else {
        if (item.item.value("w").toInt() == 0 || item.item.value("h").toInt() == 0) {
            removeParticipant(item);
        } else {
            it->item = item.item;
        }
    }
    endResetModel();
}

void
CallParticipantsModel::removeParticipant(const CallParticipant::Item& item)
{
    beginResetModel();
    participants_.remove(item.item.value("uri").toString());
    endResetModel();
}

void
CallParticipantsModel::clearParticipants()
{
    participants_.clear();
}

void
CallParticipantsModel::setParticipants(const QVariantList& participants)
{
    for (const auto& part : participants) {
        addParticipant(CallParticipant::Item {part.toJsonObject()});
    }
}
