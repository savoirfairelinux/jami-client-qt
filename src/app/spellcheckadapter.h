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

#include "spellchecker.h"
#include "qtutils.h"

#include <QObject>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class SpellCheckDictionaryListModel;

class SpellCheckAdapter final : public QObject
{
    Q_OBJECT
    QML_SINGLETON

    QML_RO_PROPERTY(QString, currentLocalePath)
    QML_RO_PROPERTY(int, installedDictionaryCount)

public:
    static SpellCheckAdapter* create(QQmlEngine* engine, QJSEngine*)
    {
        return new SpellCheckAdapter(qApp->property("SpellCheckDictionaryListModel")
                                         .value<SpellCheckDictionaryListModel*>(),
                                     engine);
    }

    explicit SpellCheckAdapter(SpellCheckDictionaryListModel* settingsManager,
                               QObject* parent = nullptr);
    ~SpellCheckAdapter() = default;

    Q_INVOKABLE QVariant getDictionaryListModel() const;
    Q_INVOKABLE QVariantMap getInstalledDictionaries() const;

    Q_INVOKABLE void installDictionary(const QString& locale);
    Q_INVOKABLE void uninstallDictionary(const QString& locale);

    Q_INVOKABLE QVariantList spellSuggestionsRequest(const QString& word);
    Q_INVOKABLE bool spell(const QString& word);
    Q_INVOKABLE QVariantList findWords(const QString& text);

public Q_SLOTS:
    Q_INVOKABLE void setDictionaryPath(const QString& path);

Q_SIGNALS:
    void dictionaryChanged();
    void downloadFailed(const QString& locale);

private:
    SpellChecker spellChecker_;
    SpellCheckDictionaryListModel* dictionaryListModel_ {nullptr};
};
