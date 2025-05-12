/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
    Q_INVOKABLE QVariantList findWords(const QString& text);

    Q_SLOT void onDictionaryAvailable();

private:
    SpellChecker spellChecker_;
    SpellCheckDictionaryManager* spellCheckDictionaryManager_;
    QMutex mutex_;
    QString dictPath_;
};
