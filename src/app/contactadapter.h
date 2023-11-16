/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

#include "qmladapterbase.h"
#include "smartlistmodel.h"
#include "conversationlistmodel.h"
#include "connectioninfolistmodel.h"

#include <QObject>
#include <QSortFilterProxyModel>
#include <QString>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class LRCInstance;

/*
 * The SelectableProxyModel class
 * provides support for sorting and filtering data passed between another model and a view.
 *
 * User can customize a function pointer to pass to FilterPredicate to ensure which row in
 * the source model can be accepted.
 *
 * Additionally, user need to setFilterRegExp to be able to get input QRegExp from FilterPredicate.
 */
class SelectableProxyModel final : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    using FilterPredicate = std::function<bool(const QModelIndex&, const QRegularExpression&)>;

    explicit SelectableProxyModel(QObject* parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        setSortRole(ConversationList::Role::LastInteractionTimeStamp);
        sort(0, Qt::DescendingOrder);
        setFilterCaseSensitivity(Qt::CaseSensitivity::CaseInsensitive);
    }

    void setPredicate(FilterPredicate filterPredicate)
    {
        filterPredicate_ = filterPredicate;
    }

    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override
    {
        // Accept all contacts in conversation list filtered with account type, except those in a call.
        auto index = sourceModel()->index(sourceRow, 0, sourceParent);
        return filterPredicate_ ? filterPredicate_(index, filterRegularExpression()) : false;
    }

    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override
    {
        QVariant leftData = sourceModel()->data(left, sortRole());
        QVariant rightData = sourceModel()->data(right, sortRole());
        // we're assuming the sort role data type here is some integral time
        return leftData.toUInt() < rightData.toUInt();
    };

private:
    FilterPredicate filterPredicate_;
};

class ContactAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_SINGLETON

public:
    static ContactAdapter* create(QQmlEngine*, QJSEngine*)
    {
        return new ContactAdapter(qApp->property("LRCInstance").value<LRCInstance*>());
    }

    explicit ContactAdapter(LRCInstance* instance, QObject* parent = nullptr);
    ~ContactAdapter() = default;

    using Role = ConversationList::Role;

    Q_INVOKABLE QVariant getContactSelectableModel(int type);
    Q_INVOKABLE void setSearchFilter(const QString& filter);
    Q_INVOKABLE void contactSelected(int index);
    Q_INVOKABLE void removeContact(const QString& peerUri, bool banContact);
    Q_INVOKABLE void updateConnectionInfo();

    void connectSignals();

Q_SIGNALS:
    void bannedStatusChanged(const QString& uri, bool banned);
    void defaultModeratorsUpdated();

private Q_SLOTS:
    void onModelUpdated(const QString& uri);

private:
    SmartListModel::Type listModeltype_;
    QScopedPointer<SmartListModel> smartListModel_;
    QScopedPointer<SelectableProxyModel> selectableProxyModel_;
    QScopedPointer<ConnectionInfoListModel> connectionInfoListModel_;

    QStringList defaultModerators_;

    bool hasDifferentMembers(const VectorString& currentMembers,
                             const VectorString& convMembers) const;
};
