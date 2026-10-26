/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include "api/messagelistmodel.h"

#include <QSortFilterProxyModel>

// Threaded projection over the displayable message list.
// With no thread selected it shows thread roots; with one selected it shows that root and its replies.
// A loaded, displayable reply whose parent is not loaded is its own (fallback) thread root.
class ThreadedMsgListModel final : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString threadId READ threadId WRITE setThreadId NOTIFY threadIdChanged)
public:
    enum Role { ThreadRootId = lrc::api::MessageList::FilterStatus + 1, ThreadReplyCount };
    Q_ENUM(Role)

    explicit ThreadedMsgListModel(QObject* parent = nullptr);

    void setSourceModel(QAbstractItemModel* sourceModel) override;
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString threadId() const;
    void setThreadId(const QString& threadId);

    Q_INVOKABLE QString threadRootOf(const QString& id) const;
    Q_INVOKABLE int replyCountOf(const QString& rootId) const;
    Q_INVOKABLE int getDisplayIndex(const QString& id);
    Q_INVOKABLE QVariantMap get(int row) const;
    int count() const;

Q_SIGNALS:
    void countChanged();
    void threadIdChanged();

private:
    QString idAt(int sourceRow) const;
    void indexRows(int first, int last);
    void rebuildIndex();
    void addToIndex(const QString& id, const QString& replyTo);
    QString find(const QString& id) const;
    void merge(const QString& childId, const QString& parentId);

    QString threadId_;

    // Union-find over loaded displayable messages; each set is one thread.
    mutable QHash<QString, QString> set_;   // id -> parent in the union-find forest
    QHash<QString, QString> rootOf_;        // representative -> thread root id
    QHash<QString, int> size_;              // representative -> loaded message count
    QHash<QString, QStringList> repliesTo_; // declared reply-to -> loaded replies, even if it is not loaded

    bool regrouped_ {false};
    bool countsChanged_ {false};
    bool refilterQueued_ {false};
    QString previousThreadId_;
};
