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
    X(Installed) \
    X(Downloading) \
    X(IsSystem)

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
    explicit SpellCheckDictionaryListModel(AppSettingsManager* settingsManager,
                                           ConnectivityMonitor* cm,
                                           QObject* parent = nullptr);
    ~SpellCheckDictionaryListModel() override = default;

    // Construct the final path for a given locale. This could be either
    // a Jami-install or a system dictionary.
    QString pathForLocale(const QString& locale) const;

    // QAbstractListModel interface
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // SpellCheckAdapter needs access to the dictionary management methods
    friend class SpellCheckAdapter;

Q_SIGNALS:
    void downloadFinished(const QString& locale);
    void downloadFailed(const QString& locale);
    void uninstallFinished(const QString& locale);
    void uninstallFailed(const QString& locale);

    // When a new dictionary is available, emit the signal so we can use
    // it to set the current dictionary from the SpellCheckAdapter
    void newDictionaryAvailable(const QString& locale);

protected:
    using Role = SpellCheckDictionaryList::Role;

    void installDictionary(const QString& locale);
    void uninstallDictionary(const QString& locale);

    QVariantMap getInstalledDictionaries() const;

private Q_SLOTS:
    void onDownloadFileFinished(const QString& localPath);
    void onDownloadFileFailed(const QString& localPath);

private:
    QJsonArray dictionaries_;            // Principal underlying data structure
    QStringList pendingDownloads_;       // Used to track pending downloads and status
    bool dictionariesAvailable_ {false}; // Flag to indicate if dictionaries are available

    int populateDictionaries(); // Returns number of installed dictionaries

    // Utility to get the index of a dictionary
    QModelIndex getDictionaryIndex(const QString& locale) const;
    bool isLocaleInstalled(const QString& locale) const;

    // Helper methods for download functionality
    void downloadDictionaryFiles(const QString& locale);
    void updateDictionaryInstallationStatus(const QString& locale, bool installed);
    void notifyDownloadStateChanged(const QString& locale);

    // Dictionary file management and downloading
    FileDownloader* spellCheckFileDownloader_;
    const QUrl downloadUrl_ {"https://raw.githubusercontent.com/LibreOffice/dictionaries/master"};
    const QString dictionariesPath_ = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                                      + "/dictionaries/";
#if defined(Q_OS_LINUX)
    const QString systemDictionariesPath_ = "/usr/share/hunspell/";
#elif defined(Q_OS_MACOS)
    const QString systemDictionariesPath_ = "/Library/Spelling/";
#else
    const QString systemDictionariesPath_ = "";
#endif

    AppSettingsManager* settingsManager_;
};
