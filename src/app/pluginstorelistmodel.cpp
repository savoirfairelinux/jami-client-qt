/**
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Xavier Jouslin de Noray   <xavier.jouslindenoray@savoirfairelinux.com>
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
#include "pluginstorelistmodel.h"

PluginStoreListModel::PluginStoreListModel(QObject* parent)
    : AbstractListModelBase(parent)
{}

int
PluginStoreListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid()) {
        return plugins_.size();
    }
    /// A valid QModelIndex returns 0 as no entry has sub-elements.
    return 0;
}

QVariant
PluginStoreListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    auto plugin = plugins_.at(index.row());

    switch (role) {
    case Role::Id:
        return QVariant(plugin["id"].toString());
    case Role::Title:
        return QVariant(plugin["name"].toString());
    case Role::IconPath:
        return QVariant(plugin["iconPath"].toString());
    case Role::Background:
        return QVariant(plugin["background"].toString());
    case Role::Description:
        return QVariant(plugin["description"].toString());
    case Role::Author:
        return QVariant(plugin["author"].toString());
    }
    return QVariant();
}

QHash<int, QByteArray>
PluginStoreListModel::roleNames() const
{
    using namespace PluginStoreList;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    PLUGINSTORE_ROLES
#undef X
    return roles;
}

// TODO: reset the model(check out pluginlistmodel)
void
PluginStoreListModel::reset()
{
    beginResetModel();
    plugins_.clear();
    endResetModel();
}

void
PluginStoreListModel::addPlugin(const QVariantMap& plugin)
{
    beginInsertRows(QModelIndex(), plugins_.size(), plugins_.size());
    plugins_.append(plugin);
    endInsertRows();
}

void
PluginStoreListModel::setPlugins(const QList<QVariantMap>& plugins)
{
    beginResetModel();
    plugins_ = plugins;
    endResetModel();
}

void
PluginStoreListModel::removePlugin(const QString& pluginId)
{
    auto index = 0;
    for (auto& plugin : plugins_) {
        if (plugin["id"].toString() == pluginId) {
            beginRemoveRows(QModelIndex(), index, index);
            plugins_.removeAt(index);
            endRemoveRows();
            return;
        }
        index++;
    }
}

void
PluginStoreListModel::updatePlugin(const QVariantMap& plugin)
{
    auto index = 0;
    for (auto& p : plugins_) {
        if (p["id"].toString() == plugin["id"].toString()) {
            p = plugin;
            Q_EMIT dataChanged(createIndex(index, 0), createIndex(index, 0));
            return;
        }
        index++;
    }
}
