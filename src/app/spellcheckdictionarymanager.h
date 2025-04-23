/*
 * Copyright (C) 2015-2025 Savoir-faire Linux Inc.
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
#include <QApplication>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration
#include "appsettingsmanager.h"

class SpellCheckDictionaryManager : public QObject
{
    Q_OBJECT
public:
    explicit SpellCheckDictionaryManager(AppSettingsManager* settingsManager, QObject* parent = nullptr);

    QVariantMap cachedinstalledDictionaries;
    AppSettingsManager* settingsManager_;
    Q_INVOKABLE QVariantMap installedDictionaries();
    Q_INVOKABLE const QString getDictionariesPath();
    Q_INVOKABLE const QString getDictionaryUrl();
    Q_INVOKABLE void refreshDictionaries();
    Q_INVOKABLE const QString getDictionaryPath();
    Q_INVOKABLE QString getSpellLanguage();
    // Q_INVOKABLE QString getLanguage();
    static constexpr char dictionaryUrl[]
        = "https://cgit.freedesktop.org/libreoffice/dictionaries/plain/";
};
