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

#include "lrcinstance.h"

PluginStoreListModel::PluginStoreListModel(QObject* parent)
    : AbstractListModelBase(parent)
{}

PluginStoreListModel::~PluginStoreListModel() {}

int
PluginStoreListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        /// Count
        // TODO: should add the number of plugins / 3
        return 1;
    }
    /// A valid QModelIndex returns 0 as no entry has sub-elements.
    return 0;
}

int
PluginStoreListModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    /// Only need one column.
    return 3;
}

QVariant
PluginStoreListModel::data(const QModelIndex& index, int role) const
{
    auto numberOfPlugins = 0;
    if (!index.isValid() || numberOfPlugins <= index.row() * 3) {
        return QVariant();
    }
    // TODO: call the plugin store API
    // auto details = lrcInstance_->pluginModel().getPluginDetails(installedPlugins_.at(index.row()));

    switch (role) {
    case Role::pluginId:
        return QVariant();
    case Role::pluginTitle:
        return QVariant();
    case Role::pluginIcon:
        return QVariant();
    case Role::pluginBackground:
        return QVariant();
    case Role::pluginDescription:
        return QVariant();
    case Role::pluginAuthor:
        return QVariant();
    }
    return QVariant();
}

QHash<int, QByteArray>
PluginStoreListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[pluginId] = "id";
    roles[pluginTitle] = "title";
    roles[pluginIcon] = "icon";
    roles[pluginDescription] = "description";
    roles[pluginAuthor] = "author";

    return roles;
}

// TODO: reset the model(check out pluginlistmodel)
void
PluginStoreListModel::reset()
{}
