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
    auto it = participants_.find(peerId);
    if (it == participants_.end()) {
        participants_.insert(participants_.begin() + idx_, peerId, item);
        beginInsertRows(QModelIndex(), idx_, idx_);
        endInsertRows();
        lrcInstance_->renderer()->addDistantRenderer(item.item["sinkId"].toString());
        renderers_.append(item.item["sinkId"].toString());
    } else {
        if (item.item["uri"] == it->item["uri"] && item.item["sinkId"] == it->item["sinkId"] &&
            item.item["active"] == it->item["active"] &&
            item.item["audioLocalMuted"] == it->item["audioLocalMuted"]
            && item.item["audioModeratorMuted"] == it->item["audioModeratorMuted"] &&
            item.item["avatar"] == it->item["avatar"] && item.item["bestName"] == it->item["bestName"]
                && item.item["isContact"] == it->item["isContact"] && item.item["isLocal"] == it->item["isLocal"]
                && item.item["videoMuted"] == it->item["videoMuted"])
            return;
        (*it) = item;
        Q_EMIT updateParticipant(item.item.toVariantMap());
    }
    idx_++;
}



void
CallParticipantsModel::filterParticipants(const QVariantList& participants)
{
    for (const auto& part : participants) {
        auto candidate = CallParticipant::Item {part.toJsonObject()};

        auto peerId = candidate.item.value("uri").toString();
        auto it = participantsCandidates_.find(peerId);
        if (candidate.item.value("w").toInt() != 0
            && candidate.item.value("h").toInt() != 0) {
            validUris_.append(peerId);
            if (it == participantsCandidates_.end()) {
                participantsCandidates_.insert(peerId, candidate);
            } else {
                (*it) = candidate;
            }
        }
    }
}

void
CallParticipantsModel::removeParticipant(int pos)
{
    auto it = participants_.begin() + pos;
    auto sinkId = it->item["sinkId"].toString();
    participants_.erase(it);
    beginRemoveRows(QModelIndex(), pos, pos);
    endRemoveRows();
}

void
CallParticipantsModel::clearParticipantsRenderes()
{
    for (auto& item : renderers_) {
        lrcInstance_->renderer()->removeDistantRenderer(item);
    }
    renderers_.clear();
}

void
CallParticipantsModel::setParticipants(const QVariantList& participants)
{
    validUris_.clear();
    filterParticipants(participants);
    validUris_.sort();

    idx_ = 0;
    for (const auto& partUri : validUris_)
        addParticipant(participantsCandidates_[partUri]);

    idx_ = 0;
    auto keys = participants_.keys();
    for (const auto& key : keys) {
        auto keyIdx = validUris_.indexOf(key);
        if (keyIdx < 0 || keyIdx >= validUris_.size())
            removeParticipant(idx_);
        else
            idx_++;
    }

    if (participants_.isEmpty()) {
        clearParticipantsRenderes();
        return;
    }
    Q_EMIT updateParticipantsLayout();
}
