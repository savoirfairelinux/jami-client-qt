/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

#pragma once

#include "lrcinstance.h"
#include "qtutils.h"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QQuickItem>
#include <QJsonObject>

#define CALL_PARTICIPANTS_ROLES \
    X(Uri) \
    X(Device) \
    X(SinkId) \
    X(BestName) \
    X(Avatar) \
    X(Active) \
    X(XPosition) \
    X(YPosition) \
    X(Width) \
    X(Height) \
    X(HideSpectators) \
    X(AudioLocalMuted) \
    X(AudioModeratorMuted) \
    X(VideoMuted) \
    X(IsModerator) \
    X(IsLocal) \
    X(IsContact) \
    X(VoiceActivity) \
    X(IsRecording) \
    X(HandRaised) \
    X(IsSharing)

namespace CallParticipant {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    CALL_PARTICIPANTS_ROLES
#undef X
};
Q_ENUM_NS(Role)

struct Item
{
    QJsonObject item;

    bool operator==(const Item& a) const
    {
        return (item == a.item);
    }
};
} // namespace CallParticipant

class CallParticipantsModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(LayoutType conferenceLayout READ conferenceLayout NOTIFY conferenceLayoutChanged)
    QML_RO_PROPERTY(int, count)

public:
    CallParticipantsModel(LRCInstance* instance, QObject* parent = nullptr);

    typedef enum { GRID = 0, ONE_WITH_SMALL, ONE } LayoutType;
    Q_ENUM(LayoutType);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateParticipant(int index, const QVariant& infos);
    void addParticipant(int index, const QVariant& infos);
    void removeParticipant(int index);
    void setParticipants(const QString& callId, const QVariantList& participants);
    Q_INVOKABLE void reset();

    void setConferenceLayout(int layout, const QString& callId)
    {
        auto newLayout = static_cast<LayoutType>(layout);
        if (callId == callId_ && newLayout != conferenceLayout_) {
            conferenceLayout_ = newLayout;
            Q_EMIT conferenceLayoutChanged();
        }
    }
    LayoutType conferenceLayout()
    {
        return conferenceLayout_;
    }

Q_SIGNALS:
    void conferenceLayoutChanged();

private:
    LRCInstance* lrcInstance_ {nullptr};

    std::mutex participantsMtx_;
    QList<CallParticipant::Item> participants_ {};
    QString callId_;
    LayoutType conferenceLayout_;
};
