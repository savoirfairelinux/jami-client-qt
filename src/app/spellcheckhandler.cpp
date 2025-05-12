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

#include "spellcheckhandler.h"
#include "global.h"

#include <QApplication>
#define SUGGESTIONS_MAX_SIZE 10 // limit the number of spelling suggestions

SpellCheckHandler::SpellCheckHandler(SpellCheckDictionaryManager* spellCheckDictionaryManager,
                                     QObject* parent)
    : spellCheckDictionaryManager_(spellCheckDictionaryManager)
{
    connect(spellCheckDictionaryManager_,
            &SpellCheckDictionaryManager::dictionaryAvailable,
            this,
            &SpellCheckHandler::onDictionaryAvailable);
}

bool
SpellCheckHandler::spell(const QString& word)
{
    return spellChecker_.spell(word);
}

QVariantList
SpellCheckHandler::spellSuggestionsRequest(const QString& word)
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
SpellCheckHandler::findWords(const QString& text)
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
SpellCheckHandler::onDictionaryAvailable()
{
    dictPath_ = spellCheckDictionaryManager_->getDictionaryPath();
    C_DBG << "Dictionary set : " << dictPath_;
    spellChecker_.replaceDictionary(dictPath_);
    Q_EMIT dictionaryChanged();
}
