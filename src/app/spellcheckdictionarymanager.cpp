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

SpellCheckDictionaryManager::SpellCheckDictionaryManager(AppSettingsManager* settingsManager,
                                                         ConnectivityMonitor* cm,
                                                         QObject* parent)
    : QObject {parent}
    , settingsManager_ {settingsManager}
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

QVariantMap
SpellCheckDictionaryManager::getInstalledDictionaries()
{
    // If we already have a cache of the installed dictionaries, return it
    if (cachedInstalledDictionaries_.size() == 0) {
        // Else we need to populate it
        populateInstalledDictionaries();
    }
    return cachedInstalledDictionaries_;
}

void
SpellCheckDictionaryManager::populateInstalledDictionaries()
{
    QString hunspellDataDir = getDictionariesPath();

    auto dictionariesDir = QDir(hunspellDataDir);
    QRegExp regex("(.*).dic");
    QSet<QString> nativeNames;

    QVariantMap result;
    result["NONE"] = tr("None");
    QStringList folders = dictionariesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    // Check for dictionary files in the base directory
    QStringList rootDicFiles = dictionariesDir.entryList(QStringList() << "*.dic", QDir::Files);
    for (const auto& dicFile : rootDicFiles) {
        regex.indexIn(dicFile);
        auto captured = regex.capturedTexts();
        if (captured.size() == 2) {
            auto nativeName = QLocale(captured[1]).nativeLanguageName();
            if (!nativeName.isEmpty() && !nativeNames.contains(nativeName)) {
                result[captured[1]] = nativeName;
                nativeNames.insert(nativeName);
            }
        }
    }
    // Check for dictionary files in subdirectories
    for (const auto& folder : folders) {
        QDir subDir = dictionariesDir.absoluteFilePath(folder);
        QStringList dicFiles = subDir.entryList(QStringList() << "*.dic", QDir::Files);
        subDir.setFilter(QDir::Files | QDir::AllDirs | QDir::NoDotAndDotDot);
        subDir.setSorting(QDir::DirsFirst);
        QFileInfoList list = subDir.entryInfoList();
        for (const auto& fileInfo : list) {
            if (fileInfo.isDir()) {
                QDir recursiveDir(fileInfo.absoluteFilePath());
                QStringList recursiveDicFiles = recursiveDir.entryList(QStringList() << "*.dic",
                                                                       QDir::Files);
                if (!recursiveDicFiles.isEmpty()) {
                    dicFiles.append(recursiveDicFiles);
                }
            }
        }

        // Extract the locale from the dictionary file names
        for (const auto& dicFile : dicFiles) {
            regex.indexIn(dicFile);
            auto captured = regex.capturedTexts();

            if (captured.size() == 2) {
                auto nativeName = QLocale(captured[1]).nativeLanguageName();

                if (nativeName.isEmpty()) {
                    continue;
                }

                if (!nativeNames.contains(nativeName)) {
                    result[folder + QDir::separator() + captured[1]] = nativeName;
                    nativeNames.insert(nativeName);
                } else {
                    qWarning() << "Duplicate native name found, skipping:" << nativeName;
                }
            }
        }
    }
    cachedInstalledDictionaries_ = result;
}

void
SpellCheckDictionaryManager::refreshDictionaries()
{
    cachedInstalledDictionaries_.clear();
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
    QJsonDocument doc = QJsonDocument::fromJson(dictionaryListJson_.toUtf8());
    if (!doc.isNull() && doc.isObject()) {
        cachedAvailableDictionaries_ = doc.object();
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
    return getDictionariesPath() + getSpellLanguage();
}

bool
SpellCheckDictionaryManager::isDictionnaryInstalled(QString locale)
{
    return cachedInstalledDictionaries_.contains(locale);
}

bool
SpellCheckDictionaryManager::isDictionnaryAvailable(QString locale)
{
    return cachedAvailableDictionaries_.contains(locale);
}

QUrl
SpellCheckDictionaryManager::getDictionaryUrl()
{
    return dictionaryUrl_;
}

QString
SpellCheckDictionaryManager::getBestDictionary(QString locale)
{
    // Automatically set the spell language to the best available dictionary
    bool previouslyNone = false;
    if (locale == "NONE") {
        locale = getUILanguage();
        previouslyNone = true;
    }
    QString bestDictionary;
    // Check if the dictionnary is installed
    if (isDictionnaryInstalled(locale)) {
        bestDictionary = locale;
        if (previouslyNone) {
            settingsManager_->setValue(Settings::Key::SpellLang, bestDictionary);
        }
        Q_EMIT dictionaryAvailable();
        return bestDictionary;
    }
    // Check if the dictionary is available at the repository
    if (isDictionnaryAvailable(locale)) {
        bestDictionary = locale;
        if (previouslyNone) {
            settingsManager_->setValue(Settings::Key::SpellLang, bestDictionary);
        }
        downloadDictionary(locale);
        return bestDictionary;
    }
    // check if a local starting with the same 2 first letters is installed
    QStringList localeParts = locale.split("_");
    QString locale2letters = localeParts[0];
    QList key_iterator = cachedInstalledDictionaries_.keys();
    for (const auto& key : key_iterator) {
        if (key.startsWith(locale2letters)) {
            bestDictionary = key;
            if (previouslyNone) {
                settingsManager_->setValue(Settings::Key::SpellLang, bestDictionary);
            }
            Q_EMIT dictionaryAvailable();
            return bestDictionary;
        }
    }
    // check if a local starting with the same 2 first letters is available
    key_iterator = cachedAvailableDictionaries_.keys();
    for (const auto& key : key_iterator) {
        if (key.startsWith(locale2letters)) {
            bestDictionary = key;
            if (previouslyNone) {
                settingsManager_->setValue(Settings::Key::SpellLang, bestDictionary);
            }
            downloadDictionary(bestDictionary);
            return bestDictionary;
        }
    }
    if (bestDictionary.isEmpty()) {
        qWarning() << "No dictionary found for locale:" << locale;
        // Fallback to the default dictionary
        bestDictionary = "en_US";
        if (previouslyNone) {
            settingsManager_->setValue(Settings::Key::SpellLang, bestDictionary);
        }
        getBestDictionary(bestDictionary);
    }
    return bestDictionary;
}

void
SpellCheckDictionaryManager::updateDictionary(QString languagePath)
{
    getBestDictionary(languagePath);
}

// Used on Windows and MacOS
void
SpellCheckDictionaryManager::downloadDictionary(QString languagePath)
{
    if (getDictionaryUrl().isEmpty()) {
        qWarning() << "Dictionary " << languagePath
                   << " cannot be downloaded : No dictionary URL set";
        return;
    }

    // Get dictionary info from cached data
    QJsonValue dictValue = cachedAvailableDictionaries_[languagePath];
    if (dictValue.isUndefined() || !dictValue.isObject()) {
        qWarning() << "Dictionary info not found for" << languagePath;
        return;
    }

    QJsonObject dictInfo = dictValue.toObject();
    QString basePath = dictInfo["path"].toString();
    if (basePath.isEmpty()) {
        qWarning() << "Invalid path for dictionary" << languagePath;
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
        qWarning() << "Dictionary " << languagePath
                   << " cannot be downloaded : No dictionary path set";
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

        if (QFile::exists(affFilePath)) {
            Q_EMIT dictionaryAvailable();
        } else {
            qWarning() << "Missing .aff file for dictionary:" << localPath;
        }
    }
}

void
SpellCheckDictionaryManager::onDownloadFileFailed(const QString& localPath)
{
    qWarning() << "Download failed for file:" << localPath;
}
