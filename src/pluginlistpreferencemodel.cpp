/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

#include "pluginlistpreferencemodel.h"
#include <regex>

PluginListPreferenceModel::PluginListPreferenceModel(QObject *parent)
    : QAbstractListModel(parent)
{}

PluginListPreferenceModel::~PluginListPreferenceModel() {}

void
PluginListPreferenceModel::populateLists()
{
    preferenceCurrentValue_ = LRCInstance::pluginModel().getPluginPreferencesValues(pluginId_)[preferenceKey_];
    const auto preferences = LRCInstance::pluginModel().getPluginPreferences(pluginId_);
    for (const auto& preference : preferences) {
        if (preference["key"] == preferenceKey_) {
            auto entries = preference["entries"];
            auto entriesValues = preference["entryValues"];
            std::string entry = entries.toStdString();
            std::string entryValues = entriesValues.toStdString();
            entry = std::regex_replace(entry, std::regex("\\["), "$2");
            entry = std::regex_replace(entry, std::regex("\\]"), "$2");
            entryValues = std::regex_replace(entryValues, std::regex("\\["), "$2");
            entryValues = std::regex_replace(entryValues, std::regex("\\]"), "$2");
            std::string delimiter = ",";

            size_t pos = 0;
            std::string token;
            while ((pos = entry.find(delimiter)) != std::string::npos) {
                preferenceList_.emplace_back(entry.substr(0, pos));

                entry.erase(0, pos + delimiter.length());
            }
            preferenceList_.emplace_back(entry.substr(0, pos));
            while ((pos = entryValues.find(delimiter)) != std::string::npos) {
                preferenceValuesList_.emplace_back(entryValues.substr(0, pos));

                entryValues.erase(0, pos + delimiter.length());
            }
            preferenceValuesList_.emplace_back(entryValues.substr(0, pos));
        }
    }
}

int
PluginListPreferenceModel::rowCount(const QModelIndex &parent) const
{
    if (!parent.isValid()) {
        /*
         * Count.
         */

        return preferenceList_.size();
    }
    /*
     * A valid QModelIndex returns 0 as no entry has sub-elements.
     */
    return 0;
}

int
PluginListPreferenceModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    /*
     * Only need one column.
     */
    return 1;
}

QVariant
PluginListPreferenceModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || preferenceList_.size() <= index.row()) {
        return QVariant();
    }

    switch (role) {
    case Role::PreferenceValue:
        return QVariant(QString::fromStdString(preferenceList_.at(index.row())));
    case Role::PreferenceEntryValue:
        return QVariant(QString::fromStdString(preferenceValuesList_.at(index.row())));
    }
    return QVariant();
}

QHash<int, QByteArray>
PluginListPreferenceModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[PreferenceValue] = "PreferenceValue";
    roles[PreferenceEntryValue] = "PreferenceEntryValue";
    return roles;
}

QModelIndex
PluginListPreferenceModel::index(int row, int column, const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    if (column != 0) {
        return QModelIndex();
    }

    if (row >= 0 && row < rowCount()) {
        return createIndex(row, column);
    }
    return QModelIndex();
}

QModelIndex
PluginListPreferenceModel::parent(const QModelIndex &child) const
{
    Q_UNUSED(child);
    return QModelIndex();
}

Qt::ItemFlags
PluginListPreferenceModel::flags(const QModelIndex &index) const
{
    auto flags = QAbstractItemModel::flags(index) | Qt::ItemNeverHasChildren | Qt::ItemIsSelectable;
    if (!index.isValid()) {
        return QAbstractItemModel::flags(index);
    }
    return flags;
}

void
PluginListPreferenceModel::reset()
{
    beginResetModel();
    endResetModel();
}

int
PluginListPreferenceModel::getCurrentSettingIndex()
{
    auto resultList = match(index(0, 0), PreferenceEntryValue, preferenceCurrentValue_);

    int resultRowIndex = 0;
    if (resultList.size() > 0) {
        resultRowIndex = resultList[0].row();
    }

    return resultRowIndex;
}
