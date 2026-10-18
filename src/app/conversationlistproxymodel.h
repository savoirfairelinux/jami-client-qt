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

#include <QCollator>
#include <QSortFilterProxyModel>

using namespace lrc::api;

// The top level filtered and sorted model to be consumed by QML ListViews
class ConversationListProxyModel final : public SelectableListProxyModel
{
    Q_OBJECT
    // One-to-one conversations (contacts) and group conversations can be left out
    // independently, e.g. to let the user pick only among their contacts.
    Q_PROPERTY(bool showContacts READ showContacts WRITE setShowContacts NOTIFY typeFilterChanged)
    Q_PROPERTY(bool showGroups READ showGroups WRITE setShowGroups NOTIFY typeFilterChanged)
    // Sort by title, A to Z, instead of by last interaction.
    Q_PROPERTY(bool sortByTitle READ sortByTitle WRITE setSortByTitle NOTIFY sortByTitleChanged)

public:
    explicit ConversationListProxyModel(QAbstractListModel* model, QObject* parent = nullptr);
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;

    bool showContacts() const
    {
        return showContacts_;
    }
    void setShowContacts(bool showContacts);
    bool showGroups() const
    {
        return showGroups_;
    }
    void setShowGroups(bool showGroups);
    bool sortByTitle() const
    {
        return sortByTitle_;
    }
    void setSortByTitle(bool sortByTitle);

    Q_INVOKABLE void setFilterRequests(bool filterRequests);
    Q_INVOKABLE void ignoreFiltering(const QStringList& highlighted)
    {
        ignored_ = highlighted;
    }

Q_SIGNALS:
    void typeFilterChanged();
    void sortByTitleChanged();

private:
    // This flag can be toggled when switching tabs to show the current account's
    // conversation invites.
    bool filterRequests_ {false};
    QStringList ignored_ {};
    bool showContacts_ {true};
    bool showGroups_ {true};
    bool sortByTitle_ {false};
    QCollator collator_;
};
