/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

#include "selectablelistproxymodel.h"
#include <api/conversationmodel.h>

class ConversationListProxyModel final : public SelectableListProxyModel
{
    Q_OBJECT

public:
    explicit ConversationListProxyModel(QAbstractListModel* model, QObject* parent = nullptr);
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;

    Q_INVOKABLE void setFilterRequests(bool filterRequests);
    Q_INVOKABLE void ignoreFiltering(const QStringList& highlighted)
    {
        ignored_ = highlighted;
    }

private:
    bool filterRequests_ {false};
    QStringList ignored_ {};
};
