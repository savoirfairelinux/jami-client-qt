/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

#include "treemodel.h"

#include <QQmlListProperty>

TreeNode::TreeNode(QObject* action, TreeNode* parent)
    : action_(action)
    , parent_(parent)
{}

TreeNode::~TreeNode()
{
    qDeleteAll(children_);
}

void
TreeNode::appendChild(TreeNode* child)
{
    children_.append(child);
}

void
TreeNode::removeChild(TreeNode* child)
{
    children_.removeOne(child);
}

TreeNode*
TreeNode::child(int row) const
{
    if (row >= 0 && row < children_.count())
        return children_.at(row);
    return nullptr;
}

TreeNode*
// NOLINTNEXTLINE(misc-no-recursion)
TreeNode::findNode(QObject* node)
{
    if (action_ == node)
        return this;
    for (auto* child : children_) {
        return child->findNode(node);
    }
    return nullptr;
}

int
TreeNode::childCount() const
{
    return static_cast<int>(children_.count());
}

QVariant
TreeNode::data(int column) const
{
    if (column == 0 && action_) {
        qWarning() << Q_FUNC_INFO << action_;
        return QVariant::fromValue(action_);
    }
    return QVariant();
}

int
TreeNode::row() const
{
    if (parent_) {
        auto idx = parent_->children_.indexOf(const_cast<TreeNode*>(this));
        return static_cast<int>(idx);
    }
    return 0;
}

TreeNode*
TreeNode::parent() const
{
    return parent_;
}

TreeModel::TreeModel(QObject* parent)
    : QAbstractItemModel(parent)
{
    root_ = new TreeNode();
}

TreeModel::~TreeModel()
{
    delete root_;
}

QModelIndex
TreeModel::index(int row, int column, const QModelIndex& parent) const
{
    if (!hasIndex(row, column, parent))
        return QModelIndex();
    TreeNode* parentNode = nodeFromIndex(parent);
    TreeNode* childNode = parentNode->child(row);
    if (childNode)
        return createIndex(row, column, childNode);
    return QModelIndex();
}

QModelIndex
TreeModel::parent(const QModelIndex& index) const
{
    if (!index.isValid())
        return QModelIndex();
    TreeNode* childNode = nodeFromIndex(index);
    TreeNode* parentNode = childNode->parent();
    if (parentNode == root_)
        return QModelIndex();
    return createIndex(parentNode->row(), 0, parentNode);
}

int
TreeModel::rowCount(const QModelIndex& parent) const
{
    TreeNode* parentNode = nodeFromIndex(parent);
    return parentNode->childCount();
}

int
TreeModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return 1; // Only one column for Action
}

QVariant
TreeModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();
    if (role != Qt::DisplayRole)
        return QVariant();
    TreeNode* node = nodeFromIndex(index);
    qWarning() << Q_FUNC_INFO << node;
    return node->data(index.column());
}

Qt::ItemFlags
TreeModel::flags(const QModelIndex& index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable;
}

void
TreeModel::addTopLevelItem(QObject* action)
{
    addItem(action, nullptr);
}

Q_INVOKABLE void
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
TreeModel::addItem(QObject* action, QObject* parentAction)
{
    // Get the parent node
    TreeNode* parentNode = nullptr;
    if (!parentAction) {
        parentNode = root_;
    } else {
        parentNode = root_->findNode(parentAction);
        if (!parentNode)
            return;
    }

    // Create the new node
    TreeNode* node = new TreeNode(action, parentNode);

    Q_EMIT layoutAboutToBeChanged();

    // Get the row at which we will insert the new node
    const int row = parentNode->childCount();
    qWarning() << "Adding item" << node << "to" << parentNode << row;

    beginInsertRows(QModelIndex(), row, row);
    parentNode->appendChild(node);
    endInsertRows();

    Q_EMIT layoutChanged();

    // Okay so now it's possible that this node has children.
    // They will be in the form:
    //  QVariant(QQmlListProperty<Action_QMLTYPE_12>, )
    // Parse the "children" property and add them to the model as well.

    // Create a QQmlListReference object from the QQmlListProperty
    QQmlListReference listReference(action->property("children"));
    // Iterate over the list
    for (int i = 0; i < listReference.count(); ++i) {
        QObject* childObject = listReference.at(i);
        qWarning() << "Adding child" << childObject;
        addItem(childObject, action);
    }
}

TreeNode*
TreeModel::nodeFromIndex(const QModelIndex& index) const
{
    if (index.isValid()) {
        return static_cast<TreeNode*>(index.internalPointer());
    }
    return root_;
}
