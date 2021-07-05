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
    X(AudioLocalMuted) \
    X(AudioModeratorMuted) \
    X(VideoMuted) \
    X(IsModerator) \
    X(IsLocal) \
    X(IsContact)

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
public:
    CallParticipantsModel(LRCInstance* instance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateParticipant(int index, const QVariant& infos);
    void addParticipant(int index, const QVariant& infos);
    void removeParticipant(int index);
    void clearParticipantsRenderes(const QString& callId);
    void setParticipants(const QString& callId, const QVariantList& participants);
    void resetParticipants(const QString& callId, const QVariantList& participants);

Q_SIGNALS:
    void updateParticipant(QVariant participantInfos);

private:
    LRCInstance* lrcInstance_ {nullptr};

    QList<CallParticipant::Item> participants_ {};
    QMap<QString, QStringList> renderers_ {};
    QString callId_;
};
