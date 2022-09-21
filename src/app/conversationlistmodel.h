/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "conversationlistmodelbase.h"
#include "selectablelistproxymodel.h"

#include <QSortFilterProxyModel>

// A wrapper view model around ConversationModel's underlying data
class ConversationListModel : public ConversationListModelBase
{
    Q_OBJECT

public:
    explicit ConversationListModel(LRCInstance* instance, QObject* parent = nullptr);

public:
    virtual int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
};

// The top level filtered and sorted model to be consumed by QML ListViews
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
    // This flag can be toggled when switching tabs to show the current account's
    // conversation invites.
    bool filterRequests_ {false};
    QStringList ignored_ {};
};

// namespace ContactList2 {
// Q_NAMESPACE
// enum Type { CONVERSATION, CONFERENCE, TRANSFER, ADDCONVMEMBER, COUNT__ };
// Q_ENUM_NS(Type)
//} // namespace ContactList2

// class SmartListModel2 final : public ConversationListModel
//{
//    Q_OBJECT
//    QML_PROPERTY(ContactList2::Type, listModelType)

// public:
//    using Type = ContactList2::Type;

//    explicit SmartListModel2(LRCInstance* instance, QObject* parent = nullptr);

//    void updateData();

//    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
//    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

//    Q_INVOKABLE void setConferenceableFilter(const QString& filter = {});
//    Q_INVOKABLE void toggleSection(const QString& section);
//    // Q_INVOKABLE void fillConversationsList();
//    Q_INVOKABLE void selectItem(int index);

// private:
//    QMap<QString, bool> sectionState_;
//    QMap<ConferenceableItem, ConferenceableValue> conferenceables_;
//    // ConversationModel::ConversationQueueProxy conversations_;
//};
