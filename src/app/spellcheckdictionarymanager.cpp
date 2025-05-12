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
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QEventLoop>
#include <QRegularExpression>

SpellCheckDictionaryManager::SpellCheckDictionaryManager(AppSettingsManager* settingsManager,
                                                         QObject* parent)
    : QObject {parent}
    , settingsManager_ {settingsManager}
{
    installedDictionaries();
    availableDictionaries();
}

QVariantMap
SpellCheckDictionaryManager::installedDictionaries()
{
    // If we already have a cache of the installed dictionaries, return it
    if (cachedInstalledDictionaries_.size() > 0) {
        return cachedInstalledDictionaries_;

        // If not, we need to check the dictionaries directory
    } else {
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
        return result;
    }
}

void
SpellCheckDictionaryManager::refreshDictionaries()
{
    cachedInstalledDictionaries_.clear();
    cachedAvailableDictionaries_.clear();
}

QString
SpellCheckDictionaryManager::getSpellLanguage()
{
    auto pref = settingsManager_->getValue(Settings::Key::SpellLang).toString();
    qWarning() << "Spell language:" << pref;
    return pref;
}

QVariantMap
SpellCheckDictionaryManager::availableDictionaries()
{
    if (cachedAvailableDictionaries_.size() > 0) {
        qWarning() << "Returning cached available dictionaries";
        return cachedAvailableDictionaries_;
    } else {
        auto dictionariesURL = getDictionaryUrl();
        qWarning() << "Fetching available dictionaries from URL:" << dictionariesURL;
        QNetworkRequest request(dictionariesURL);
        QNetworkReply* reply = networkRequestManager_.get(request);
        QObject::connect(reply, &QNetworkReply::finished, [=]() {
            if (reply->error() == QNetworkReply::NoError) {
                QString webPageContent = QString::fromUtf8(reply->readAll());
                //qWarning() << "Page content:" << webPageContent;
                QVariantMap result;
                QRegularExpression regexWithCountry("'>\\s*([a-z]{2,3}_[A-Z]{2})\\s*</a></li>");
                QRegularExpression regexSimple("'>\\s*([a-z]{2,3})(?![A-Z_])\\s*</a></li>");
                QSet<QString> foundDictionaries;

                // Find all matches with a country code
                auto matchIterator = regexWithCountry.globalMatch(webPageContent);
                while (matchIterator.hasNext()) {
                    QRegularExpressionMatch match = matchIterator.next();
                    QString locale = match.captured(1);
                    if (!foundDictionaries.contains(locale)) {
                        qWarning() << "Match found with country code:" << locale;
                        auto nativeName = QLocale(locale).nativeLanguageName();
                        if (!nativeName.isEmpty()) {
                            result[locale] = nativeName;
                            foundDictionaries.insert(locale);
                        }
                        qWarning() << "Found dictionary with country:" << locale
                                   << "Native name:" << nativeName;
                    }
                }

                // Find all simple matches
                matchIterator = regexSimple.globalMatch(webPageContent);
                while (matchIterator.hasNext()) {
                    QRegularExpressionMatch match = matchIterator.next();
                    QString locale = match.captured(1);
                    if (!foundDictionaries.contains(locale)) {
                        auto nativeName = QLocale(locale).nativeLanguageName();
                        if (!nativeName.isEmpty()) {
                            result[locale] = nativeName;
                            foundDictionaries.insert(locale);
                        }
                        qWarning()
                            << "Found simple dictionary:" << locale << "Native name:" << nativeName;
                    }
                }

                cachedAvailableDictionaries_ = result;
            } else {
                qWarning() << "Error:" << reply->errorString();
            }
            reply->deleteLater();
        });
    }
    return QVariantMap {};
}

QString
SpellCheckDictionaryManager::getDictionariesPath()
{
#if defined(Q_OS_LINUX)
    QString hunDir = "/usr/share/hunspell/";
#else
    QString hunDir QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/dictionaries/";
#endif
    return hunDir;
}

// Is only used at application boot time
QString
SpellCheckDictionaryManager::getDictionaryPath()
{
    return getDictionariesPath() + getSpellLanguage();
}

bool SpellCheckDictionaryManager::isDictionnaryInstalled(QString locale)
{
    installedDictionaries();
    return cachedInstalledDictionaries_.contains(locale);
}

bool SpellCheckDictionaryManager::isDictionnaryAvailable(QString locale)
{
    availableDictionaries();
    return cachedAvailableDictionaries_.contains(locale);
}

QUrl
SpellCheckDictionaryManager::getDictionaryUrl()
{
    return dictionaryUrl_;
}

QString
SpellCheckDictionaryManager::getBestDictionary(QString locale){
    installedDictionaries();
    availableDictionaries();
    QString bestDictionary;
    if (isDictionnaryInstalled(locale)) {
        bestDictionary = locale;
        return bestDictionary;
    }
    // check if a local starting with the same 2 first letters is installed
    QStringList localeParts = locale.split("_");
    QString locale2letters = localeParts[0];
    QList key_iterator = cachedInstalledDictionaries_.keys();
    for (const auto& key : key_iterator) {
        if (key.startsWith(locale2letters)) {
            bestDictionary = key;
            return bestDictionary;
        }
    }
    if (isDictionnaryAvailable(locale)) {
        bestDictionary = locale;
        return bestDictionary;
    }
    // check if a local starting with the same 2 first letters is available
    key_iterator = cachedAvailableDictionaries_.keys();
    for (const auto& key : key_iterator) {
        if (key.startsWith(locale2letters)) {
            bestDictionary = key;
            Q_EMIT requestDictionaryDownload(bestDictionary);
            return bestDictionary;
        }
    }
    if (bestDictionary.isEmpty()) {
        qWarning() << "No dictionary found for locale:" << locale;
        // Fallback to the default dictionary
        bestDictionary = "en_US";
        getBestDictionary(bestDictionary);
    }
    return bestDictionary;
}
