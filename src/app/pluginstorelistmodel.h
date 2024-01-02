/**
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
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
#pragma once

#include "abstractlistmodelbase.h"
#include "pluginversionmanager.h"

class QColor;
class QString;

#define PLUGINSTORE_ROLES \
    X(Id) \
    X(Name) \
    X(IconPath) \
    X(Background) \
    X(Description) \
    X(Status) \
    X(Author)

namespace PluginStoreList {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    PLUGINSTORE_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace PluginStoreList

class PluginStoreListModel : public AbstractListModelBase
{
    Q_OBJECT

public:
    explicit PluginStoreListModel(LRCInstance* lrcInstance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset();

    void addPlugin(const QVariantMap& plugin);
    void setPlugins(const QList<QVariantMap>& plugins);
    void removePlugin(const QString& pluginId);
    void updatePlugin(const QVariantMap& plugin);
    Q_INVOKABLE QColor computeAverageColorOfImage(const QString& fileUrl);

Q_SIGNALS:
    void pluginAdded(const QString& pluginId);

public Q_SLOTS:
    void onVersionStatusChanged(const QString& pluginId, PluginStatus::Role status);

private:
    QList<QVariantMap> filterPlugins(const QList<QVariantMap>& plugins);
    int rowFromPluginId(const QString& pluginId) const;
    void sort();
    using Role = PluginStoreList::Role;
    QList<QVariantMap> plugins_;
    LRCInstance* lrcInstance_ {};
};
