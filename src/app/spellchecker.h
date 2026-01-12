/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
 * \file spellchecker.h
 */

#pragma once

#include <QTextCodec>
#include <QString>
#include <QStringList>
#include <QDebug>
#include <QObject>

#include <hunspell/hunspell.hxx>

class Hunspell;

class SpellChecker : public QObject
{
    Q_OBJECT
public:
    explicit SpellChecker();

    bool replaceDictionary(const QString& dictionaryPath);

    Q_INVOKABLE bool spell(const QString& word);
    Q_INVOKABLE QStringList suggest(const QString& word);
    Q_INVOKABLE void ignoreWord(const QString& word);

    // Used to find words and their position in a text
    struct WordInfo
    {
        QString word;
        int position;
        int length;
    };

    Q_INVOKABLE QList<WordInfo> findWords(const QString& text);

private:
    void put_word(const QString& word);

    std::unique_ptr<Hunspell> hunspell_;

    QString currentDictionaryPath_;
    QTextCodec* codec_;
};
