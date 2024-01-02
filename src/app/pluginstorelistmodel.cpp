/**
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

#include "api/pluginmodel.h"

#include <QUrl>

#include <algorithm>

PluginStoreListModel::PluginStoreListModel(LRCInstance* lrcInstance, QObject* parent)
    : AbstractListModelBase(parent)
    , lrcInstance_(lrcInstance)
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
    case Role::Name:
        return QVariant(plugin["name"].toString());
    case Role::Id:
        return QVariant(plugin["id"].toString());
    case Role::IconPath:
        return QVariant(plugin["iconPath"].toString());
    case Role::Description:
        return QVariant(plugin["description"].toString());
    case Role::Author:
        return QVariant(plugin["author"].toString());
    case Role::Status:
        return QVariant(plugin.value("status", PluginStatus::INSTALLABLE));
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

void
PluginStoreListModel::reset()
{
    beginResetModel();
    endResetModel();
}

void
PluginStoreListModel::addPlugin(const QVariantMap& plugin)
{
    beginInsertRows(QModelIndex(), plugins_.size(), plugins_.size());
    plugins_.append(plugin);
    sort();
    endInsertRows();
}

void
PluginStoreListModel::setPlugins(const QList<QVariantMap>& plugins)
{
    beginResetModel();
    plugins_ = filterPlugins(plugins);
    sort();
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
            sort();
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

QColor
PluginStoreListModel::computeAverageColorOfImage(const QString& file)
{
    auto fileUrl = QUrl(file);
    // Return an invalid color if the file URL is invalid.
    if (!fileUrl.isValid()) {
        return QColor();
    }
    // Load the image.
    QImage image(fileUrl.toLocalFile());
    // If the image is valid...
    if (!image.isNull()) {
        static const QSize size(3, 3);
        static const int nPixels = size.width() * size.height();
        // Scale the image to 3x3 pixels.
        image = image.scaled(size, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
        // Return the average color of the image's pixels.
        double red = 0;
        double green = 0;
        double blue = 0;
        for (int i = 0; i < size.width(); i++) {
            for (int j = 0; j < size.height(); j++) {
                auto pixelColor = image.pixelColor(i, j);
                red += pixelColor.red();
                green += pixelColor.green();
                blue += pixelColor.blue();
            }
        }
        return QColor(red / nPixels, green / nPixels, blue / nPixels);
    } else {
        // Return an invalid color.
        return QColor();
    }
}

void
PluginStoreListModel::onVersionStatusChanged(const QString& pluginId, PluginStatus::Role status)
{
    auto it = std::find_if(plugins_.begin(), plugins_.end(), [&pluginId](const QVariantMap& p) {
        return p["id"].toString() == pluginId;
    });

    switch (status) {
    case PluginStatus::INSTALLABLE:
        if (it != plugins_.end()) {
            break;
        }
        pluginAdded(pluginId);
        break;
    default:
        break;
    }

    if (it == plugins_.end()) {
        return;
    }
    auto& plugin = *it;

    plugin["status"] = status;
    auto index = createIndex(rowFromPluginId(pluginId), 0);
    if (index.isValid()) {
        Q_EMIT dataChanged(index, index, {PluginStoreList::Role::Status});
    }
    switch (status) {
    case PluginStatus::INSTALLED:
        removePlugin(pluginId);
        break;
    default:
        break;
    }
}

int
PluginStoreListModel::rowFromPluginId(const QString& pluginId) const
{
    const auto it = std::find_if(plugins_.begin(),
                                 plugins_.end(),
                                 [&pluginId](const QVariantMap& p) {
                                     return p["id"].toString() == pluginId;
                                 });
    if (it != plugins_.end()) {
        return std::distance(plugins_.begin(), it);
    }
    return -1;
}

void
PluginStoreListModel::sort()
{
    std::sort(plugins_.begin(), plugins_.end(), [](const QVariantMap& a, const QVariantMap& b) {
        return a["timestamp"].toString() < b["timestamp"].toString();
    });
}

QList<QVariantMap>
PluginStoreListModel::filterPlugins(const QList<QVariantMap>& plugins)
{
    auto& pluginModel = lrcInstance_->pluginModel();
    auto installedPlugins = pluginModel.getInstalledPlugins();
    QList<QVariantMap> filterPluginsNotInstalled;
    for (auto& remotePlugin : plugins) {
        if (std::find_if(installedPlugins.begin(),
                         installedPlugins.end(),
                         [remotePlugin, &pluginModel, this](const QString& installedPlugin) {
                             const auto& details = pluginModel.getPluginDetails(installedPlugin);
                             return remotePlugin["id"].toString() == details.id;
                         })
            == installedPlugins.end()) {
            filterPluginsNotInstalled.append(remotePlugin);
        }
    }
    return filterPluginsNotInstalled;
}
