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

#include "spellcheckdictionarymanager.h"
#include <tidy.h>
#include <tidybuffio.h>

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
{}

QVariantMap
SpellCheckDictionaryManager::installedDictionaries()
{
    // If we already have a cache of the installed dictionaries, return it
    if (cachedinstalledDictionaries.size() > 0) {
        return cachedinstalledDictionaries;

    // If not, we need to check the dictionaries directory
    } else {
        QString hunspellDataDir = getDictionariesPath();
        // qWarning() << "Hunspell data directory:" << hunspellDataDir;

        auto dictionariesDir = QDir(hunspellDataDir);
        QRegExp regex("(.*).dic");
        QSet<QString> nativeNames;

        QVariantMap result;
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

        // qWarning() << "Folders found in dictionaries directory:" << folders;
        // Check for dictionary files in subdirectories
        for (const auto& folder : folders) {
            QDir subDir = dictionariesDir.absoluteFilePath(folder);
            // qWarning() << "Processing folder:" << folder;
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
            // qWarning() << "Dictionary files found in folder" << folder << ":" << dicFiles;

            // Extract the locale from the dictionary file names
            for (const auto& dicFile : dicFiles) {
                regex.indexIn(dicFile);
                auto captured = regex.capturedTexts();
                // qWarning() << "Captured texts for file" << dicFile << ":" << captured;

                if (captured.size() == 2) {
                    auto nativeName = QLocale(captured[1]).nativeLanguageName();
                    // qWarning() << "Native language name for locale" << captured[1] << ":" << nativeName;

                    if (nativeName.isEmpty()) {
                        // qWarning() << "Locale" << captured[1]
                        //<< "has no native language name, skipping.";
                        continue;
                    }

                    if (!nativeNames.contains(nativeName)) {
                        result[folder + QDir::separator() + captured[1]] = nativeName;
                        nativeNames.insert(nativeName);
                        // qWarning() << "Added dictionary:" << captured[1]
                        //<< "with native name:" << nativeName;
                    } else {
                        // qWarning() << "Duplicate native name found, skipping:" << nativeName;
                    }
                }
            }
        }

        // qWarning() << "Final installed dictionaries:" << result;
        cachedinstalledDictionaries = result;
        return result;
    }
}

/* QString
SpellCheckDictionaryManager::getLanguage()
{
    auto pref = AppSettingsManager::getValue(Settings::Key::LANG).toString();
    return pref == "SYSTEM" ? QLocale::system().name() : pref;
} */

const QString
SpellCheckDictionaryManager::getDictionariesPath()
{
/* return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QDir::separator()
       + "dictionaries" + QDir::separator(); */
#if defined(Q_OS_LINUX)
    QString hunDir = "/usr/share/hunspell/";
    ;

#elif defined(Q_OS_MACOS)
    QString hunDir = "/Library/Spelling/";
#else
    qWarning() << "! getDictionaryPath error : Hunspell shouldn't be activated on Windows yet";
    QString hunDir = "";
#endif
    // qWarning() << "Hunspell data directory:" << hunDir;
    return hunDir;
}

const QString
SpellCheckDictionaryManager::getDictionaryUrl()
{
    return dictionaryUrl;
}

void
SpellCheckDictionaryManager::refreshDictionaries()
{
    cachedinstalledDictionaries.clear();
}

QString
SpellCheckDictionaryManager::getSpellLanguage()
{
    auto pref = settingsManager_->getValue(Settings::Key::SpellLang).toString();
    qWarning("SpellLang: %s", qPrintable(pref));
    return pref == "none" ? "en_GB/en" : pref;
}

// Is only used at application boot time
const QString
SpellCheckDictionaryManager::getDictionaryPath()
{
    return "/usr/share/hunspell/" + getSpellLanguage();
}
