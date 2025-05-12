#pragma once

#include <QObject>
#include <QMutex>
#include "spellcheckdictionarymanager.h"
#include "spellchecker.h"

class SpellCheckHandler : public QObject
{
    Q_OBJECT

public:
    SpellCheckHandler(SpellCheckDictionaryManager* spellCheckDictionaryManager, QObject* parent);

    Q_INVOKABLE QVariantList spellSuggestionsRequest(const QString& word);
    Q_INVOKABLE bool spell(const QString& word);
/*     Q_INVOKABLE void updateDictionary(const QString& path); */
    Q_INVOKABLE QVariantList findWords(const QString& text);

    Q_SLOT void onDictionaryAvailable();

private:
    SpellChecker spellChecker_;
    SpellCheckDictionaryManager* spellCheckDictionaryManager_;
    QMutex mutex_;
    QString dictPath_;
};
