/**
 * Copyright (C) 2019-2025 Savoir-faire Linux Inc.
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

#include "lrcinstance.h"

#include "api/pluginmodel.h"

PluginListPreferenceModel::PluginListPreferenceModel(QObject* parent)
    : AbstractListModelBase(parent)
{}

PluginListPreferenceModel::~PluginListPreferenceModel() {}

void
PluginListPreferenceModel::populateLists()
{
    preferenceValuesList_.clear();
    preferenceList_.clear();
    if (pluginId_.isEmpty())
        return;
    auto preferences = lrcInstance_->pluginModel().getPluginPreferences(pluginId_, "");
    if (!accountId_.isEmpty())
        preferences.append(lrcInstance_->pluginModel().getPluginPreferences(pluginId_, accountId_));
    for (const auto& preference : preferences) {
        if (preference["key"] == preferenceKey_) {
            if (preference.find("entries") != preference.end()
                && preference.find("entryValues") != preference.end())
                preferenceList_ = preference["entries"].split(",");
            preferenceValuesList_ = preference["entryValues"].split(",");
            break;
        }
    }
    getCurrentSettingIndex();
}

int
PluginListPreferenceModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        /// Count
        return preferenceList_.size();
    }
    /// A valid QModelIndex returns 0 as no entry has sub-elements.
    return 0;
}

QVariant
PluginListPreferenceModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || preferenceList_.size() <= index.row()) {
        return QVariant();
    }

    switch (role) {
    case Role::PreferenceValue:
        return QVariant(preferenceList_.at(index.row()));
    case Role::PreferenceEntryValue:
        return QVariant(preferenceValuesList_.at(index.row()));
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

void
PluginListPreferenceModel::reset()
{
    beginResetModel();
    endResetModel();
}

int
PluginListPreferenceModel::getCurrentSettingIndex()
{
    auto resultList = match(index(0, 0), PreferenceEntryValue, preferenceCurrentValue());

    int resultRowIndex = 0;
    if (resultList.size() > 0) {
        resultRowIndex = resultList[0].row();
    }

    return resultRowIndex;
}
