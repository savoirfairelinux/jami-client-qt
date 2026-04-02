/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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

#include "abstractlistmodelbase.h"

#define TRACKEDMEMBERS_ROLES \
    X(Details) \
    X(PeerUri) \
    X(Devices) \
    X(Count)

namespace TrackedMembers {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    TRACKEDMEMBERS_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace TrackedMembers

class TrackedMembersModel final : public AbstractListModelBase
{
    Q_OBJECT
    Q_PROPERTY(QString conversationId READ conversationId WRITE setConversationId NOTIFY conversationIdChanged)

public:
    explicit TrackedMembersModel(LRCInstance* instance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void update();

    QString conversationId() const;
    void setConversationId(const QString& conversationId);

Q_SIGNALS:
    void conversationIdChanged();

private:
    void aggregateData();
    void resetData();

    QString conversationId_;
    LRCInstance* lrcInstance_;

    QVector<QString> peerUris_;
    QMap<QString, QMap<QString, QVariant>> peerData_;
    QVector<QMap<QString, QString>> trackedMembersList_;
};
