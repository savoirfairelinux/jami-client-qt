/**
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
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

PluginListModel::PluginListModel(LRCInstance* lrcInstance, QObject* parent)
    : AbstractListModelBase(parent)
    , lrcInstance_(lrcInstance)
{
    reset();
}

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
    installedPlugins_.at(index.row());
    switch (role) {
    case Role::PluginName:
        return QVariant(details.name);
    case Role::PluginVersion:
        return QVariant(details.version);
    case Role::PluginDescription:
        return QVariant(details.description);
    case Role::PluginId:
        return QVariant(installedPlugins_.at(index.row()));
    case Role::PluginIcon:
        return QVariant(details.iconPath);
    case Role::PluginImage:
        return QVariant(details.backgroundPath);
    case Role::IsLoaded:
        return QVariant(details.loaded);
    case Role::PluginAuthor:
        return QVariant(details.author);
    case Role::Status:
        return QVariant(pluginStatus_.value(installedPlugins_.at(index.row())));
    case Role::NewPluginAvailable:
        return QVariant(newVersionAvailable_.value(installedPlugins_.at(index.row())));
    case Role::Id:
        return QVariant(details.id);
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
    roles[PluginImage] = "PluginImage";
    roles[PluginVersion] = "PluginVersion";
    roles[PluginAuthor] = "PluginAuthor";
    roles[IsLoaded] = "IsLoaded";
    roles[Status] = "Status";
    roles[PluginDescription] = "PluginDescription";
    roles[NewPluginAvailable] = "NewPluginAvailable";
    roles[Id] = "Id";
    return roles;
}

void
PluginListModel::reset()
{
    beginResetModel();
    installedPlugins_.clear();
    installedPlugins_ = lrcInstance_->pluginModel().getInstalledPlugins();
    for (auto plugin : installedPlugins_) {
        pluginStatus_[plugin] = PluginStatus::INSTALLED;
    }
    filterPlugins(installedPlugins_);
    endResetModel();
}

void
PluginListModel::removePlugin(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    installedPlugins_.removeAt(index);
    endRemoveRows();
    reset();
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

    reset();
}

void
PluginListModel::disableAllPlugins()
{
    for (auto& plugin : installedPlugins_) {
        auto& pluginModel = lrcInstance_->pluginModel();
        const auto& details = pluginModel.getPluginDetails(plugin);
        pluginModel.unloadPlugin(details.path);
        disabled(details.path);
    }
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
PluginListModel::onNewVersionAvailable(const QString& pluginId, const QString& version)
{
    // check if pluginId exists in installedPlugins_
    auto pluginIndex = -1;
    for (auto& p : installedPlugins_) {
        auto details = lrcInstance_->pluginModel().getPluginDetails(p);
        if (details.name == pluginId) {
            pluginIndex = installedPlugins_.indexOf(p, -1);
            break;
        }
    }
    if (pluginIndex == -1) {
        return;
    }
    newVersionAvailable_[pluginId] = version;
    pluginChanged(pluginIndex);
}

void
PluginListModel::deleteLatestVersion(const QString& pluginId)
{
    auto pluginIndex = -1;
    for (auto& p : installedPlugins_) {
        auto details = lrcInstance_->pluginModel().getPluginDetails(p);
        if (details.name == pluginId) {
            pluginIndex = installedPlugins_.indexOf(p, -1);
            break;
        }
    }
    if (pluginIndex == -1) {
        return;
    }
    newVersionAvailable_.remove(pluginId);
}
void
PluginListModel::onVersionStatusChanged(const QString& pluginId, PluginStatus::Role status)
{
    auto pluginIndex = -1;
    QString pluginModelId = "";
    for (const auto& p : installedPlugins_) {
        auto details = lrcInstance_->pluginModel().getPluginDetails(p);
        if (details.id == pluginId) {
            pluginIndex = installedPlugins_.indexOf(p, -1);
            pluginModelId = p;
            break;
        }
    }
    switch (status) {
    case PluginStatus::INSTALLED:
        addPlugin();
        break;
    case PluginStatus::FAILED:
        errorOccurred(pluginId);
        status = PluginStatus::UPDATABLE;
        break;
    default:
        break;
    }

    if (pluginIndex == -1) {
        return;
    }
    pluginStatus_[pluginModelId] = status;
    pluginChanged(pluginIndex);
    switch (status) {
    case PluginStatus::INSTALLABLE:
        removePlugin(pluginIndex);
        break;
    default:
        break;
    }
    return;
}
