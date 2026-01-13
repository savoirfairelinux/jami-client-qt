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

#include "spellcheckdictionarylistmodel.h"

#include "global.h"

#include <QApplication>
#include <QBuffer>
#include <QClipboard>
#include <QFileInfo>
#include <QRegularExpression>
#include <QMimeData>
#include <QDir>
#include <QMimeDatabase>
#include <QUrl>
#include <QRegularExpression>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QStandardPaths>
#include <QFile>

SpellCheckDictionaryListModel::SpellCheckDictionaryListModel(AppSettingsManager* settingsManager,
                                                             ConnectivityMonitor* cm,
                                                             QObject* parent)
    : QAbstractListModel(parent)
    , spellCheckFileDownloader_(new FileDownloader(cm, this))
    , settingsManager_(settingsManager)
{
    // Connect FileDownloader signals
    connect(spellCheckFileDownloader_,
            &FileDownloader::downloadFileSuccessful,
            this,
            &SpellCheckDictionaryListModel::onDownloadFileFinished);
    connect(spellCheckFileDownloader_,
            &FileDownloader::downloadFileFailed,
            this,
            &SpellCheckDictionaryListModel::onDownloadFileFailed);

    // Initialize the model with available dictionaries and check if dictionaries are available
    // This will determine whether we need to notify the UI about a new available dictionary,
    // which is important because we want SpellCheckAdapter to be able to set the dictionary path
    // but only when dictionaries are available after initialization, and not on every download.
    dictionariesAvailable_ = populateDictionaries() > 0;

    // First, correct/migrate a bad setting that may have been set in the past
    auto spellLangLocale = settingsManager_->getValue(Settings::Key::SpellLang).toString();
    auto currentLocale = settingsManager_->getLanguage();
    if (spellLangLocale.isEmpty() || !isLocaleInstalled(spellLangLocale)) {
        C_WARN << "Spell check language setting is empty or invalid, resetting to current locale";
        settingsManager_->setValue(Settings::Key::SpellLang, currentLocale);
        installDictionary(currentLocale);
    }
}

QString
SpellCheckDictionaryListModel::pathForLocale(const QString& locale) const
{
    // Find the dictionary in the model and construct the path based on the locale and the
    // dictionary type (Jami-install or system)
    const auto index = getDictionaryIndex(locale);
    if (!index.isValid()) {
        return {};
    }
    const auto& dictObj = dictionaries_.at(index.row()).toObject();
    if (dictObj.value("isSystem").toBool()) {
        return systemDictionariesPath_ + locale;
    }
    return dictionariesPath_ + locale;
}

int
SpellCheckDictionaryListModel::rowCount(const QModelIndex& parent) const
{
    return dictionaries_.size();
}

QVariant
SpellCheckDictionaryListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return {};
    // Try to find the item at the index
    const auto& item = dictionaries_.at(index.row());
    if (!item.isObject())
        return {};
    // Try to convert the item to a QJsonObject
    const auto& itemObject = item.toObject().toVariantMap();
    switch (role) {
    case Role::NativeName:
        return itemObject.value("nativeName");
    case Role::Path:
        return itemObject.value("path");
    case Role::Locale:
        return itemObject.value("locale");
    case Role::Installed:
        return itemObject.value("installed").toBool();
    case Role::Downloading:
        return pendingDownloads_.contains(itemObject.value("locale").toString());
    case Role::IsSystem:
        return itemObject.value("isSystem").toBool();
    default:
        return {};
    }
}

QHash<int, QByteArray>
SpellCheckDictionaryListModel::roleNames() const
{
    using namespace SpellCheckDictionaryList;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    SPELL_CHECK_DICTIONARY_MODEL_ROLES
#undef X
    return roles;
}

int
SpellCheckDictionaryListModel::populateDictionaries()
{
    // First, we need to get the list of available dictionaries.
    QFile availableDictionariesFile(":/misc/available_dictionaries.json");
    if (!availableDictionariesFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        C_WARN << "Available Dictionaries file failed to load";
        return 0;
    }
    const auto availableDictionaries = QString(availableDictionariesFile.readAll());
    QJsonDocument doc = QJsonDocument::fromJson(availableDictionaries.toUtf8());
    /*
    The file is a JSON object with the following structure:
    {
        "af_ZA": {
            "nativeName": "Afrikaans (Suid-Afrika)",
            "path": "af_ZA/af_ZA"
        },
        ...
    }
    We want to convert it to a QJsonArray of QJsonObjects, each containing the locale,
    nativeName, path, and installed status.
    */
    if (doc.isNull() || !doc.isObject()) {
        C_WARN.noquote() << "Available Dictionaries file is not a valid JSON object";
        return 0;
    }

    beginResetModel();
    dictionaries_ = QJsonArray();

    const auto object = doc.object();

    // Get installed dictionaries to check status
    QString hunspellDataDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/dictionaries/";
    QDir dictionariesDir(hunspellDataDir);
    static const QRegularExpression regex("(.*).dic");
    QStringList installedLocales;

    // Check for dictionary files in the base directory
    QStringList rootDicFiles = dictionariesDir.entryList(QStringList() << "*.dic", QDir::Files);
    for (const auto& dicFile : rootDicFiles) {
        auto match = regex.match(dicFile);
        auto captured = match.capturedTexts();
        if (captured.size() == 2) {
            installedLocales << captured[1];
        }
    }

    // Check for dictionary files in the system directory
    QStringList systemDicFiles = QDir(systemDictionariesPath_).entryList(QStringList() << "*.dic", QDir::Files);
    for (const auto& dicFile : systemDicFiles) {
        auto match = regex.match(dicFile);
        auto captured = match.capturedTexts();
        if (captured.size() == 2) {
            installedLocales << captured[1];
        }
    }

    // Add the dictionaries to the model with the appropriate flags
    for (const auto& key : object.keys()) {
        const auto valueObject = object.value(key).toObject();
        bool isSystem = systemDicFiles.contains(key + ".dic");
        bool isInstalled = installedLocales.contains(key);
        dictionaries_.append(QJsonObject {{"locale", key},
                                          {"nativeName", valueObject.value("nativeName").toString()},
                                          {"path", valueObject.value("path").toString()},
                                          {"installed", isInstalled},
                                          {"isSystem", isSystem}});
    }
    endResetModel();
    return installedLocales.size();
}

Q_INVOKABLE void
SpellCheckDictionaryListModel::installDictionary(const QString& locale)
{
    // Check if dictionary is already installed
    const auto index = getDictionaryIndex(locale);
    if (!index.isValid()) {
        C_WARN << "Dictionary not found for locale:" << locale;
        return;
    }

    // Check if already installed
    auto dictObj = dictionaries_.at(index.row()).toObject();
    if (dictObj.value("installed").toBool()) {
        C_WARN << "Dictionary already installed for locale:" << locale;
        return;
    }

    // Check if download is already in progress
    if (pendingDownloads_.contains(locale)) {
        C_WARN << "Download already in progress for locale:" << locale;
        return;
    }

    // Start the download process
    downloadDictionaryFiles(locale);
}

Q_INVOKABLE void
SpellCheckDictionaryListModel::uninstallDictionary(const QString& locale)
{
    const auto index = getDictionaryIndex(locale);
    if (!index.isValid()) {
        C_WARN << "Dictionary not found for locale:" << locale;
        return;
    }

    // Check if dictionary is actually installed
    auto dictObj = dictionaries_.at(index.row()).toObject();
    if (!dictObj.value("installed").toBool()) {
        C_WARN << "Dictionary not installed for locale:" << locale;
        return;
    }

    // Check if the dictionary is a system dictionary (cannot be uninstalled here)
    if (dictObj.value("isSystem").toBool()) {
        C_WARN << "Cannot uninstall system dictionary:" << locale;
        return;
    }

    // Delete the dictionary files
    QString affFile = dictionariesPath_ + locale + ".aff";
    QString dicFile = dictionariesPath_ + locale + ".dic";

    bool affDeleted = true;
    bool dicDeleted = true;

    if (QFile::exists(affFile)) {
        affDeleted = QFile::remove(affFile);
        if (!affDeleted) {
            C_WARN << "Failed to delete .aff file:" << affFile;
        }
    }

    if (QFile::exists(dicFile)) {
        dicDeleted = QFile::remove(dicFile);
        if (!dicDeleted) {
            C_WARN << "Failed to delete .dic file:" << dicFile;
        }
    }

    // Update the installation status regardless of file deletion success
    // Note: This ensures the UI reflects the uninstall attempt only
    updateDictionaryInstallationStatus(locale, false);

    if (affDeleted && dicDeleted) {
        C_DBG << "Dictionary uninstalled successfully for locale:" << locale;
        Q_EMIT uninstallFinished(locale);
    } else {
        C_WARN << "Dictionary uninstall completed with errors for locale:" << locale;
        Q_EMIT uninstallFailed(locale);
    }
}

QVariantMap
SpellCheckDictionaryListModel::getInstalledDictionaries() const
{
    QVariantMap installedDictionaries;
    for (const auto& dict : dictionaries_) {
        const auto dictObj = dict.toObject();
        if (dictObj.value("installed").toBool()) {
            installedDictionaries.insert(dictObj.value("locale").toString(), dictObj.value("nativeName").toString());
        }
    }
    return installedDictionaries;
}

QModelIndex
SpellCheckDictionaryListModel::getDictionaryIndex(const QString& locale) const
{
    for (int i = 0; i < dictionaries_.size(); ++i) {
        if (dictionaries_.at(i).toObject().value("locale") == locale)
            return createIndex(i, 0);
    }
    return {}; // Not found
}

bool
SpellCheckDictionaryListModel::isLocaleInstalled(const QString& locale) const
{
    // Iterate through the dictionaries to check if the locale is installed
    for (const auto& dict : dictionaries_) {
        if (dict.toObject().value("locale").toString() == locale) {
            return dict.toObject().value("installed").toBool();
        }
    }
    return false; // Locale not found
}

void
SpellCheckDictionaryListModel::downloadDictionaryFiles(const QString& locale)
{
    C_DBG << "Downloading dictionary:" << locale;

    // Find the dictionary info
    const auto index = getDictionaryIndex(locale);
    if (!index.isValid()) {
        C_WARN << "Cannot download: dictionary not found for locale:" << locale;
        Q_EMIT downloadFailed(locale);
        return;
    }

    auto dictObj = dictionaries_.at(index.row()).toObject();
    QString basePath = dictObj.value("path").toString();

    if (basePath.isEmpty()) {
        C_WARN << "Cannot download: invalid path for dictionary" << locale;
        Q_EMIT downloadFailed(locale);
        return;
    }

    // Add to pending downloads
    pendingDownloads_.append(locale);
    Q_EMIT dataChanged(index, index, {Role::Downloading});

    // Create target directory if it doesn't exist
    QDir().mkpath(dictionariesPath_);

    QString targetFile = dictionariesPath_ + locale;

    // Construct URLs using the stored path
    QString baseUrl = downloadUrl_.toString();
    QUrl urlAff = baseUrl + "/" + basePath + ".aff";
    QUrl urlDic = baseUrl + "/" + basePath + ".dic";

    C_DBG << "Downloading dictionary files for" << locale;

    // Start downloads
    spellCheckFileDownloader_->downloadFile(urlAff, targetFile + ".aff");
    spellCheckFileDownloader_->downloadFile(urlDic, targetFile + ".dic");
}

void
SpellCheckDictionaryListModel::updateDictionaryInstallationStatus(const QString& locale, bool installed)
{
    const auto index = getDictionaryIndex(locale);
    if (!index.isValid()) {
        return;
    }

    // Update the dictionary object
    auto dictObj = dictionaries_.at(index.row()).toObject();
    dictObj["installed"] = installed;
    dictionaries_[index.row()] = dictObj;

    // Emit data changed signal
    Q_EMIT dataChanged(index, index, {SpellCheckDictionaryList::Installed});
}

void
SpellCheckDictionaryListModel::notifyDownloadStateChanged(const QString& locale)
{
    auto index = getDictionaryIndex(locale);
    if (index.isValid()) {
        Q_EMIT dataChanged(index, index, {Role::Downloading});
    }
}

void
SpellCheckDictionaryListModel::onDownloadFileFinished(const QString& localPath)
{
    C_DBG << "Download finished:" << localPath;

    // Extract locale from file path
    QFileInfo fileInfo(localPath);
    QString locale = fileInfo.baseName();

    // We need both a .dic file and a .aff file.
    // Check which one we downloaded and whether we already have the other one.
    bool haveBothFiles = false;
    if (localPath.endsWith(".dic")) {
        QString affFilePath = localPath;
        affFilePath.chop(4); // Remove ".dic"
        affFilePath += ".aff";

        if (QFile::exists(affFilePath)) {
            haveBothFiles = true;
        } else {
            C_DBG << "Waiting for .aff file for:" << locale;
        }
    } else if (localPath.endsWith(".aff")) {
        QString dicFilePath = localPath;
        dicFilePath.chop(4); // Remove ".aff"
        dicFilePath += ".dic";

        if (QFile::exists(dicFilePath)) {
            haveBothFiles = true;
        } else {
            C_DBG << "Waiting for .dic file for:" << locale;
        }
    }

    if (haveBothFiles) {
        // Both files are now available, mark as installed
        updateDictionaryInstallationStatus(locale, true);
        pendingDownloads_.removeAll(locale);
        notifyDownloadStateChanged(locale);
        Q_EMIT downloadFinished(locale);
        C_DBG << "Dictionary installation completed for:" << locale;

        // If we want to prevent installed dictionaries from being automatically set as the current
        // dictionary, then place the newDictionaryAvailable signal within the if block.
        Q_EMIT newDictionaryAvailable(locale);
        if (!dictionariesAvailable_) {
            dictionariesAvailable_ = true;
        }
    }
}

void
SpellCheckDictionaryListModel::onDownloadFileFailed(const QString& localPath)
{
    C_WARN << "Download failed for file:" << localPath;

    // Extract locale from file path
    QFileInfo fileInfo(localPath);
    QString locale = fileInfo.baseName();

    // Remove from pending downloads and emit failure signal
    pendingDownloads_.removeAll(locale);
    notifyDownloadStateChanged(locale);
    Q_EMIT downloadFailed(locale);
}
