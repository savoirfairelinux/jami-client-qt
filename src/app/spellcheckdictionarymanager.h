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
#include "systemtray.h"

#include <QObject>
#include <QApplication>
#include <QQmlEngine>
#include <QUrl>
#include <QJsonObject>
#include <QJsonArray>
#include <QSystemTrayIcon>
#include <QtCore/QLoggingCategory>
#include <QAbstractListModel>
#include <QJsonDocument>

#define SPELL_CHECK_DICTIONARY_MODEL_ROLES \
    X(NativeName) \
    X(Path) \
    X(Locale) \
    X(Installed)

namespace SpellCheckDictionaryList {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    SPELL_CHECK_DICTIONARY_MODEL_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace SpellCheckDictionaryList

class SpellCheckDictionaryListModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit SpellCheckDictionaryListModel(ConnectivityMonitor* cm, QObject* parent = nullptr);
    ~SpellCheckDictionaryListModel() override = default;

    // QAbstractListModel interface
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void populateDictionaries();
    Q_INVOKABLE void installDictionary(const QString& locale);
    Q_INVOKABLE void uninstallDictionary(const QString& locale);

Q_SIGNALS:
    void downloadFinished(const QString& locale);
    void downloadFailed(const QString& locale);
    void uninstallFinished(const QString& locale);
    void uninstallFailed(const QString& locale);

protected:
    using Role = SpellCheckDictionaryList::Role;

private Q_SLOTS:
    void onDownloadFileFinished(const QString& localPath);
    void onDownloadFileFailed(const QString& localPath);

private:
    // Underlying data
    QJsonArray dictionaries_;

    // Utility to get the index of a dictionary
    QModelIndex getDictionaryIndex(const QString& locale) const;

    // Helper methods for download functionality
    void downloadDictionaryFiles(const QString& locale);
    void updateDictionaryInstallationStatus(const QString& locale, bool installed);
    QString getDictionariesPath() const;

    // Downloader utility
    FileDownloader* spellCheckFileDownloader_;
    const QUrl downloadUrl_ {"https://raw.githubusercontent.com/LibreOffice/dictionaries/master"};
    const QString dictionariesPath_ = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                                      + "/dictionaries/";

    // Track pending downloads
    QStringList pendingDownloads_;
};

class SpellCheckDictionaryManager : public QObject
{
    Q_OBJECT
    QJsonObject cachedInstalledDictionaries_;
    QJsonObject cachedAvailableDictionaries_;
    QJsonObject cachedCompleteDictionariesList_;
    // To know what translation files are available on the remote
    const QUrl downloadUrl_ {"https://raw.githubusercontent.com/LibreOffice/dictionaries/master"};
    AppSettingsManager* settingsManager_;
    SystemTray* systemTray_;

public:
    explicit SpellCheckDictionaryManager(AppSettingsManager* settingsManager,
                                         ConnectivityMonitor* cm,
                                         SystemTray* systemTray,
                                         QObject* parent = nullptr);
    ~SpellCheckDictionaryManager();

    FileDownloader* spellCheckFileDownloader;

    Q_INVOKABLE QJsonObject getInstalledDictionaries();
    Q_INVOKABLE QJsonObject getAvailableDictionaries(); // Changed return type
    Q_INVOKABLE QString getDictionariesPath();
    Q_INVOKABLE void refreshDictionaries();
    Q_INVOKABLE QString getDictionaryPath();
    Q_INVOKABLE QString getSpellLanguage();
    Q_INVOKABLE QUrl getDictionaryUrl();
    Q_INVOKABLE bool isDictionnaryInstalled(const QString& locale);
    Q_INVOKABLE bool isDictionnaryAvailable(const QString& locale);
    Q_INVOKABLE QString getBestDictionary(QString locale);
    Q_INVOKABLE void updateDictionary(QString languagePath);
    Q_INVOKABLE void downloadDictionary(QString languagePath);
    Q_INVOKABLE void populateInstalledDictionaries();
    Q_INVOKABLE void populateAvailableDictionaries();
    Q_INVOKABLE QString getUILanguage();

    Q_SIGNAL void dictionaryAvailable();
    Q_SIGNAL void downloadFinished();
    Q_SIGNAL QString dictionaryDownloadFailed(const QString& localPath);

    Q_SLOT void onDownloadFileFinished(const QString& localPath);
    Q_SLOT void onDownloadFileFailed(const QString& localPath);
};
