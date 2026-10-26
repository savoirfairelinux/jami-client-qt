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

#include "threadedmsglistmodel.h"

#include "messagesadapter.h"

ThreadedMsgListModel::ThreadedMsgListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    connect(this, &QAbstractItemModel::rowsInserted, this, &ThreadedMsgListModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &ThreadedMsgListModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &ThreadedMsgListModel::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &ThreadedMsgListModel::countChanged);
}

void
ThreadedMsgListModel::setSourceModel(QAbstractItemModel* model)
{
    if (sourceModel())
        disconnect(sourceModel(), nullptr, this, nullptr);

    // Connected before the base class connects, so the index is current when new rows are filtered.
    if (model) {
        connect(model, &QAbstractItemModel::rowsInserted, this, [this](const QModelIndex&, int first, int last) {
            indexRows(first, last);
        });
        connect(model, &QAbstractItemModel::rowsRemoved, this, &ThreadedMsgListModel::rebuildIndex);
        connect(model, &QAbstractItemModel::rowsMoved, this, &ThreadedMsgListModel::rebuildIndex);
        connect(model, &QAbstractItemModel::layoutChanged, this, &ThreadedMsgListModel::rebuildIndex);
        connect(model, &QAbstractItemModel::modelReset, this, &ThreadedMsgListModel::rebuildIndex);
    }

    QSortFilterProxyModel::setSourceModel(model);
    rebuildIndex();
    invalidateRowsFilter();
    regrouped_ = countsChanged_ = false;
    previousThreadId_ = threadId_;

    // Connected after the base class, so the proxy has applied the change before rows are refiltered.
    if (model) {
        auto refresh = [this] {
            // Regrouping refilters loaded rows; coalesce it so a history batch costs one pass, not one per message.
            if (regrouped_ && !refilterQueued_) {
                refilterQueued_ = true;
                QMetaObject::invokeMethod(
                    this,
                    [this] {
                        refilterQueued_ = false;
                        invalidateRowsFilter();
                    },
                    Qt::QueuedConnection);
            }
            if (countsChanged_ && rowCount())
                Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, 0), {ThreadReplyCount});
            regrouped_ = countsChanged_ = false;
            if (previousThreadId_ != threadId_) {
                previousThreadId_ = threadId_;
                Q_EMIT threadIdChanged();
            }
        };
        connect(model, &QAbstractItemModel::rowsInserted, this, refresh);
        connect(model, &QAbstractItemModel::rowsRemoved, this, refresh);
        connect(model, &QAbstractItemModel::rowsMoved, this, refresh);
        connect(model, &QAbstractItemModel::layoutChanged, this, refresh);
        connect(model, &QAbstractItemModel::modelReset, this, refresh);
    }
}

bool
ThreadedMsgListModel::filterAcceptsRow(int sourceRow, const QModelIndex&) const
{
    const auto id = idAt(sourceRow);
    const auto root = threadRootOf(id);
    return threadId_.isEmpty() ? root.isEmpty() || root == id : root == threadId_;
}

QVariant
ThreadedMsgListModel::data(const QModelIndex& index, int role) const
{
    if (role == ThreadRootId)
        return threadRootOf(QSortFilterProxyModel::data(index, MessageList::Id).toString());
    if (role == ThreadReplyCount)
        return replyCountOf(QSortFilterProxyModel::data(index, MessageList::Id).toString());
    return QSortFilterProxyModel::data(index, role);
}

QHash<int, QByteArray>
ThreadedMsgListModel::roleNames() const
{
    auto roles = QSortFilterProxyModel::roleNames();
    roles[ThreadRootId] = "ThreadRootId";
    roles[ThreadReplyCount] = "ThreadReplyCount";
    return roles;
}

QString
ThreadedMsgListModel::threadId() const
{
    return threadId_;
}

void
ThreadedMsgListModel::setThreadId(const QString& threadId)
{
    if (threadId_ == threadId)
        return;
    threadId_ = previousThreadId_ = threadId;
    invalidateRowsFilter();
    Q_EMIT threadIdChanged();
}

QString
ThreadedMsgListModel::threadRootOf(const QString& id) const
{
    return set_.contains(id) ? rootOf_.value(find(id)) : QString();
}

int
ThreadedMsgListModel::replyCountOf(const QString& rootId) const
{
    return threadRootOf(rootId) == rootId && !rootId.isEmpty() ? size_.value(find(rootId)) - 1 : 0;
}

int
ThreadedMsgListModel::getDisplayIndex(const QString& id)
{
    auto filtered = qobject_cast<FilteredMsgListModel*>(sourceModel());
    if (!filtered)
        return -1;
    return mapFromSource(filtered->index(filtered->getDisplayIndex(id), 0)).row();
}

QVariantMap
ThreadedMsgListModel::get(int row) const
{
    QVariantMap map;
    const auto modelIndex = index(row, 0);
    const auto roles = roleNames();
    for (auto it = roles.cbegin(); it != roles.cend(); ++it)
        map.insert(it.value(), data(modelIndex, it.key()));
    return map;
}

int
ThreadedMsgListModel::count() const
{
    return rowCount();
}

QString
ThreadedMsgListModel::idAt(int sourceRow) const
{
    return sourceModel()->index(sourceRow, 0).data(MessageList::Id).toString();
}

void
ThreadedMsgListModel::indexRows(int first, int last)
{
    for (int row = first; row <= last; ++row) {
        const auto source = sourceModel()->index(row, 0);
        addToIndex(source.data(MessageList::Id).toString(), source.data(MessageList::ReplyTo).toString());
    }
}

void
ThreadedMsgListModel::rebuildIndex()
{
    set_.clear();
    rootOf_.clear();
    size_.clear();
    repliesTo_.clear();
    if (sourceModel())
        indexRows(0, sourceModel()->rowCount() - 1);
    // Indexing never loses the open thread, but removing its root can.
    if (!threadId_.isEmpty() && !set_.contains(threadId_))
        threadId_.clear();
    regrouped_ = true;
    countsChanged_ = true;
}

void
ThreadedMsgListModel::addToIndex(const QString& id, const QString& replyTo)
{
    if (id.isEmpty() || set_.contains(id))
        return;
    set_[id] = id;
    rootOf_[id] = id;
    size_[id] = 1;
    // Loaded replies to this message stop being fallback roots.
    for (const auto& reply : repliesTo_.value(id)) {
        merge(reply, id);
        regrouped_ = true;
    }
    if (!replyTo.isEmpty()) {
        repliesTo_[replyTo].append(id);
        if (set_.contains(replyTo))
            merge(id, replyTo);
    }
}

QString
ThreadedMsgListModel::find(const QString& id) const
{
    auto rep = id;
    while (set_[rep] != rep)
        rep = set_[rep];
    // Path compression keeps later lookups near constant.
    for (auto next = id; next != rep;)
        next = std::exchange(set_[next], rep);
    return rep;
}

void
ThreadedMsgListModel::merge(const QString& childId, const QString& parentId)
{
    auto child = find(childId);
    auto parent = find(parentId);
    if (child == parent)
        return; // Reply cycle: keep the existing thread.
    const auto root = rootOf_.value(parent);
    if (threadId_ == rootOf_.value(child))
        threadId_ = root;
    // Union by size; the merged thread keeps the parent's root.
    if (size_[child] > size_[parent])
        std::swap(child, parent);
    set_[child] = parent;
    size_[parent] += size_.take(child);
    rootOf_.remove(child);
    rootOf_[parent] = root;
    countsChanged_ = true;
}
