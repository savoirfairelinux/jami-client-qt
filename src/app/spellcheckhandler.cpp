#include "spellcheckhandler.h"

#include <QApplication>
#define SUGGESTIONS_MAX_SIZE 5 // limit the number of spelling suggestions
SpellCheckHandler::SpellCheckHandler(SpellCheckDictionaryManager* spellCheckDictionaryManager,
                                     QObject* parent)
    : spellCheckDictionaryManager_(spellCheckDictionaryManager)
{
    spellChecker_ = std::make_shared<SpellChecker>();
}
bool
SpellCheckHandler::spell(const QString& word)
{
    return spellChecker_->spell(word);
}
void
SpellCheckHandler::dictionariesListPopulated()
{
    connect(spellCheckDictionaryManager_,
            SIGNAL(void dictionnariesListPopulated()),
            this,
            SLOT(onDictionariesListPopulated()));
}

QVariantList
SpellCheckHandler::spellSuggestionsRequest(const QString& word)
{
    QStringList suggestionsList;
    QVariantList variantList;
    if (spellChecker_ == nullptr || spellChecker_->spell(word)) {
        return variantList;
    }

    suggestionsList = spellChecker_->suggest(word);
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
    if (!spellChecker_)
        return result;

    auto words = spellChecker_->findWords(text);
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
SpellCheckHandler::updateDictionnary(const QString& path)
{
    return spellChecker_->replaceDictionary(path);
}

void
SpellCheckHandler::onDictionariesListPopulated()
{
    qWarning() << "Dictionaries list populated";
    spellChecker_->replaceDictionary(spellCheckDictionaryManager_->getSpellLanguage());
}
