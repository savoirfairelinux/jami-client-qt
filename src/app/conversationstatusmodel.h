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

#define CONVERSATIONSTATUS_ROLES \
    X(ConnectionDatas) \
    X(PeerName) \
    X(PeerId) \
    X(DeviceId) \
    X(Status) \
    X(RemoteAddress) \
    X(IsMobile) \
    X(ConnectionTime) \
    X(Count)

namespace ConversationStatus {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    CONVERSATIONSTATUS_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace ConversationStatus

class ConversationStatusModel final : public AbstractListModelBase
{
    Q_OBJECT
    Q_PROPERTY(QString conversationId READ conversationId WRITE setConversationId NOTIFY conversationIdChanged)

public:
    explicit ConversationStatusModel(LRCInstance* instance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void update();

    QString conversationId() const;
    void setConversationId(const QString& conversationId);

Q_SIGNALS:
    void conversationIdChanged();

private:
    using Role = ConversationStatus::Role;

    VectorMapStringString connectionInfoList_;
    QVector<QString> peerIds_;
    QMap<QString, QMap<QString, QMap<QString, QVariant>>> peerData_;
    QString conversationId_;

    void aggregateData();
    void resetData();
};
