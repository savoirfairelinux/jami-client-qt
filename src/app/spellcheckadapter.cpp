/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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

#include "spellcheckadapter.h"

#include "spellcheckdictionarylistmodel.h"

#include <QApplication>

#define SUGGESTIONS_MAX_SIZE 10 // limit the number of spelling suggestions

SpellCheckAdapter::SpellCheckAdapter(SpellCheckDictionaryListModel* dictionaryListModel,
                                     AppSettingsManager* settingsManager,
                                     QObject* parent)
    : QObject(parent)
    , dictionaryListModel_(dictionaryListModel)
    , settingsManager_(settingsManager)
{
    // Connect to update the selected dictionary if no dictionary is set on start
    connect(dictionaryListModel_,
            &SpellCheckDictionaryListModel::newDictionaryAvailable,
            this,
            &SpellCheckAdapter::setDictionary);

    // Load the current dictionary if available
    auto currentLocale = settingsManager_->getValue(Settings::Key::SpellLang).toString();
    if (!currentLocale.isEmpty()) {
        setDictionary(currentLocale);
    }

    // Listen for data changes to the dictionaryListModel_ to determine
    // our installedDictionaryCount
    connect(dictionaryListModel_,
            &QAbstractItemModel::dataChanged,
            this,
            [this](const QModelIndex&, const QModelIndex&, const QList<int>& roles) {
                if (roles.contains(SpellCheckDictionaryList::Installed)) {
                    set_installedDictionaryCount(dictionaryListModel_->getInstalledDictionaries().size());
                    localeCheckers_.clear();
                }
            });

    // Initialize the installedDictionaryCount
    set_installedDictionaryCount(dictionaryListModel_->getInstalledDictionaries().size());

    // Listen for download failure
    connect(dictionaryListModel_,
            &SpellCheckDictionaryListModel::downloadFailed,
            this,
            &SpellCheckAdapter::downloadFailed);
}

void
SpellCheckAdapter::installDictionary(const QString& locale)
{
    dictionaryListModel_->installDictionary(locale);
}

void
SpellCheckAdapter::uninstallDictionary(const QString& locale)
{
    dictionaryListModel_->uninstallDictionary(locale);
}

QVariant
SpellCheckAdapter::getDictionaryListModel() const
{
    return QVariant::fromValue(dictionaryListModel_);
}

QVariantMap
SpellCheckAdapter::getInstalledDictionaries() const
{
    return dictionaryListModel_->getInstalledDictionaries();
}

bool
SpellCheckAdapter::spell(const QString& word)
{
    return spellChecker_.spell(word);
}

QVariantList
SpellCheckAdapter::spellSuggestionsRequest(const QString& word)
{
    QStringList suggestionsList;
    QVariantList variantList;
    if (spellChecker_.spell(word)) {
        return variantList;
    }

    suggestionsList = spellChecker_.suggest(word);
    for (const auto& suggestion : suggestionsList) {
        if (variantList.size() >= SUGGESTIONS_MAX_SIZE) {
            break;
        }
        variantList.append(QVariant(suggestion));
    }
    return variantList;
}

SpellChecker*
SpellCheckAdapter::checkerFor(const QString& locale)
{
    if (auto it = localeCheckers_.find(locale); it != localeCheckers_.end())
        return it->second.get();
    const auto path = dictionaryListModel_->pathForLocale(locale);
    if (path.isEmpty())
        return nullptr;
    auto checker = std::make_unique<SpellChecker>();
    if (!checker->replaceDictionary(path))
        return nullptr;
    return localeCheckers_.emplace(locale, std::move(checker)).first->second.get();
}

bool
SpellCheckAdapter::spellIn(const QString& locale, const QString& word)
{
    const auto checker = checkerFor(locale);
    return !checker || checker->spell(word);
}

QVariantList
SpellCheckAdapter::spellSuggestionsIn(const QString& locale, const QString& word)
{
    QVariantList result;
    const auto checker = checkerFor(locale);
    if (!checker || checker->spell(word))
        return result;
    for (const auto& suggestion : checker->suggest(word)) {
        if (result.size() >= SUGGESTIONS_MAX_SIZE)
            break;
        result.append(suggestion);
    }
    return result;
}

QVariantList
SpellCheckAdapter::findWords(const QString& text)
{
    QVariantList result;
    auto words = spellChecker_.findWords(text);
    for (const auto& word : words) {
        QVariantMap wordInfo;
        wordInfo["word"] = word.word;
        wordInfo["position"] = word.position;
        wordInfo["length"] = word.length;
        result.append(wordInfo);
    }
    return result;
}

void
SpellCheckAdapter::setDictionary(const QString& locale)
{
    auto localPath = dictionaryListModel_->pathForLocale(locale);
    if (spellChecker_.replaceDictionary(localPath)) {
        settingsManager_->setValue(Settings::Key::SpellLang, locale);
        set_hasLoadedDictionary(true);
        Q_EMIT dictionaryChanged();
    } else {
        qWarning() << "Failed to set dictionary for locale:" << locale;
    }
}
