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

#pragma once

#include "lrcinstance.h"
#include "qtutils.h"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QDebug>

#define CC_ROLES \
    X(QObject*, ItemAction) \
    X(int, BadgeCount) \
    X(bool, HasBackground) \
    X(QObject*, MenuAction) \
    X(QString, Name)

namespace CallControl {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(t, role) role,
    CC_ROLES
#undef X
};
Q_ENUM_NS(Role)

struct Item
{
#define X(t, role) t role;
    CC_ROLES
#undef X
};
} // namespace CallControl

class CallControlListModel : public QAbstractListModel
{
    Q_OBJECT
public:
    CallControlListModel(QObject* parent = nullptr)
        : QAbstractListModel(parent)
    {}

    int rowCount(const QModelIndex& parent = QModelIndex()) const override
    {
        if (parent.isValid())
            return 0;
        return data_.size();
    }

    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override
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

    void setBadgeCount(int row, int count)
    {
        if (row >= rowCount())
            return;
        data_[row].BadgeCount = count;
        auto idx = index(row, 0);
        Q_EMIT dataChanged(idx, idx);
    }

    QHash<int, QByteArray> roleNames() const override
    {
        using namespace CallControl;
        QHash<int, QByteArray> roles;
#define X(t, role) roles[role] = #role;
        CC_ROLES
#undef X
        return roles;
    }

    void addItem(const CallControl::Item& item)
    {
        beginResetModel();
        data_.append(item);
        endResetModel();
    }

private:
    QList<CallControl::Item> data_;
};

class IndexRangeFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit IndexRangeFilterProxyModel(QAbstractListModel* parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        setSourceModel(parent);
        sourceModel()->data(QModelIndex());
    }

    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override
    {
        auto index = sourceModel()->index(sourceRow, 0, sourceParent);
        bool predicate = true;
        if (filterRole() != Qt::DisplayRole) {
            predicate = sourceModel()->data(index, filterRole()).toInt() != 0;
        }
        return sourceRow <= max_ && sourceRow >= min_ && predicate;
    }

    void setRange(int min, int max)
    {
        min_ = min;
        max_ = max;
        invalidateFilter();
    }

private:
    int min_ {-1};
    int max_ {-1};
};

class CallOverlayModel : public QObject
{
    Q_OBJECT
    QML_PROPERTY(int, overflowIndex)

public:
    CallOverlayModel(LRCInstance* instance, QObject* parent = nullptr)
        : QObject(parent)
        , lrcInstance_(instance)
        , primaryModel_(new CallControlListModel(this))
        , secondaryModel_(new CallControlListModel(this))
        , overflowModel_(new IndexRangeFilterProxyModel(secondaryModel_))
        , overflowVisibleModel_(new IndexRangeFilterProxyModel(secondaryModel_))
        , overflowHiddenModel_(new IndexRangeFilterProxyModel(secondaryModel_))
    {
        connect(this,
                &CallOverlayModel::overflowIndexChanged,
                this,
                &CallOverlayModel::setControlRanges);
        overflowVisibleModel_->setFilterRole(CallControl::Role::BadgeCount);
    }

    Q_INVOKABLE void addPrimaryControl(const QVariantMap& props)
    {
        CallControl::Item item {
#define X(t, role) props[#role].value<t>(),
            CC_ROLES
#undef X
        };
        primaryModel_->addItem(item);
    }

    Q_INVOKABLE void addSecondaryControl(const QVariantMap& props)
    {
        CallControl::Item item {
#define X(t, role) props[#role].value<t>(),
            CC_ROLES
#undef X
        };
        secondaryModel_->addItem(item);
        setControlRanges();
    }

    Q_INVOKABLE void setBadgeCount(int row, int count)
    {
        secondaryModel_->setBadgeCount(row, count);
    }

    Q_INVOKABLE QVariant primaryModel()
    {
        return QVariant::fromValue(primaryModel_);
    }
    Q_INVOKABLE QVariant secondaryModel()
    {
        return QVariant::fromValue(secondaryModel_);
    }
    Q_INVOKABLE QVariant overflowModel()
    {
        return QVariant::fromValue(overflowModel_);
    }
    Q_INVOKABLE QVariant overflowVisibleModel()
    {
        return QVariant::fromValue(overflowVisibleModel_);
    }
    Q_INVOKABLE QVariant overflowHiddenModel()
    {
        return QVariant::fromValue(overflowHiddenModel_);
    }

private Q_SLOTS:
    void setControlRanges()
    {
        overflowModel_->setRange(0, overflowIndex_ - 1);
        overflowVisibleModel_->setRange(overflowIndex_, secondaryModel_->rowCount());
        overflowHiddenModel_->setRange(overflowIndex_, secondaryModel_->rowCount());
    }

private:
    LRCInstance* lrcInstance_ {nullptr};

    CallControlListModel* primaryModel_;
    CallControlListModel* secondaryModel_;
    IndexRangeFilterProxyModel* overflowModel_;
    IndexRangeFilterProxyModel* overflowVisibleModel_;
    IndexRangeFilterProxyModel* overflowHiddenModel_;
};
