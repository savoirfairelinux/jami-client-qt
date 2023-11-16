/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
#include "appsettingsmanager.h"
#include "qtutils.h"

#include <QAbstractListModel>
#include <QObject>

#define MEMBERS_ROLES \
    X(MemberUri) \
    X(MemberRole)

namespace Members {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    MEMBERS_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace Members

class CurrentConversationMembers : public QAbstractListModel
{
    Q_OBJECT
    QML_RO_PROPERTY(int, count)

public:
    explicit CurrentConversationMembers(LRCInstance* lrcInstance, QObject* parent = nullptr);
    void setMembers(const QString& accountId, const QString& convId, const QStringList& members);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

private:
    LRCInstance* lrcInstance_;
    QString accountId_;
    QString convId_;
    QStringList members_;
};
