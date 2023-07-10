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

#pragma once

#include <QAction>
#include <QAbstractItemModel>
#include <QQmlContext>

class TreeNode
{
public:
    TreeNode(QObject* action = nullptr, TreeNode* parent = nullptr);
    ~TreeNode();

    void appendChild(TreeNode* child);
    void removeChild(TreeNode* child);
    TreeNode* child(int row) const;
    TreeNode* findNode(QObject* node);
    int childCount() const;
    QVariant data(int column) const;
    int row() const;
    TreeNode* parent() const;

private:
    QObject* action_;
    QList<TreeNode*> children_;
    TreeNode* parent_;
};

class TreeModel : public QAbstractItemModel
{
    Q_OBJECT
public:
    TreeModel(QObject* parent = nullptr);
    ~TreeModel();

    QModelIndex index(int row, int column, const QModelIndex& parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex& index) const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    Q_INVOKABLE void addTopLevelItem(QObject* action);
    Q_INVOKABLE void addItem(QObject* action, QObject* parentAction = nullptr);

private:
    TreeNode* nodeFromIndex(const QModelIndex& index) const;

    TreeNode* root_;
};
