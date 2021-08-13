/**
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

class LRCInstance;

class PreferenceItemListModel : public AbstractListModelBase
{
    Q_OBJECT

    Q_PROPERTY(QString pluginId_ READ pluginId_ WRITE setPluginId)
    QML_PROPERTY(QString, category_)
    QML_PROPERTY(QString, mediaHandlerName_)
    QML_PROPERTY(QString, accountId_)
    QML_RO_PROPERTY(int, preferencesCount_)
public:
    enum Role {
        PreferenceKey = Qt::UserRole + 1,
        PreferenceName,
        PreferenceSummary,
        PreferenceType,
        PluginId,
        PreferenceCurrentValue,
        CurrentPath,
        FileFilters,
        IsImage,
        Enabled
    };

    typedef enum {
        LIST,
        PATH,
        EDITTEXT,
        SWITCH,
        DEFAULT,
    } Type;

    Q_ENUM(Role)
    Q_ENUM(Type)

    explicit PreferenceItemListModel(QObject* parent = nullptr);
    ~PreferenceItemListModel();

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
     * This function is to reset the model when there's new plugin added or modified.
     */
    Q_INVOKABLE void reset();

    QString pluginId_() const;
    void setPluginId(const QString& pluginId);

private:
    int preferencesCount();

    QString pluginId__;
    VectorMapStringString preferenceList_;
};
