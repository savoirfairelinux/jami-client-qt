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

#pragma once
#include "appsettingsmanager.h"

#include <QObject>
#include <QApplication>
#include <QQmlEngine>

class SpellCheckDictionaryManager : public QObject
{
    Q_OBJECT
    QVariantMap cachedInstalledDictionaries_;
    AppSettingsManager* settingsManager_;
public:
    explicit SpellCheckDictionaryManager(AppSettingsManager* settingsManager,
                                         QObject* parent = nullptr);

    Q_INVOKABLE QVariantMap installedDictionaries();
    Q_INVOKABLE QString getDictionariesPath();
    Q_INVOKABLE void refreshDictionaries();
    Q_INVOKABLE QString getDictionaryPath();
    Q_INVOKABLE QString getSpellLanguage();
};
