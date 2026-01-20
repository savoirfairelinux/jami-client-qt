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

#include <QObject>
#include <QSettings>

#include "accountsettingspropertymap.h"

class AccountSettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(AccountSettingsPropertyMap* accountSettingsPropertyMap READ accountSettingsPropertyMap CONSTANT)
public:
    explicit AccountSettingsManager(QObject* parent = nullptr);

    AccountSettingsPropertyMap* accountSettingsPropertyMap()
    {
        return &accountSettingsPropertyMap_;
    }
    Q_INVOKABLE void initalizeAccountSettings();
    Q_INVOKABLE void updateCurrentAccount(const QString& newCurrentAccountID);
    Q_INVOKABLE void setValue(const QString& key, const QVariant& value);
    Q_INVOKABLE QVariant getValue(const QString& key);
    Q_INVOKABLE void resetToDefaults();

private:
    QSettings* accountSettings_;
    AccountSettingsPropertyMap accountSettingsPropertyMap_;
    QString currentAccountID_;
};
