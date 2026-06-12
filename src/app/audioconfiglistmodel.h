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

#pragma once

#include <QAbstractListModel>

class AudioConfigListModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Role { AudioConfigOption = Qt::UserRole + 1, AudioConfigValue };
    Q_ENUM(Role);

    AudioConfigListModel(QObject* parent = 0);

    /*
     * QAbstractListModel override.
     */
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    /*
     * Override role name as access point in qml.
     */
    QHash<int, QByteArray> roleNames() const override;

    /*
     * This function gets the current device ID in the daemon.
     */
    Q_INVOKABLE int getCurrentSettingIndex(const QString& currentSelection) const;

private:
    // Display labels, translated at lookup time in data(). QT_TRANSLATE_NOOP
    // keeps them registered under the historical "QObject" context, where the
    // existing translations live.
    QList<const char*> audioConfigOptions = {QT_TRANSLATE_NOOP("QObject", "Auto (default)"),
                                             QT_TRANSLATE_NOOP("QObject", "System (if available)"),
                                             QT_TRANSLATE_NOOP("QObject", "Built-in"),
                                             QT_TRANSLATE_NOOP("QObject", "Disabled")};
    // Stable configuration values understood by the daemon, parallel to
    // audioConfigOptions. These are what get stored and must never be
    // translated or displayed.
    QList<QString> audioConfigValues = {QString("auto"),
                                        QString("system"),
                                        QString("audioProcessor"),
                                        QString("off")};
};
