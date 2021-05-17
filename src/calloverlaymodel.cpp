/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

#include "calloverlaymodel.h"

CallControlListModel::CallControlListModel(QObject* parent)
    : QAbstractListModel(parent)
{}

int
CallControlListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return data_.size();
}

QVariant
CallControlListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    using namespace CallControl;
    auto item = data_.at(index.row());

    switch (role) {
    case Role::DummyRole:
        break;
#define X(t, _role) \
    case Role::_role: \
        return QVariant::fromValue(item._role);
        CC_ROLES
#undef X
    default:
        break;
    }
    return QVariant();
}

QHash<int, QByteArray>
CallControlListModel::roleNames() const
{
    using namespace CallControl;
    QHash<int, QByteArray> roles;
#define X(t, role) roles[role] = #role;
    CC_ROLES
#undef X
    return roles;
}

void
CallControlListModel::setBadgeCount(int row, int count)
{
    if (row >= rowCount())
        return;
    data_[row].BadgeCount = count;
    auto idx = index(row, 0);
    Q_EMIT dataChanged(idx, idx);
}

void
CallControlListModel::addItem(const CallControl::Item& item)
{
    beginResetModel();
    data_.append(item);
    endResetModel();
}

IndexRangeFilterProxyModel::IndexRangeFilterProxyModel(QAbstractListModel* parent)
    : QSortFilterProxyModel(parent)
{
    setSourceModel(parent);
    sourceModel()->data(QModelIndex());
}

bool
IndexRangeFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    auto index = sourceModel()->index(sourceRow, 0, sourceParent);
    bool predicate = true;
    if (filterRole() != Qt::DisplayRole) {
        predicate = sourceModel()->data(index, filterRole()).toInt() != 0;
    }
    return sourceRow <= max_ && sourceRow >= min_ && predicate;
}

void
IndexRangeFilterProxyModel::setRange(int min, int max)
{
    min_ = min;
    max_ = max;
    invalidateFilter();
}

PendingConferencesListModel::PendingConferencesListModel(LRCInstance* instance, QObject* parent)
    : QAbstractListModel(parent)
    , lrcInstance_(instance)
{
    connectSignals();
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, [this]() { connectSignals(); });
}

int
PendingConferencesListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return lrcInstance_->getCurrentCallModel()->getPendingConferences().size();
}

QVariant
PendingConferencesListModel::data(const QModelIndex& index, int role) const
{
    return QVariant();
}

QHash<int, QByteArray>
PendingConferencesListModel::roleNames() const
{
    using namespace PendingConferences;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    PC_ROLES
#undef X
    return roles;
}

void
PendingConferencesListModel::connectSignals()
{
    disconnect(beginInsertPendingConferencesRows_);
    disconnect(endInsertPendingConferencesRows_);
    disconnect(beginRemovePendingConferencesRows_);
    disconnect(endRemovePendingConferencesRows_);

    beginInsertPendingConferencesRows_ = connect(
        lrcInstance_->getCurrentCallModel(),
        &NewCallModel::beginInsertPendingConferencesRows,
        this,
        [this](int position, int rows) {
            qDebug() << position << "ssssssssssssssss";
            beginInsertRows(QModelIndex(), position, position + (rows - 1));
        },
        Qt::DirectConnection);

    endInsertPendingConferencesRows_ = connect(
        lrcInstance_->getCurrentCallModel(),
        &NewCallModel::endInsertPendingConferencesRows,
        this,
        [this]() { endInsertRows(); },
        Qt::DirectConnection);

    beginRemovePendingConferencesRows_ = connect(
        lrcInstance_->getCurrentCallModel(),
        &NewCallModel::beginRemovePendingConferencesRows,
        this,
        [this](int position, int rows) {
            qDebug() << position << "ssssssssssssssss";
            beginRemoveRows(QModelIndex(), position, position + (rows - 1));
        },
        Qt::DirectConnection);

    endRemovePendingConferencesRows_ = connect(
        lrcInstance_->getCurrentCallModel(),
        &NewCallModel::endRemovePendingConferencesRows,
        this,
        [this]() { endRemoveRows(); },

        Qt::DirectConnection);
}

CallOverlayModel::CallOverlayModel(LRCInstance* instance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(instance)
    , primaryModel_(new CallControlListModel(this))
    , secondaryModel_(new CallControlListModel(this))
    , overflowModel_(new IndexRangeFilterProxyModel(secondaryModel_))
    , overflowVisibleModel_(new IndexRangeFilterProxyModel(secondaryModel_))
    , overflowHiddenModel_(new IndexRangeFilterProxyModel(secondaryModel_))
    , pendingConferencesModel_(new PendingConferencesListModel(instance, this))
{
    connect(this,
            &CallOverlayModel::overflowIndexChanged,
            this,
            &CallOverlayModel::setControlRanges);
    overflowVisibleModel_->setFilterRole(CallControl::Role::BadgeCount);
}

void
CallOverlayModel::addPrimaryControl(const QVariantMap& props)
{
    CallControl::Item item {
#define X(t, role) props[#role].value<t>(),
        CC_ROLES
#undef X
    };
    primaryModel_->addItem(item);
}

void
CallOverlayModel::addSecondaryControl(const QVariantMap& props)
{
    CallControl::Item item {
#define X(t, role) props[#role].value<t>(),
        CC_ROLES
#undef X
    };
    secondaryModel_->addItem(item);
    setControlRanges();
}

void
CallOverlayModel::setBadgeCount(int row, int count)
{
    secondaryModel_->setBadgeCount(row, count);
}

QVariant
CallOverlayModel::primaryModel()
{
    return QVariant::fromValue(primaryModel_);
}

QVariant
CallOverlayModel::secondaryModel()
{
    return QVariant::fromValue(secondaryModel_);
}

QVariant
CallOverlayModel::overflowModel()
{
    return QVariant::fromValue(overflowModel_);
}

QVariant
CallOverlayModel::overflowVisibleModel()
{
    return QVariant::fromValue(overflowVisibleModel_);
}

QVariant
CallOverlayModel::overflowHiddenModel()
{
    return QVariant::fromValue(overflowHiddenModel_);
}

QVariant
CallOverlayModel::pendingConferencesModel()
{
    return QVariant::fromValue(pendingConferencesModel_);
}

void
CallOverlayModel::setControlRanges()
{
    overflowModel_->setRange(0, overflowIndex_ - 1);
    overflowVisibleModel_->setRange(overflowIndex_, secondaryModel_->rowCount());
    overflowHiddenModel_->setRange(overflowIndex_, secondaryModel_->rowCount());
}
