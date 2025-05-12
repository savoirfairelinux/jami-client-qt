#pragma once

#include <QObject>
#include "spellcheckdictionarymanager.h"
#include "spellchecker.h"

class SpellCheckHandler : public QObject
{
    Q_OBJECT
    std::shared_ptr<SpellChecker> spellChecker_;
    SpellCheckDictionaryManager* spellCheckDictionaryManager_;

public:
    SpellCheckHandler(SpellCheckDictionaryManager* spellCheckDictionaryManager, QObject* parent);
    Q_INVOKABLE QVariantList spellSuggestionsRequest(const QString& word);
    Q_INVOKABLE bool spell(const QString& word);
    Q_INVOKABLE void updateDictionnary(const QString& path);
    Q_INVOKABLE QVariantList findWords(const QString& text);
};
