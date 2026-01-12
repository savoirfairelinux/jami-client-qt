/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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

#include "audioconfiglistmodel.h"

AudioConfigListModel::AudioConfigListModel(QObject* parent)
    : QAbstractListModel(parent)
{}

int
AudioConfigListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid())
        return audioConfigOptions.size();

    /*
     * A valid QModelIndex returns 0 as no entry has sub-elements.
     */
    return 0;
}

int
AudioConfigListModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    /*
     * Only need one column.
     */
    return 1;
}

QVariant
AudioConfigListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    switch (role) {
    case Role::AudioConfigOption:
        return QVariant(audioConfigOptions.at(index.row()));
    }

    return QVariant();
}

QHash<int, QByteArray>
AudioConfigListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[Role::AudioConfigOption] = "AudioConfigOption";
    return roles;
}

int
AudioConfigListModel::getCurrentSettingIndex(const QString& currentSelection) const
{
    if (currentSelection == "auto") // Auto (default)
        return 0;
    else if (currentSelection == "system") // System (if available)
        return 1;
    else if (currentSelection == "audioProcessor") // Built-in
        return 2;
    else if (currentSelection == "off") // Disabled
        return 3;

    return 0;
}