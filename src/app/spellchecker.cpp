/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Jerome Lamy <jerome.lamy@savoirfairelinux.com>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * \file spellchecker.c
 */

#include "spellchecker.h"

#include <QString>
#include <QFile>
#include <QTextStream>
#include <QTextCodec>
#include <QStringList>
#include <QDebug>
#include <QRegExp>

SpellChecker::SpellChecker(const QString& dictionaryPath)
{
    replaceDictionary(dictionaryPath);
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

void
SpellChecker::replaceDictionary(const QString& dictionaryPath)
{
    QString dictFile = dictionaryPath + ".dic";
    QString affixFile = dictionaryPath + ".aff";
    QByteArray dictFilePathBA = dictFile.toLocal8Bit();
    QByteArray affixFilePathBA = affixFile.toLocal8Bit();
    if (_hunspell) {
        _hunspell.reset();
    }
    _hunspell = std::make_shared<Hunspell>(affixFilePathBA.constData(), dictFilePathBA.constData());

    // detect encoding analyzing the SET option in the affix file
    _encoding = "ISO8859-1";
    QFile _affixFile(affixFile);
    if (_affixFile.open(QIODevice::ReadOnly)) {
        QTextStream stream(&_affixFile);
        QRegExp enc_detector("^\\s*SET\\s+([A-Z0-9\\-]+)\\s*", Qt::CaseInsensitive);
        for (QString line = stream.readLine(); !line.isEmpty(); line = stream.readLine()) {
            if (enc_detector.indexIn(line) > -1) {
                _encoding = enc_detector.cap(1);
                break;
            }
        }
        _affixFile.close();
    }

    _codec = QTextCodec::codecForName(this->_encoding.toLatin1().constData());
}
