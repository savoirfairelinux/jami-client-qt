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
    case Role::Status:
        return QVariant(plugin.value("status", PluginStatus::INSTALLABLE).toString());
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
        return QColor(red / nPixels, green / nPixels, blue / nPixels, 70);
    } else {
        // Return an invalid color.
        return QColor();
    }
}

void
PluginStoreListModel::onVersionStatusChanged(const QString& pluginId, PluginStatus::Role status)
{
    auto plugin = QVariantMap();
    for (auto& p : plugins_) {
        if (p["id"].toString() == pluginId) {
            plugin = p;
            break;
        }
    }
    switch (status) {
    case PluginStatus::INSTALLABLE:
        if (!plugin.isEmpty())
            break;
        pluginAdded(pluginId);
        break;

    default:
        break;
    }
    if (plugin.isEmpty()) {
        return;
    }
    plugin["status"] = status;

    switch (status) {
    case PluginStatus::INSTALLED:
        removePlugin(pluginId);
        break;
    case PluginStatus::FAILED:
        qWarning() << "Failed to install plugin" << pluginId;
        break;
    default:
        break;
    }
}
