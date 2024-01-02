/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "selectablelistproxymodel.h"

SelectableListProxyModel::SelectableListProxyModel(QAbstractListModel* model, QObject* parent)
    : QSortFilterProxyModel(parent)
    , currentFilteredRow_(-1)
    , selectedSourceIndex_(QModelIndex())
{
    bindSourceModel(model);
}

void
SelectableListProxyModel::bindSourceModel(QAbstractListModel* model)
{
    setSourceModel(model);
    if (!model) {
        return;
    }

    auto connectModelSignal = [this, model](auto signal, auto slot) {
        connect(model, signal, this, slot, Qt::UniqueConnection);
    };

    connectModelSignal(&QAbstractListModel::dataChanged, &SelectableListProxyModel::onModelUpdated);
    connectModelSignal(&QAbstractListModel::rowsInserted, &SelectableListProxyModel::onModelUpdated);
    connectModelSignal(&QAbstractListModel::rowsRemoved, &SelectableListProxyModel::onModelTrimmed);
    connectModelSignal(&QAbstractListModel::modelReset, &SelectableListProxyModel::deselect);
}

void
SelectableListProxyModel::setFilter(const QString& filterString)
{
    setFilterFixedString(filterString);
    updateSelection();
}

void
SelectableListProxyModel::select(const QModelIndex& index)
{
    selectedSourceIndex_ = mapToSource(index);
    updateSelection();
}

void
SelectableListProxyModel::select(int row)
{
    select(index(row, 0));
}

void
SelectableListProxyModel::deselect()
{
    selectedSourceIndex_ = QModelIndex();
    currentFilteredRow_ = -1;
    Q_EMIT currentFilteredRowChanged();
}

QVariant
SelectableListProxyModel::dataForRow(int row, int role) const
{
    return data(index(row, 0), role);
}

void
SelectableListProxyModel::selectSourceRow(int row)
{
    // note: the convId <-> index binding loop present
    // is broken here
    if (row == -1 || selectedSourceIndex_.row() == row)
        return;
    selectedSourceIndex_ = sourceModel()->index(row, 0);
    updateSelection();
}

void
SelectableListProxyModel::updateSelection(bool rowsRemoved)
{
    // if there has been no valid selection made, there is
    // nothing to update
    if (!selectedSourceIndex_.isValid() && currentFilteredRow_ == -1)
        return;

    auto lastFilteredRow = currentFilteredRow_;
    auto filteredIndex = mapFromSource(selectedSourceIndex_);

    // if the source model is empty, invalidate the selection
    if (rowCount() == 0 && rowsRemoved) {
        set_currentFilteredRow(-1);
        Q_EMIT validSelectionChanged();
        return;
    }

    // if the source and filtered index is no longer valid
    // this would indicate that a mutation has occured,
    // In this case, we need to update the selection to one
    // row above the current one.
    if (!selectedSourceIndex_.isValid()) {
        auto row = qMax(currentFilteredRow_ - 1, 0);
        selectedSourceIndex_ = mapToSource(index(row, 0));
        filteredIndex = mapFromSource(selectedSourceIndex_);
        // filteredIndex is not necessarily valid here, so we emit
        // forcefully to ensure that the selection is updated
        currentFilteredRow_ = filteredIndex.row();
        Q_EMIT currentFilteredRowChanged();
        Q_EMIT validSelectionChanged();
        return;
    }

    // update the row for ListView observers
    set_currentFilteredRow(filteredIndex.row());

    // finally, if the filter index is invalid, then we have
    // probably just filtered out the selected item and don't
    // want to force reselection of other ui components, as the
    // source index is still valid, in that case, or if the
    // row hasn't changed, don't notify
    if (!filteredIndex.isValid() || lastFilteredRow == currentFilteredRow_) {
        return;
    }

    Q_EMIT validSelectionChanged();
}

void
SelectableListProxyModel::onModelUpdated()
{
    updateSelection();
}

void
SelectableListProxyModel::onModelTrimmed()
{
    updateSelection(true);
}

SelectableListProxyGroupModel::SelectableListProxyGroupModel(QList<SelectableListProxyModel*> models,
                                                             QObject* parent)
    : QObject(parent)
    , models_(models)
{
    Q_FOREACH (auto* m, models_) {
        connect(m, &SelectableListProxyModel::validSelectionChanged, this, [this, m] {
            // deselct all other lists in the group
            Q_FOREACH (auto* otherM, models_) {
                if (m != otherM) {
                    otherM->deselect();
                }
            }
        });
    }
}
