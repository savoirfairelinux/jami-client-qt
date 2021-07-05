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
    auto participant = participants_.at(index.row());

    switch (role) {
    case Role::Uri:
        return QVariant::fromValue(participant.item.value("uri"));
    case Role::BestName:
        return QVariant::fromValue(participant.item.value("bestName"));
    case Role::Active:
        return QVariant::fromValue(participant.item.value("active"));
    case Role::AudioLocalMuted:
        return QVariant::fromValue(participant.item.value("audioLocalMuted"));
    case Role::AudioModeratorMuted:
        return QVariant::fromValue(participant.item.value("audioModeratorMuted"));
    case Role::VideoMuted:
        return QVariant::fromValue(participant.item.value("videoMuted"));
    case Role::IsModerator:
        return QVariant::fromValue(participant.item.value("isModerator"));
    case Role::IsLocal:
        return QVariant::fromValue(participant.item.value("isLocal"));
    case Role::IsContact:
        return QVariant::fromValue(participant.item.value("isContact"));
    case Role::Avatar:
        return QVariant::fromValue(participant.item.value("avatar"));
    case Role::SinkId:
        return QVariant::fromValue(participant.item.value("sinkId"));
    case Role::HandRaised:
        return QVariant::fromValue(participant.item.value("handRaised"));
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
CallParticipantsModel::addParticipant(int index, const QVariant& infos)
{
    auto it = participants_.begin() + index;
    participants_.insert(it, CallParticipant::Item {infos.toJsonObject()});

    beginInsertRows(QModelIndex(), index, index);
    endInsertRows();

    callId_ = participants_[index].item["callId"].toString();
    lrcInstance_->renderer()->addDistantRenderer(participants_[index].item["sinkId"].toString());
    renderers_[participants_[index].item["callId"].toString()].append(
        participants_[index].item["sinkId"].toString());
}

void
CallParticipantsModel::updateParticipant(int index, const QVariant& infos)
{
    if (participants_.size() <= index)
        return;
    auto it = participants_.begin() + index;
    (*it) = CallParticipant::Item {infos.toJsonObject()};

    callId_ = participants_[index].item["callId"].toString();
    Q_EMIT updateParticipant(it->item.toVariantMap());
}

void
CallParticipantsModel::removeParticipant(int index)
{
    callId_ = participants_[index].item["callId"].toString();

    auto it = participants_.begin() + index;
    participants_.erase(it);

    beginRemoveRows(QModelIndex(), index, index);
    endRemoveRows();
}

void
CallParticipantsModel::clearParticipantsRenderes(const QString& callId)
{
    for (auto& item : renderers_[callId]) {
        lrcInstance_->renderer()->removeDistantRenderer(item);
    }
    renderers_.remove(callId);
}

void
CallParticipantsModel::setParticipants(const QString& callId, const QVariantList& participants)
{
    if (callId_ == callId)
        return;

    callId_ = callId;

    participants_.clear();
    beginResetModel();
    endResetModel();

    if (participants.isEmpty())
        clearParticipantsRenderes(callId);
    else {
        int idx = 0;
        for (const auto& participant : participants) {
            addParticipant(idx, participant);
            idx++;
        }
    }
}

void
CallParticipantsModel::resetParticipants(const QString& callId, const QVariantList& participants)
{
    if (callId == callId_)
        setParticipants(callId, participants);
    else if (participants.isEmpty())
        clearParticipantsRenderes(callId);
}
