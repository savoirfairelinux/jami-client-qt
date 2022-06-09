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

#pragma once

#include "lrcinstance.h"
#include "qtutils.h"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QQuickItem>
#include <QJsonObject>

#define ACTIVE_CALLS_ROLES \
    X(Id) \
    X(Uri) \
    X(Device) \
    X(Ignored)

namespace ActiveCalls {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    ACTIVE_CALLS_ROLES
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
} // namespace ActiveCalls

class ActiveCallsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    ActiveCallsModel(QObject* parent, LRCInstance* lrcInstance);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void reset();
    Q_INVOKABLE void ignore(const QString& id, const QString& uri, const QString& device);

private:
    QVector<QMap<QString, QString>> ignored_;
    LRCInstance* lrcInstance_;
};
