/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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

#ifndef ACCOUNTSETTINGSPROPERTYMAP_H
#define ACCOUNTSETTINGSPROPERTYMAP_H

#include <QQmlPropertyMap>

class AccountSettingsPropertyMap : public QQmlPropertyMap
{
    Q_OBJECT
public:
    explicit AccountSettingsPropertyMap(QObject* parent = nullptr)
        : QQmlPropertyMap(this, parent)
    {}

    void setAccountSettingProperty(const QString& key, const QVariant& value)
    {
        updateValue(key, value);
    }

protected:
    QVariant updateValue(const QString& key, const QVariant& value) override
    {
        // No need to update the value if theyre the same!
        if (this->value(key) != value) {
            insert(key, value);
            Q_EMIT valueChanged(key, value);
        }
        return value;
    }

Q_SIGNALS:
    void valueChanged(const QString& key, const QVariant& value);
};

#endif // ACCOUNTSETTINGSPROPERTYMAP_H
