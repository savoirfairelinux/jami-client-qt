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
{}

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

QString
SpellCheckDictionaryManager::getDictionariesPath()
{
#if defined(Q_OS_LINUX)
    QString hunDir = "/usr/share/hunspell/";
    ;

#elif defined(Q_OS_MACOS)
    QString hunDir = "/Library/Spelling/";
#else
    QString hunDir = "";
#endif
    return hunDir;
}


void
SpellCheckDictionaryManager::refreshDictionaries()
{
    cachedInstalledDictionaries_.clear();
}

QString
SpellCheckDictionaryManager::getSpellLanguage()
{
    auto pref = settingsManager_->getValue(Settings::Key::SpellLang).toString();
    return pref ;
}

// Is only used at application boot time
QString
SpellCheckDictionaryManager::getDictionaryPath()
{
    return "/usr/share/hunspell/" + getSpellLanguage();
}
