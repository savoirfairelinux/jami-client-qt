/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

#define TIPS_ROLES \
    X(TipId) \
    X(Title) \
    X(Description) \
    X(Type)

namespace Tips {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    TIPS_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace Tips

class TipsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    TipsModel(AppSettingsManager* sm, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

public Q_SLOTS:
    void reset();

private:
    VectorMapStringString tips_;
    AppSettingsManager* settingsManager_;
};