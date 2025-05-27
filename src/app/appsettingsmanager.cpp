/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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
 * \file appsettingsmanager.cpp
 */

#include "appsettingsmanager.h"

#include "global.h"

#include <QCoreApplication>
#include <QLibraryInfo>
#include <QDir>

const QString defaultDownloadPath = QStandardPaths::writableLocation(
    QStandardPaths::DownloadLocation);

AppSettingsManager::AppSettingsManager(QObject* parent)
    : QObject(parent)
    , settings_(new QSettings("jami.net", "Jami", this))
    , settingsMap_(this)
{
    for (int i = 0; i < static_cast<int>(Settings::Key::COUNT__); ++i) {
        auto key = static_cast<Settings::Key>(i);
        auto strKey = Settings::toString(key);

        // Populate QPropertyMap with stored settings values
        auto settingsValue = settings_->value(strKey, Settings::defaultValue(key));
        if (QString(settingsValue.typeName()) == "QString"
            && (settingsValue.toString() == "false" || settingsValue.toString() == "true"))
            settingsValue = settingsValue.toBool();
        settingsMap_.insert(strKey, settingsValue);
        C_INFO << "Setting" << strKey << " initialized with value:" << settingsValue;

        // If the setting is written in the settings file and is equal to the default value,
        // remove it from the settings file.
        // This allow us to change default values without risking to remove user settings
        if ((settings_->contains(strKey))
            && (settings_->value(strKey) == Settings::defaultValue(key)))
            settings_->remove(strKey);
    }
    // Connect changes to QQmlPropertyMap to QSettings
    // Additionnal logic related to specific settings done here
    connect(&settingsMap_,
            &QQmlPropertyMap::valueChanged,
            this,
            [this](const QString& key, const QVariant& value) {
                C_INFO << " ======== saved settings" << key << "changed to" << value;
                if (key == Settings::toString(Settings::Key::BaseZoom)) {
                    if (value.toDouble() < 0.1 || value.toDouble() > 2.0) {
                        setValue(key,
                                 settings_->value(key,
                                                  Settings::defaultValue(Settings::Key::BaseZoom)));
                        return;
                    }
                }
                settings_->setValue(key, value);
                if (key == Settings::toString(Settings::Key::LANG)) {
                    loadTranslations();
                    set_isRTL(isRTL());
                } else if (key == Settings::toString(Settings::Key::DisplayHyperlinkPreviews))
                    loadHistory();
            });
    set_isRTL(isRTL());
}

QVariant
AppSettingsManager::getValue(const QString& key, const QVariant& defaultValue)
{
    return settingsMap_.value(key);
}

void
AppSettingsManager::setValue(const QString& key, const QVariant& value)
{
    settingsMap_.insert(key, value);
    // As the valueChanged signal is NOT emmited when modifying
    // a QmlPropertyMap from C++, we need to update the QSettings manually
    settings_->setValue(key, value);
}

QVariant
AppSettingsManager::getValue(const Settings::Key key)
{
    return getValue(Settings::toString(key), Settings::defaultValue(key));
}

void
AppSettingsManager::setValue(const Settings::Key key, const QVariant& value)
{
    setValue(Settings::toString(key), value);
}

QVariant
AppSettingsManager::getDefault(const Settings::Key key) const
{
    return Settings::defaultValue(key);
}

void
AppSettingsManager::setToDefault(const Settings::Key key)
{
    setValue(Settings::toString(key), getDefault(key));
}

QString
AppSettingsManager::getLanguage()
{
    auto pref = getValue(Settings::Key::LANG).toString();
    return pref == "SYSTEM" ? QLocale::system().name() : pref;
}

bool
AppSettingsManager::isRTL()
{
    auto pref = getValue(Settings::Key::LANG);
    pref = pref == "SYSTEM" ? QLocale::system().name() : pref;
    static const QStringList rtlLanguages {
        // as defined by ISO 639-1
        "ar",    // Arabic
        "he",    // Hebrew
        "fa",    // Persian (Farsi)
        "az_IR", // Azerbaijani
        "ur",    // Urdu
        "ps",    // Pashto
        "ku",    // Kurdish
        "sd",    // Sindhi
        "dv",    // Dhivehi (Maldivian)
        "yi",    // Yiddish
        "am",    // Amharic
        "ti",    // Tigrinya
        "kk"     // Kazakh (in Arabic script)
    };
    return rtlLanguages.contains(pref);
}

void
AppSettingsManager::loadTranslations()
{
#if defined(Q_OS_LINUX) && defined(JAMI_INSTALL_PREFIX)
    QString appDir = JAMI_INSTALL_PREFIX;
#elif defined(Q_OS_MACOS)
    QDir dir(qApp->applicationDirPath());
    dir.cdUp();
    QString appDir = dir.absolutePath() + "/Resources/share";
#else
    QString appDir = qApp->applicationDirPath() + QDir::separator() + "share";
#endif

    // Remove previously installed translators
    for (auto* tr : installedTr_)
        qApp->removeTranslator(tr);
    installedTr_.clear();

    QString locale_name = getLanguage();
    C_INFO << QString("Using locale: %1").arg(locale_name);
    QString locale_lang = locale_name.split('_')[0];

    QTranslator* qtTranslator_lang = new QTranslator(qApp);
    QTranslator* qtTranslator_name = new QTranslator(qApp);
    if (locale_name != locale_lang) {
        if (qtTranslator_lang->load("qt_" + locale_lang,
                                    QLibraryInfo::path(QLibraryInfo::TranslationsPath)))
            qApp->installTranslator(qtTranslator_lang);
        installedTr_.append(qtTranslator_lang);
    }

    if (qtTranslator_name->load("qt_" + locale_name,
                                QLibraryInfo::path(QLibraryInfo::TranslationsPath))) {
        qApp->installTranslator(qtTranslator_name);
        installedTr_.append(qtTranslator_name);
    }

    QTranslator* mainTranslator_lang = new QTranslator(qApp);
    QTranslator* mainTranslator_name = new QTranslator(qApp);
    if (locale_name != locale_lang) {
        if (mainTranslator_lang->load(appDir + QDir::separator() + "jami" + QDir::separator()
                                      + "translations" + QDir::separator() + "jami_client_qt_"
                                      + locale_lang)) {
            qApp->installTranslator(mainTranslator_lang);
            installedTr_.append(mainTranslator_lang);
        }
    }
    if (mainTranslator_name->load(appDir + QDir::separator() + "jami" + QDir::separator()
                                  + "translations" + QDir::separator() + "jami_client_qt_"
                                  + locale_name)) {
        qApp->installTranslator(mainTranslator_name);
        installedTr_.append(mainTranslator_name);
    }

    Q_EMIT retranslate();
    loadHistory();
}

void
AppSettingsManager::loadHistory()
{
    Q_EMIT reloadHistory();
}
