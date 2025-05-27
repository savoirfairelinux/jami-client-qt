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

#include "spellcheckdictionarymanager.h"

#include "global.h"
#include "utils.h"

#include <QApplication>
#include <QBuffer>
#include <QClipboard>
#include <QFileInfo>
#include <QRegExp>
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

SpellCheckDictionaryListModel::SpellCheckDictionaryListModel(ConnectivityMonitor* cm,
                                                             QObject* parent)
    : QAbstractListModel(parent)
    , spellCheckFileDownloader_(new FileDownloader(cm, this))
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

    // We need access to the SpellCheckDictionaryManager to check installed dictionaries
    // For now, we'll populate without the installed status and update it later
    populateDictionaries();
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

Q_INVOKABLE void
SpellCheckDictionaryListModel::populateDictionaries()
{
    Q_EMIT beginResetModel();
    dictionaries_ = QJsonArray();

    // First, we need to get the list of available dictionaries.
    QFile availableDictionariesFile(":/misc/available_dictionaries.json");
    if (!availableDictionariesFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning().noquote() << "Available Dictionaries file failed to load";
        return;
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
    if (!doc.isNull() && doc.isObject()) {
        const auto object = doc.object();

        // Get installed dictionaries to check status
        QString hunspellDataDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                                  + "/dictionaries/";
        QDir dictionariesDir(hunspellDataDir);
        QRegExp regex("(.*).dic");
        QStringList installedLocales;

        // Check for dictionary files in the base directory
        QStringList rootDicFiles = dictionariesDir.entryList(QStringList() << "*.dic", QDir::Files);
        for (const auto& dicFile : rootDicFiles) {
            regex.indexIn(dicFile);
            auto captured = regex.capturedTexts();
            if (captured.size() == 2) {
                installedLocales << captured[1];
            }
        }

        // Check for dictionary files in subdirectories
        QStringList folders = dictionariesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const auto& folder : folders) {
            QDir subDir = dictionariesDir.absoluteFilePath(folder);
            QStringList dicFiles = subDir.entryList(QStringList() << "*.dic", QDir::Files);
            for (const auto& dicFile : dicFiles) {
                regex.indexIn(dicFile);
                auto captured = regex.capturedTexts();
                if (captured.size() == 2) {
                    installedLocales << captured[1];
                }
            }
        }

        for (const auto& key : object.keys()) {
            const auto value = object.value(key).toObject();
            bool isInstalled = installedLocales.contains(key);
            dictionaries_.append(QJsonObject {{"locale", key},
                                              {"nativeName", value.value("nativeName").toString()},
                                              {"path", value.value("path").toString()},
                                              {"installed", isInstalled}});
        }
    }

    Q_EMIT endResetModel();
}

Q_INVOKABLE void
SpellCheckDictionaryListModel::installDictionary(const QString& locale)
{
    // Check if dictionary is already installed
    const auto index = getDictionaryIndex(locale);
    if (!index.isValid()) {
        qWarning() << "Dictionary not found for locale:" << locale;
        return;
    }

    // Check if already installed
    auto dictObj = dictionaries_.at(index.row()).toObject();
    if (dictObj.value("installed").toBool()) {
        qWarning() << "Dictionary already installed for locale:" << locale;
        return;
    }

    // Check if download is already in progress
    if (pendingDownloads_.contains(locale)) {
        qWarning() << "Download already in progress for locale:" << locale;
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
        qWarning() << "Dictionary not found for locale:" << locale;
        return;
    }

    // Check if dictionary is actually installed
    auto dictObj = dictionaries_.at(index.row()).toObject();
    if (!dictObj.value("installed").toBool()) {
        qWarning() << "Dictionary not installed for locale:" << locale;
        return;
    }

    // Delete the dictionary files
    QString targetDir = getDictionariesPath();
    QString affFile = targetDir + locale + ".aff";
    QString dicFile = targetDir + locale + ".dic";

    bool affDeleted = true;
    bool dicDeleted = true;

    if (QFile::exists(affFile)) {
        affDeleted = QFile::remove(affFile);
        if (!affDeleted) {
            qWarning() << "Failed to delete .aff file:" << affFile;
        }
    }

    if (QFile::exists(dicFile)) {
        dicDeleted = QFile::remove(dicFile);
        if (!dicDeleted) {
            qWarning() << "Failed to delete .dic file:" << dicFile;
        }
    }

    // Update the installation status regardless of file deletion success
    // This ensures the UI reflects the uninstall attempt
    updateDictionaryInstallationStatus(locale, false);

    if (affDeleted && dicDeleted) {
        qDebug() << "Dictionary uninstalled successfully for locale:" << locale;
        Q_EMIT uninstallFinished(locale);
    } else {
        qWarning() << "Dictionary uninstall completed with errors for locale:" << locale;
        Q_EMIT uninstallFailed(locale);
    }
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

void
SpellCheckDictionaryListModel::downloadDictionaryFiles(const QString& locale)
{
    // Find the dictionary info
    const auto index = getDictionaryIndex(locale);
    if (!index.isValid()) {
        qWarning() << "Cannot download: dictionary not found for locale:" << locale;
        return;
    }

    auto dictObj = dictionaries_.at(index.row()).toObject();
    QString basePath = dictObj.value("path").toString();

    if (basePath.isEmpty()) {
        qWarning() << "Cannot download: invalid path for dictionary" << locale;
        Q_EMIT downloadFailed(locale);
        return;
    }

    // Add to pending downloads
    pendingDownloads_.append(locale);

    // Create target directory if it doesn't exist
    QString targetDir = getDictionariesPath();
    QDir().mkpath(targetDir);

    QString targetFile = targetDir + locale;

    // Construct URLs using the stored path
    QString baseUrl = downloadUrl_.toString();
    QUrl urlAff = baseUrl + "/" + basePath + ".aff";
    QUrl urlDic = baseUrl + "/" + basePath + ".dic";

    qDebug() << "Downloading dictionary files for" << locale;
    qDebug() << "AFF URL:" << urlAff.toString();
    qDebug() << "DIC URL:" << urlDic.toString();
    qDebug() << "Target:" << targetFile;

    // Start downloads
    spellCheckFileDownloader_->downloadFile(urlAff, targetFile + ".aff");
    spellCheckFileDownloader_->downloadFile(urlDic, targetFile + ".dic");
}

void
SpellCheckDictionaryListModel::updateDictionaryInstallationStatus(const QString& locale,
                                                                  bool installed)
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

QString
SpellCheckDictionaryListModel::getDictionariesPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/dictionaries/";
}

void
SpellCheckDictionaryListModel::onDownloadFileFinished(const QString& localPath)
{
    qDebug() << "Download finished:" << localPath;

    // Extract locale from file path
    QFileInfo fileInfo(localPath);
    QString locale = fileInfo.baseName();

    // Check if this is a .dic file and if the corresponding .aff file exists
    if (localPath.endsWith(".dic")) {
        QString affFilePath = localPath;
        affFilePath.chop(4); // Remove ".dic"
        affFilePath += ".aff";

        if (QFile::exists(affFilePath)) {
            // Both files are now available, mark as installed
            updateDictionaryInstallationStatus(locale, true);
            pendingDownloads_.removeAll(locale);
            Q_EMIT downloadFinished(locale);
            qDebug() << "Dictionary installation completed for:" << locale;
        } else {
            qDebug() << "Waiting for .aff file for:" << locale;
        }
    } else if (localPath.endsWith(".aff")) {
        QString dicFilePath = localPath;
        dicFilePath.chop(4); // Remove ".aff"
        dicFilePath += ".dic";

        if (QFile::exists(dicFilePath)) {
            // Both files are now available, mark as installed
            updateDictionaryInstallationStatus(locale, true);
            pendingDownloads_.removeAll(locale);
            Q_EMIT downloadFinished(locale);
            qDebug() << "Dictionary installation completed for:" << locale;
        } else {
            qDebug() << "Waiting for .dic file for:" << locale;
        }
    }
}

void
SpellCheckDictionaryListModel::onDownloadFileFailed(const QString& localPath)
{
    qWarning() << "Download failed for file:" << localPath;

    // Extract locale from file path
    QFileInfo fileInfo(localPath);
    QString locale = fileInfo.baseName();

    // Remove from pending downloads and emit failure signal
    pendingDownloads_.removeAll(locale);
    Q_EMIT downloadFailed(locale);
}

SpellCheckDictionaryManager::SpellCheckDictionaryManager(AppSettingsManager* settingsManager,
                                                         ConnectivityMonitor* cm,
                                                         SystemTray* systemTray,
                                                         QObject* parent)
    : QObject {parent}
    , settingsManager_ {settingsManager}
    , systemTray_ {systemTray}
    , spellCheckFileDownloader {new FileDownloader(cm, this)}
{
    populateInstalledDictionaries();
    populateAvailableDictionaries();
    connect(spellCheckFileDownloader,
            &FileDownloader::downloadFileFailed,
            this,
            &SpellCheckDictionaryManager::onDownloadFileFailed);
    connect(spellCheckFileDownloader,
            &FileDownloader::downloadFileSuccessful,
            this,
            &SpellCheckDictionaryManager::onDownloadFileFinished);
}

SpellCheckDictionaryManager::~SpellCheckDictionaryManager()
{
    delete spellCheckFileDownloader;
}

QJsonObject
SpellCheckDictionaryManager::getInstalledDictionaries()
{
    // If we already have a cache of the installed dictionaries, just return it
    if (cachedInstalledDictionaries_.isEmpty()) {
        qWarning() << "Cache is empty, populating installed dictionaries";
        // Else we need to populate it
        populateInstalledDictionaries();
    } else {
        qWarning() << "Returning cached installed dictionaries with"
                   << cachedInstalledDictionaries_.keys().size()
                   << "entries:" << cachedInstalledDictionaries_.keys();
    }
    return cachedInstalledDictionaries_;
}

void
SpellCheckDictionaryManager::populateInstalledDictionaries()
{
    QString hunspellDataDir = getDictionariesPath();
    qWarning() << "Populating installed dictionaries from:" << hunspellDataDir;

    auto dictionariesDir = QDir(hunspellDataDir);
    QRegExp regex("(.*).dic");

    QJsonObject result;
    // Add "NONE" option with same format as other entries
    QJsonObject noneObj;
    noneObj["nativeName"] = tr("None");
    noneObj["path"] = "NONE";
    result["NONE"] = noneObj;

    // Make sure available dictionaries are loaded
    if (cachedAvailableDictionaries_.isEmpty()) {
        qWarning() << "Available dictionaries cache is empty, populating it first";
        populateAvailableDictionaries();
    }

    // Check for dictionary files in the base directory
    QStringList rootDicFiles = dictionariesDir.entryList(QStringList() << "*.dic", QDir::Files);
    qWarning() << "Found" << rootDicFiles.size()
               << "dictionary files in root directory:" << rootDicFiles;

    for (const auto& dicFile : rootDicFiles) {
        regex.indexIn(dicFile);
        auto captured = regex.capturedTexts();
        if (captured.size() == 2) {
            QString locale = captured[1];
            // If this dictionary exists in available dictionaries, copy its info and remove from available
            if (cachedCompleteDictionariesList_.contains(locale)) {
                result[locale] = cachedCompleteDictionariesList_[locale];
                if (cachedAvailableDictionaries_.contains(locale)) {
                    cachedAvailableDictionaries_.remove(locale);
                    qWarning() << "Removed dictionary for locale:" << locale;
                }
            }
        }
    }

    // Check for dictionary files in subdirectories
    QStringList folders = dictionariesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    qWarning() << "Found" << folders.size() << "subdirectories:" << folders;

    for (const auto& folder : folders) {
        QDir subDir = dictionariesDir.absoluteFilePath(folder);
        QStringList dicFiles = subDir.entryList(QStringList() << "*.dic", QDir::Files);
        qWarning() << "Found" << dicFiles.size() << "dictionary files in" << folder << ":"
                   << dicFiles;

        for (const auto& dicFile : dicFiles) {
            regex.indexIn(dicFile);
            auto captured = regex.capturedTexts();

            if (captured.size() == 2) {
                QString locale = captured[1];
                QString key = folder + QDir::separator() + locale;

                // If this dictionary exists in available dictionaries, copy its info and remove
                // from available
                if (cachedCompleteDictionariesList_.contains(locale)) {
                    result[key] = cachedCompleteDictionariesList_[locale];
                    if (cachedAvailableDictionaries_.contains(locale)) {
                        cachedAvailableDictionaries_.remove(locale);
                        qWarning()
                            << "Removed dictionary for locale:" << locale << "with key:" << key;
                    }
                }
            }
        }
    }

    cachedInstalledDictionaries_ = result;
    qWarning() << "Final installed dictionaries count:" << result.keys().size()
               << "with keys:" << result.keys();
}

void
SpellCheckDictionaryManager::refreshDictionaries()
{
    populateInstalledDictionaries();
}

QString
SpellCheckDictionaryManager::getSpellLanguage()
{
    auto pref = settingsManager_->getValue(Settings::Key::SpellLang).toString();
    return pref;
}
QString
SpellCheckDictionaryManager::getUILanguage()
{
    auto pref = settingsManager_->getValue(Settings::Key::LANG).toString();
    return pref;
}

QJsonObject
SpellCheckDictionaryManager::getAvailableDictionaries()
{
    if (cachedAvailableDictionaries_.isEmpty()) {
        populateAvailableDictionaries();
    }
    return cachedAvailableDictionaries_;
}

void
SpellCheckDictionaryManager::populateAvailableDictionaries()
{
    QString jsonString = Utils::getAvailableDictionariesJson();
    if (jsonString.isEmpty()) {
        C_ERR << "Could not load available dictionaries list";
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(jsonString.toUtf8());
    if (!doc.isNull() && doc.isObject()) {
        cachedAvailableDictionaries_ = doc.object();
        cachedCompleteDictionariesList_ = doc.object();
    } else {
        C_ERR << "Invalid JSON format in available dictionaries file";
    }
}

QString
SpellCheckDictionaryManager::getDictionariesPath()
{
    QString hunDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                     + "/dictionaries/";
    return hunDir;
}

QString
SpellCheckDictionaryManager::getDictionaryPath()
{
    C_DBG << "getDictionaryPath() :" << getDictionariesPath() << getSpellLanguage();
    return getDictionariesPath() + getSpellLanguage();
}

bool
SpellCheckDictionaryManager::isDictionnaryInstalled(const QString& locale)
{
    return cachedInstalledDictionaries_.contains(locale);
}

bool
SpellCheckDictionaryManager::isDictionnaryAvailable(const QString& locale)
{
    return cachedAvailableDictionaries_.contains(locale);
}

QUrl
SpellCheckDictionaryManager::getDictionaryUrl()
{
    return downloadUrl_;
}

QString
SpellCheckDictionaryManager::getBestDictionary(QString locale)
{
    // Automatically set the spell language to the best available dictionary
    if (locale == "NONE") {
        locale = getUILanguage();
        C_DBG << "Locale set to user interface language:" << locale;
    }
    QString bestDictionary;
    // Check if the dictionnary is installed
    if (isDictionnaryInstalled(locale)) {
        bestDictionary = locale;
        settingsManager_->setValue(Settings::Key::SpellLang, bestDictionary);
        Q_EMIT dictionaryAvailable();
        C_DBG << "Installed dictionary for locale:" << bestDictionary;
        return bestDictionary;
    }
    // Check if the dictionary is available at the repository
    if (isDictionnaryAvailable(locale)) {
        bestDictionary = locale;
        downloadDictionary(locale);
        C_DBG << "Downloading dictionary for locale:" << bestDictionary;
        return bestDictionary;
    }
    // check if a local starting with the same 2 first letters is installed
    QStringList localeParts = locale.split("_");
    QString locale2letters = localeParts[0];
    QList key_iterator = cachedInstalledDictionaries_.keys();
    for (const auto& key : key_iterator) {
        if (key.startsWith(locale2letters)) {
            bestDictionary = key;
            settingsManager_->setValue(Settings::Key::SpellLang, bestDictionary);
            Q_EMIT dictionaryAvailable();
            C_DBG << "Installed dictionary for locale with same language:" << bestDictionary;
            return bestDictionary;
        }
    }
    // check if a local starting with the same 2 first letters is available
    key_iterator = cachedAvailableDictionaries_.keys();
    for (const auto& key : key_iterator) {
        if (key.startsWith(locale2letters)) {
            bestDictionary = key;
            downloadDictionary(bestDictionary);
            C_DBG << "Downloading dictionary for locale with same language:" << bestDictionary;
            return bestDictionary;
        }
    }
    if (bestDictionary.isEmpty()) {
        C_DBG << "No dictionary found for locale:" << locale;
        // Fallback to the default dictionary
        bestDictionary = "en_US";
        getBestDictionary(bestDictionary);
    }
    return bestDictionary;
}

void
SpellCheckDictionaryManager::updateDictionary(QString languagePath)
{
    getBestDictionary(languagePath);
}

void
SpellCheckDictionaryManager::downloadDictionary(QString languagePath)
{
    if (getDictionaryUrl().isEmpty()) {
        C_ERR << "Dictionary " << languagePath << " cannot be downloaded : No dictionary URL set";
        return;
    }

    // Get dictionary info from cached data
    QJsonValue dictValue = cachedAvailableDictionaries_[languagePath];
    if (dictValue.isUndefined() || !dictValue.isObject()) {
        C_WARN << "Dictionary info not found for" << languagePath;
        return;
    }

    QJsonObject dictInfo = dictValue.toObject();
    QString basePath = dictInfo["path"].toString();
    if (basePath.isEmpty()) {
        C_WARN << "Invalid path for dictionary" << languagePath;
        return;
    }

    QString file = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                   + "/dictionaries/" + languagePath;

    // Construct URLs using the stored path
    QString baseUrl = downloadUrl_.toString();
    QUrl urlAff = baseUrl + "/" + basePath + ".aff";
    QUrl urlDic = baseUrl + "/" + basePath + ".dic";

    if (!file.isEmpty()) {
        spellCheckFileDownloader->downloadFile(urlAff, file + ".aff");
        spellCheckFileDownloader->downloadFile(urlDic, file + ".dic");
    } else {
        C_WARN << "Dictionary " << languagePath << " cannot be downloaded : No dictionary path set";
    }
}

void
SpellCheckDictionaryManager::onDownloadFileFinished(const QString& localPath)
{
    // Handle the downloaded file (e.g., install the dictionary)
    // If this is a .dic file we emit the signal
    if (localPath.endsWith(".dic")) {
        // Check if the corresponding .aff file exists
        QString affFilePath = localPath;
        affFilePath.chop(4); // Remove ".dic"
        affFilePath += ".aff";

        // Extract the locale name from the path
        QFileInfo fileInfo(localPath);
        QString locale = fileInfo.baseName();

        if (QFile::exists(affFilePath)) {
            settingsManager_->setValue(Settings::Key::SpellLang, locale);
            Q_EMIT dictionaryAvailable();
            Q_EMIT downloadFinished();
        } else {
            C_WARN << "Missing .aff file for dictionary:" << localPath;
        }
    }
}

void
SpellCheckDictionaryManager::onDownloadFileFailed(const QString& localPath)
{
    C_WARN << "Download failed for file:" << localPath;
    Q_EMIT dictionaryDownloadFailed(localPath);
}
