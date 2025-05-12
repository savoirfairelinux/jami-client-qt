#include "spellcheckhandler.h"

#include <QApplication>
#define SUGGESTIONS_MAX_SIZE 5 // limit the number of spelling suggestions
SpellCheckHandler::SpellCheckHandler(SpellCheckDictionaryManager* spellCheckDictionaryManager,
                                     QObject* parent)
    : spellCheckDictionaryManager_(spellCheckDictionaryManager)
{
    qWarning() << "SpellCheckHandler constructor" << spellChecker_.isLoaded();
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
/*
void
SpellCheckHandler::updateDictionary(const QString& path)
{
    qWarning() << "updateDictionary" << path;
    return spellChecker_.replaceDictionary(path);
} */

void
SpellCheckHandler::onDictionaryAvailable()
{
    dictPath_ = spellCheckDictionaryManager_->getDictionaryPath();
    qWarning() << "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!replaceDictionary" << dictPath_;
    spellChecker_.replaceDictionary(dictPath_);
}
