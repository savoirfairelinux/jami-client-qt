#include "spellchecker.h"

#include <QString>
#include <QFile>
#include <QTextStream>
#include <QTextCodec>
#include <QStringList>
#include <QDebug>
#include <QRegExp>

#include "hunspell/hunspell.hxx"

SpellChecker::SpellChecker(const QString& dictionaryPath)
{
    QString dictFile = dictionaryPath + ".dic";
    QString affixFile = dictionaryPath + ".aff";
    QByteArray dictFilePathBA = dictFile.toLocal8Bit();
    QByteArray affixFilePathBA = affixFile.toLocal8Bit();
    _hunspell = new Hunspell(affixFilePathBA.constData(), dictFilePathBA.constData());

    // detect encoding analyzing the SET option in the affix file
    _encoding = "ISO8859-1";
    QFile _affixFile(affixFile);
    if (_affixFile.open(QIODevice::ReadOnly)) {
        QTextStream stream(&_affixFile);
        QRegExp enc_detector("^\\s*SET\\s+([A-Z0-9\\-]+)\\s*", Qt::CaseInsensitive);
        for (QString line = stream.readLine(); !line.isEmpty(); line = stream.readLine()) {
            if (enc_detector.indexIn(line) > -1) {
                _encoding = enc_detector.cap(1);
                qDebug() << QString("Encoding set to ") + _encoding;
                break;
            }
        }
        _affixFile.close();
    }
    _codec = QTextCodec::codecForName(this->_encoding.toLatin1().constData());
}

bool
SpellChecker::spell(const QString& word)
{
    // Encode from Unicode to the encoding used by current dictionary
    return _hunspell->spell(word.toStdString()) != 0;
}

QStringList
SpellChecker::suggest(const QString& word)
{
    // Encode from Unicode to the encoding used by current dictionary
    std::vector<std::string> numSuggestions = _hunspell->suggest(word.toStdString());
    QStringList suggestions;

    for (size_t i = 0; i < numSuggestions.size(); ++i) {
        suggestions << QString::fromStdString(numSuggestions.at(i));
    }

    return suggestions;
}

void
SpellChecker::ignoreWord(const QString& word)
{
    put_word(word);
}

void
SpellChecker::put_word(const QString& word)
{
    _hunspell->add(_codec->fromUnicode(word).constData());
}
