/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#pragma once

#include "conversationlistmodelbase.h"
#include "selectablelistproxymodel.h"

#include <QSortFilterProxyModel>

// A wrapper view model around ConversationModel's underlying data
class ConversationListModel final : public ConversationListModelBase
{
    Q_OBJECT

public:
    ConversationListModel(QObject* parent = nullptr)
        : ConversationListModelBase(parent) {};
    explicit ConversationListModel(LRCInstance* instance, QObject* parent = nullptr);
    ~ConversationListModel() = default;

protected:
    Q_SLOT void onModelUpdated() override;

public:
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
};

// The top level filtered and sorted model to be consumed by QML ListViews
class ConversationListProxyModel final : public SelectableListProxyModel
{
    Q_OBJECT

public:
    explicit ConversationListProxyModel(QAbstractListModel* model = nullptr,
                                        QObject* parent = nullptr);
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
