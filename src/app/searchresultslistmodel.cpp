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

#include "searchresultslistmodel.h"

SearchResultsListModel::SearchResultsListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    model_ = lrcInstance_->getCurrentConversationModel();
}

int
SearchResultsListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && model_) {
        return model_->getAllSearchResults().size();
    }
    return 0;
}

QVariant
SearchResultsListModel::data(const QModelIndex& index, int role) const
{
    const auto& data = model_->getAllSearchResults();
    if (!index.isValid() || data.empty() || index.row() >= (int) data.size())
        return {};
    return model_->dataForItem(data.at(index.row()), role);
}

QHash<int, QByteArray>
SearchResultsListModel::roleNames() const
{
    return model_->roleNames();
}

void
SearchResultsListModel::setFilter(const QString& filterString)
{
    model_->setFilter(filterString);
}

void
SearchResultsListModel::onSearchResultsUpdated()
{
    beginResetModel();
    endResetModel();
}
