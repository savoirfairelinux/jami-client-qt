#pragma once

#include "lrcinstance.h"
#include "qmladapterbase.h"
#include "previewengine.h"

#include <QTextCodec>
#include <QString>
#include <QStringList>
#include <QDebug>
#include <QObject>
#include <string>

using namespace std;

class Hunspell;

class SpellChecker : public QObject
{
    Q_OBJECT
public:
    explicit SpellChecker(const QString&);
    ~SpellChecker() = default;

    Q_INVOKABLE bool spell(const QString& word);
    Q_INVOKABLE QStringList suggest(const QString& word);
    Q_INVOKABLE void ignoreWord(const QString& word);

private:
    void put_word(const QString& word);
    Hunspell* _hunspell;
    QString _encoding;
    QTextCodec* _codec;
};
