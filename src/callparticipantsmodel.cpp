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

#include "callparticipantsmodel.h"

#include "lrcinstance.h"
#include "qtutils.h"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QQuickItem>

#include <api/callparticipantsmodel.h>

CallParticipantsModel::CallParticipantsModel(LRCInstance* instance, QObject* parent)
    : QAbstractListModel(parent)
    , lrcInstance_(instance)
{}

int
CallParticipantsModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    // Internal call, so no need to protect participants_ as locked higher
    return participants_.size();
}

QVariant
CallParticipantsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    using namespace CallParticipant;
    // Internal call, so no need to protect participants_ as locked higher
    auto participant = participants_.at(index.row());

    switch (role) {
    case Role::Uri:
        return QVariant::fromValue(participant.item.value(lrc::api::ParticipantsInfosStrings::URI));
    case Role::BestName:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::BESTNAME));
    case Role::Device:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::DEVICE));
    case Role::Active:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::ACTIVE));
    case Role::AudioLocalMuted:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::AUDIOLOCALMUTED));
    case Role::AudioModeratorMuted:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::AUDIOMODERATORMUTED));
    case Role::VideoMuted:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::VIDEOMUTED));
    case Role::IsModerator:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::ISMODERATOR));
    case Role::IsLocal:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::ISLOCAL));
    case Role::IsContact:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::ISCONTACT));
    case Role::Avatar:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::AVATAR));
    case Role::SinkId:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::STREAMID));
    case Role::Height:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::HEIGHT));
    case Role::Width:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::WIDTH));
    case Role::HandRaised:
        return QVariant::fromValue(
            participant.item.value(lrc::api::ParticipantsInfosStrings::HANDRAISED));
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
    std::lock_guard<std::mutex> lk(participantsMtx_);
    if (index > participants_.size())
        return;
    beginInsertRows(QModelIndex(), index, index);

    auto it = participants_.begin() + index;
    participants_.insert(it, CallParticipant::Item {infos.toJsonObject()});

    endInsertRows();

    callId_ = participants_[index].item[lrc::api::ParticipantsInfosStrings::CALLID].toString();
}

void
CallParticipantsModel::updateParticipant(int index, const QVariant& infos)
{
    {
        std::lock_guard<std::mutex> lk(participantsMtx_);
        if (participants_.size() <= index)
            return;
        auto it = participants_.begin() + index;
        (*it) = CallParticipant::Item {infos.toJsonObject()};

        callId_ = participants_[index].item[lrc::api::ParticipantsInfosStrings::CALLID].toString();
    }
    Q_EMIT dataChanged(createIndex(index, 0), createIndex(index, 0));
}

void
CallParticipantsModel::removeParticipant(int index)
{
    std::lock_guard<std::mutex> lk(participantsMtx_);
    if (participants_.size() <= index)
        return;
    callId_ = participants_[index].item[lrc::api::ParticipantsInfosStrings::CALLID].toString();

    beginRemoveRows(QModelIndex(), index, index);

    auto it = participants_.begin() + index;
    participants_.erase(it);

    endRemoveRows();
}

void
CallParticipantsModel::setParticipants(const QString& callId, const QVariantList& participants)
{
    callId_ = callId;

    std::lock_guard<std::mutex> lk(participantsMtx_);
    participants_.clear();
    reset();

    if (!participants.isEmpty()) {
        int idx = 0;
        for (const auto& participant : participants) {
            beginInsertRows(QModelIndex(), idx, idx);
            auto it = participants_.begin() + idx;
            participants_.insert(it, CallParticipant::Item {participant.toJsonObject()});
            endInsertRows();
            idx++;
        }
    }
}

void
CallParticipantsModel::reset()
{
    beginResetModel();
    endResetModel();
}
