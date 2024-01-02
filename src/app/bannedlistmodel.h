/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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

class BannedListModel : public AbstractListModelBase
{
    Q_OBJECT
    QML_RO_PROPERTY(int, count)
public:
    enum Role { ContactName = Qt::UserRole + 1, ContactID };
    Q_ENUM(Role)

    explicit BannedListModel(QObject* parent = nullptr);
    ~BannedListModel();

    // QAbstractListModel override.
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    QModelIndex index(int row,
                      int column = 0,
                      const QModelIndex& parent = QModelIndex()) const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    // This function is to reset the model when there's new account added.
    void reset();

private Q_SLOTS:
    void setupForAccount();
    void onBannedStatusChanged(const QString& uri, bool banned);

private:
    QList<QString> bannedlist_;
};
