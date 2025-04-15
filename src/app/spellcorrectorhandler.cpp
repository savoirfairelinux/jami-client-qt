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

#include "spellcorrectorhandler.h"
#include <QApplication>
#include <QBuffer>
#include <QClipboard>
#include <QFileInfo>
#include <QRegExp>
#include <QMimeData>
#include <QDir>
#include <QMimeDatabase>

SpellCorrectorHandler::SpellCorrectorHandler(QObject* parent)
    : QObject {parent}
{}

QVariantMap
SpellCorrectorHandler::installedDictionaries()
{
    QString hunspellDataDir = getDictionariesPath();
    qWarning() << "Hunspell data directory:" << hunspellDataDir;

    auto dictionariesDir = QDir(hunspellDataDir);
    QRegExp regex("(.*).dic");
    QSet<QString> nativeNames;
    QStringList trFiles = dictionariesDir.entryList(QStringList() << "jami_client_qt_*.qm", QDir::Files);
    qWarning() << "Translation files found:" << trFiles;

    QVariantMap result;
    QStringList folders = dictionariesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    qWarning() << "Folders found in dictionaries directory:" << folders;

    for (const auto& folder : folders) {
        QDir subDir = dictionariesDir.absoluteFilePath(folder);
        qWarning() << "Processing folder:" << folder;

        QStringList dicFiles = subDir.entryList(QStringList() << "*.dic", QDir::Files);
        qWarning() << "Dictionary files found in folder" << folder << ":" << dicFiles;

        for (const auto& dicFile : dicFiles) {
            regex.indexIn(dicFile);
            auto captured = regex.capturedTexts();
            qWarning() << "Captured texts for file" << dicFile << ":" << captured;

            if (captured.size() == 2) {
                auto nativeName = QLocale(captured[1]).nativeLanguageName();
                qWarning() << "Native language name for locale" << captured[1] << ":" << nativeName;

                if (nativeName.isEmpty()) {
                    qWarning() << "Locale" << captured[1] << "has no native language name, skipping.";
                    continue;
                }

                if (!nativeNames.contains(nativeName)) {
                    result[captured[1]] = nativeName;
                    nativeNames.insert(nativeName);
                    qWarning() << "Added dictionary:" << captured[1] << "with native name:" << nativeName;
                } else {
                    qWarning() << "Duplicate native name found, skipping:" << nativeName;
                }
            }
        }
    }

    qWarning() << "Final installed dictionaries:" << result;
    return result;
}

/*QString
SpellCorrectorHandler::getLanguage()
{
    auto pref = AppSettingsManager::getValue(Settings::Key::LANG).toString();
    return pref == "SYSTEM" ? QLocale::system().name() : pref;
}
*/
const QString
SpellCorrectorHandler::getDictionariesPath()
{
#if defined(HUNSPELL_INSTALL_DIR)
    QString hunspellDataDir = "/home/pmagnier-slimani/.cache/Jami/dictionaries";
    //QString hunspellDataDir = HUNSPELL_INSTALL_DIR;
#else
    QString hunspellDataDir = "/home/pmagnier-slimani/.cache/Jami/dictionaries";
    //QString hunspellDataDir = qApp->applicationDirPath() + QDir::separator() + "share";
#endif
    return hunspellDataDir;
}

