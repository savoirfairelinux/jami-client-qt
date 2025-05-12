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
#include "connectivitymonitor.h"
#include "filedownloader.h"

#include <condition_variable>
#include <mutex>
#include <QObject>
#include <QApplication>
#include <QQmlEngine>
#include <QUrl>

class SpellCheckDictionaryManager : public QObject
{
    Q_OBJECT
    QVariantMap cachedInstalledDictionaries_;
    QVariantMap cachedAvailableDictionaries_;
    AppSettingsManager* settingsManager_;
    // To know what translation files are available on the remote
    // To initialize the fileDownloader
    ConnectivityMonitor* connectivityMonitor_;
    const QUrl dictionaryUrl_ {"https://cgit.freedesktop.org/libreoffice/dictionaries/plain/"};
    std::mutex mutex_;
    std::condition_variable conditionVariable_;

public:
    explicit SpellCheckDictionaryManager(AppSettingsManager* settingsManager,
                                         ConnectivityMonitor* cm,
                                         QObject* parent = nullptr);

    FileDownloader spellCheckFileDownloader;

    Q_INVOKABLE QVariantMap getInstalledDictionaries();
    Q_INVOKABLE QVariantMap getAvailableDictionaries();
    Q_INVOKABLE QString getDictionariesPath();
    Q_INVOKABLE void refreshDictionaries();
    Q_INVOKABLE QString getDictionaryPath();
    Q_INVOKABLE QString getSpellLanguage();
    Q_INVOKABLE QUrl getDictionaryUrl();
    Q_INVOKABLE bool isDictionnaryInstalled(QString locale);
    Q_INVOKABLE bool isDictionnaryAvailable(QString locale);
    Q_INVOKABLE QString getBestDictionary(QString locale);
    Q_INVOKABLE void updateDictionary(QString languagePath);
    Q_INVOKABLE void downloadDictionary(QString languagePath);
    Q_INVOKABLE void populateInstalledDictionaries();
    Q_INVOKABLE void populateAvailableDictionaries();

    Q_SIGNAL void dictionnariesListPopulated();
};
