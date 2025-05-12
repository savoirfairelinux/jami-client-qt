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
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>

class SpellCheckDictionaryManager : public QObject
{
    Q_OBJECT
    QVariantMap cachedInstalledDictionaries_;
    QVariantMap cachedAvailableDictionaries_;
    AppSettingsManager* settingsManager_;
    QNetworkAccessManager networkRequestManager_;
    const QUrl dictionaryUrl_ {"https://cgit.freedesktop.org/libreoffice/dictionaries/plain/"};

public:
    explicit SpellCheckDictionaryManager(AppSettingsManager* settingsManager,
                                         QObject* parent = nullptr);

    Q_INVOKABLE QVariantMap installedDictionaries();
    Q_INVOKABLE QVariantMap availableDictionaries();
    Q_INVOKABLE QString getDictionariesPath();
    Q_INVOKABLE void refreshDictionaries();
    Q_INVOKABLE QString getDictionaryPath();
    Q_INVOKABLE QString getSpellLanguage();
    Q_INVOKABLE QUrl getDictionaryUrl();
    Q_INVOKABLE bool isDictionnaryInstalled(QString locale);
    Q_INVOKABLE bool isDictionnaryAvailable(QString locale);
    Q_INVOKABLE QString getBestDictionary(QString locale);

    Q_SIGNAL void requestDictionaryDownload(QString locale);
};
