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
 * \file spellchecker.h
 */

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

#include <hunspell/hunspell.hxx>

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
    std::shared_ptr<Hunspell> _hunspell;
    QString _encoding;
    QTextCodec* _codec;
};