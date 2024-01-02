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

#pragma once

#include "abstractlistmodelbase.h"
#include "pluginversionmanager.h"

class LRCInstance;

class PluginListModel : public AbstractListModelBase
{
    Q_OBJECT
    QML_PROPERTY(bool, filterAccount)
public:
    enum Role {
        PluginName = Qt::UserRole + 1,
        PluginDescription,
        PluginId,
        PluginVersion,
        PluginAuthor,
        PluginImage,
        PluginIcon,
        NewPluginAvailable,
        IsLoaded,
        Status,
        Id
    };
    Q_ENUM(Role)

    explicit PluginListModel(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~PluginListModel();

    /*
     * QAbstractListModel override.
     */
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    /*
     * Override role name as access point in qml.
     */
    QHash<int, QByteArray> roleNames() const override;

    /*
     * This function is to reset the model when there's new account added.
     */
    Q_INVOKABLE void reset();
    Q_INVOKABLE void removePlugin(int index);
    Q_INVOKABLE void pluginChanged(int index);
    Q_INVOKABLE void addPlugin();
    Q_INVOKABLE void disableAllPlugins();
    Q_INVOKABLE void deleteLatestVersion(const QString& pluginId);

Q_SIGNALS:
    void versionCheckRequested(const QString& pluginId);
    void setVersionStatus(const QString& pluginId, PluginStatus::Role status);
    void autoUpdateChanged(bool state);
    void disabled(const QString& pluginId);
    void errorOccurred(const QString& pluginId);

public Q_SLOTS:
    void onVersionStatusChanged(const QString& pluginId, PluginStatus::Role status);
    void onNewVersionAvailable(const QString& pluginId, const QString& version);

private:
    LRCInstance* lrcInstance_ = nullptr;
    void filterPlugins(VectorString& list) const;
    VectorString installedPlugins_ {};
    QMap<QString, PluginStatus::Role> pluginStatus_ {};
    QMap<QString, QString> newVersionAvailable_ {};
};
