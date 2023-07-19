/**
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos   <aline.gondimsantos@savoirfairelinux.com>
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

#include "pluginlistmodel.h"

#include "lrcinstance.h"

#include "api/pluginmodel.h"

PluginListModel::PluginListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
    , lrcInstance_(instance)
{}

PluginListModel::~PluginListModel() {}

int
PluginListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        /// Count
        return installedPlugins_.size();
    }
    /// A valid QModelIndex returns 0 as no entry has sub-elements.
    return 0;
}

int
PluginListModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    /// Only need one column.
    return 1;
}

QVariant
PluginListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || installedPlugins_.size() <= index.row()) {
        return QVariant();
    }

    auto details = lrcInstance_->pluginModel().getPluginDetails(installedPlugins_.at(index.row()));

    switch (role) {
    case Role::PluginName:
        return QVariant(details.name);
    case Role::PluginId:
        return QVariant(installedPlugins_.at(index.row()));
    case Role::PluginIcon:
        return QVariant(details.iconPath);
    case Role::IsLoaded:
        return QVariant(details.loaded);
    }
    return QVariant();
}

QHash<int, QByteArray>
PluginListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[PluginName] = "PluginName";
    roles[PluginId] = "PluginId";
    roles[PluginIcon] = "PluginIcon";
    roles[IsLoaded] = "IsLoaded";

    return roles;
}

void
PluginListModel::reset()
{
    beginResetModel();
    installedPlugins_.clear();
    installedPlugins_ = lrcInstance_->pluginModel().getInstalledPlugins();
    filterPlugins(installedPlugins_);
    endResetModel();
}

void
PluginListModel::removePlugin(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    installedPlugins_.removeAt(index);
    endRemoveRows();
}

void
PluginListModel::pluginChanged(int index)
{
    Q_EMIT dataChanged(createIndex(index, 0), createIndex(index, 0));
}

void
PluginListModel::addPlugin()
{
    auto newList = lrcInstance_->pluginModel().getInstalledPlugins();
    filterPlugins(newList);
    if (newList.size() <= installedPlugins_.size())
        return;

    int index = 0;
    for (const auto& item : newList) {
        if (installedPlugins_.indexOf(item) == -1)
            break;
        index++;
    }

    beginInsertRows(QModelIndex(), index, index);
    installedPlugins_ = newList;
    endInsertRows();
}

void
PluginListModel::filterPlugins(VectorString& list) const
{
    if (!lrcInstance_ || !filterAccount_)
        return;

    const auto accountId = lrcInstance_->get_currentAccountId();
    list.erase(std::remove_if(list.begin(), // clazy:exclude=strict-iterators
                              list.end(),
                              [&](const QString& pluginName) -> bool {
                                  const auto prefs = lrcInstance_->pluginModel()
                                                         .getPluginPreferences(pluginName,
                                                                               accountId);
                                  return prefs.empty();
                              }),
               list.cend());
}

void
PluginListModel::onVersionStatusChanged(const QString& pluginId, PluginStatus::Role status)
{
    auto pluginIndex = -1;
    for (auto& p : installedPlugins_) {
        auto details = lrcInstance_->pluginModel().getPluginDetails(p);
        if (details.name == pluginId) {
            pluginIndex = installedPlugins_.indexOf(p, -1);
            break;
        }
    }
    switch (status) {
    case PluginStatus::INSTALLED:
        addPlugin();
        break;
    default:
        break;
    }

    if (pluginIndex == -1) {
        return;
    }

    switch (status) {
    case PluginStatus::INSTALLABLE:
        removePlugin(pluginIndex);
        break;
    case PluginStatus::FAILED:
        qWarning() << "Failed to install plugin" << pluginId;
        break;
    default:
        break;
    }
    return;
}
