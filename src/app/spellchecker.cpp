/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
#include <QRegularExpression>
#include <QRegularExpressionMatchIterator>

SpellChecker::SpellChecker()
    : hunspell_(new Hunspell("", ""))
{}

bool
SpellChecker::spell(const QString& word)
{
    // Encode from Unicode to the encoding used by current dictionary
    return hunspell_->spell(word.toStdString()) != 0;
}

QStringList
SpellChecker::suggest(const QString& word)
{
    // Encode from Unicode to the encoding used by current dictionary
    std::vector<std::string> numSuggestions = hunspell_->suggest(word.toStdString());
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
    hunspell_->add(codec_->fromUnicode(word).constData());
}

bool
SpellChecker::replaceDictionary(const QString& dictionaryPath)
{
    if (dictionaryPath == currentDictionaryPath_) {
        return false;
    }

    QString dictFile = dictionaryPath + ".dic";
    QString affixFile = dictionaryPath + ".aff";
    QByteArray dictFilePath = dictFile.toLocal8Bit();
    QByteArray affixFilePath = affixFile.toLocal8Bit();
    hunspell_.reset(new Hunspell(affixFilePath.constData(), dictFilePath.constData()));
    // detect encoding analyzing the SET option in the affix file
    encoding_ = "ISO8859-1";
    QFile _affixFile(affixFile);
    if (_affixFile.open(QIODevice::ReadOnly)) {
        QTextStream stream(&_affixFile);
        QRegExp enc_detector("^\\s*SET\\s+([A-Z0-9\\-]+)\\s*", Qt::CaseInsensitive);
        for (QString line = stream.readLine(); !line.isEmpty(); line = stream.readLine()) {
            if (enc_detector.indexIn(line) > -1) {
                encoding_ = enc_detector.cap(1);
                break;
            }
        }
        _affixFile.close();
    }

    codec_ = QTextCodec::codecForName(this->encoding_.toLatin1().constData());

    currentDictionaryPath_ = dictionaryPath;
    return true;
}

QList<SpellChecker::WordInfo>
SpellChecker::findWords(const QString& text)
{
    // This is in the C++ part of the code because QML regex does not support unicode
    QList<WordInfo> results;
    QRegularExpression regex("\\p{L}+");
    QRegularExpressionMatchIterator iter = regex.globalMatch(text);

    while (iter.hasNext()) {
        QRegularExpressionMatch match = iter.next();
        WordInfo info;
        info.word = match.captured();
        info.position = match.capturedStart();
        info.length = match.capturedLength();
        results.append(info);
    }

    return results;
}
