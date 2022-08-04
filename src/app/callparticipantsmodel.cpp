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
    auto& item = participants_.at(index.row()).item;

    switch (role) {
    case Role::Uri:
        return QVariant(item.value(ParticipantsInfosStrings::URI).toString());
    case Role::BestName:
        return QVariant(item.value(ParticipantsInfosStrings::BESTNAME).toString());
    case Role::Device:
        return QVariant(item.value(ParticipantsInfosStrings::DEVICE).toString());
    case Role::Active:
        return QVariant(item.value(ParticipantsInfosStrings::ACTIVE).toBool());
    case Role::AudioLocalMuted:
        return QVariant(item.value(ParticipantsInfosStrings::AUDIOLOCALMUTED).toBool());
    case Role::AudioModeratorMuted:
        return QVariant(item.value(ParticipantsInfosStrings::AUDIOMODERATORMUTED).toBool());
    case Role::VideoMuted:
        return QVariant(item.value(ParticipantsInfosStrings::VIDEOMUTED).toBool());
    case Role::IsModerator:
        return QVariant(item.value(ParticipantsInfosStrings::ISMODERATOR).toBool());
    case Role::IsLocal:
        return QVariant(item.value(ParticipantsInfosStrings::ISLOCAL).toBool());
    case Role::IsContact:
        return QVariant(item.value(ParticipantsInfosStrings::ISCONTACT).toBool());
    case Role::Avatar:
        return QVariant(item.value(ParticipantsInfosStrings::AVATAR).toString());
    case Role::SinkId:
        return QVariant(item.value(ParticipantsInfosStrings::STREAMID).toString());
    case Role::Height:
        return QVariant(item.value(ParticipantsInfosStrings::HEIGHT).toInt());
    case Role::Width:
        return QVariant(item.value(ParticipantsInfosStrings::WIDTH).toInt());
    case Role::HandRaised:
        return QVariant(item.value(ParticipantsInfosStrings::HANDRAISED).toBool());
    case Role::VoiceActivity:
        return QVariant(item.value(ParticipantsInfosStrings::VOICEACTIVITY).toBool());
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
