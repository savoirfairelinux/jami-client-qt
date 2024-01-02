/**
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

#include "api/pluginmodel.h"

class PluginListPreferenceModel : public AbstractListModelBase
{
    Q_OBJECT
    Q_PROPERTY(QString preferenceNewValue READ preferenceNewValue WRITE setPreferenceNewValue NOTIFY
                   preferenceNewValueChanged)
    Q_PROPERTY(QString pluginId READ pluginId WRITE setPluginId NOTIFY pluginIdChanged)
    QML_PROPERTY(QString, preferenceKey)
    QML_PROPERTY(int, idx)
    QML_PROPERTY(QString, accountId)
public:
    enum Role { PreferenceValue = Qt::UserRole + 1, PreferenceEntryValue };
    Q_ENUM(Role)

    explicit PluginListPreferenceModel(QObject* parent = nullptr);
    ~PluginListPreferenceModel();

    // QAbstractListModel override.
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // This function is to reset the model when there's new account added.
    Q_INVOKABLE void reset();

    // This function is to get the current preference value.
    Q_INVOKABLE int getCurrentSettingIndex();

    Q_INVOKABLE void populateLists();

    void setPreferenceNewValue(const QString preferenceNewValue)
    {
        if (preferenceNewValue_ != preferenceNewValue) {
            preferenceNewValue_ = preferenceNewValue;
            Q_EMIT preferenceNewValueChanged();
        }
    }

    void setPluginId(const QString pluginId)
    {
        if (pluginId_ != pluginId) {
            pluginId_ = pluginId;
            populateLists();
            Q_EMIT pluginIdChanged();
        }
    }

    QString preferenceCurrentValue()
    {
        return lrcInstance_->pluginModel().getPluginPreferencesValues(pluginId_,
                                                                      accountId_)[preferenceKey_];
    }

    QString preferenceNewValue()
    {
        preferenceNewValue_ = preferenceValuesList_[idx_];
        return preferenceNewValue_;
    }

    QString pluginId()
    {
        return pluginId_;
    }

Q_SIGNALS:
    void preferenceNewValueChanged();
    void pluginIdChanged();

private:
    QString pluginId_ {};
    QString preferenceNewValue_ {};
    QStringList preferenceValuesList_;
    QStringList preferenceList_;
};
