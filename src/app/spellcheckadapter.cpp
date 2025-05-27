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

#include "spellcheckadapter.h"

#include "global.h"
#include "spellcheckdictionarylistmodel.h"

#include <QApplication>

#define SUGGESTIONS_MAX_SIZE 10 // limit the number of spelling suggestions

SpellCheckAdapter::SpellCheckAdapter(SpellCheckDictionaryListModel* dictionaryListModel,
                                     QObject* parent)
    : QObject(parent)
    , dictionaryListModel_(dictionaryListModel)
{
    // Connect to update the selected dictionary if no dictionary is set on start
    connect(dictionaryListModel_,
            &SpellCheckDictionaryListModel::dictionaryAvailable,
            this,
            &SpellCheckAdapter::setDictionaryPath);

    // Load the current dictionary if available
    auto currentDictionaryPath = dictionaryListModel->currentDictionaryPath();
    if (!currentDictionaryPath.isEmpty()) {
        setDictionaryPath(currentDictionaryPath);
    }
}

void
SpellCheckAdapter::installDictionary(const QString& locale)
{
    dictionaryListModel_->installDictionary(locale);
}

void
SpellCheckAdapter::uninstallDictionary(const QString& locale)
{
    dictionaryListModel_->uninstallDictionary(locale);
}

bool
SpellCheckAdapter::spell(const QString& word)
{
    return spellChecker_.spell(word);
}

QVariantList
SpellCheckAdapter::spellSuggestionsRequest(const QString& word)
{
    QStringList suggestionsList;
    QVariantList variantList;
    if (spellChecker_.spell(word)) {
        return variantList;
    }

    suggestionsList = spellChecker_.suggest(word);
    for (const auto& suggestion : suggestionsList) {
        if (variantList.size() >= SUGGESTIONS_MAX_SIZE) {
            break;
        }
        variantList.append(QVariant(suggestion));
    }
    return variantList;
}

QVariantList
SpellCheckAdapter::findWords(const QString& text)
{
    QVariantList result;
    auto words = spellChecker_.findWords(text);
    for (const auto& word : words) {
        QVariantMap wordInfo;
        wordInfo["word"] = word.word;
        wordInfo["position"] = word.position;
        wordInfo["length"] = word.length;
        result.append(wordInfo);
    }
    return result;
}

void
SpellCheckAdapter::setDictionaryPath(const QString& localPath)
{
    C_INFO << "Setting dictionary path to:" << localPath;
    spellChecker_.replaceDictionary(localPath);
    Q_EMIT dictionaryChanged();
}
