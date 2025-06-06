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
{
    for (int i = 0; i < static_cast<int>(Settings::Key::COUNT__); ++i) {
        auto key = static_cast<Settings::Key>(i);
        auto strKey= Settings::toString(key);
        // If the setting is written in the settings file and is equal to the default value,
        // remove it from the settings file.
        // This allow us to change default values without risking to remove user settings
        if ((settings_->contains(strKey)) && (settings_->value(strKey) == Settings::defaultValue(key)))
            settings_->remove(strKey);
    }
}

QVariant
AppSettingsManager::getValue(const QString& key, const QVariant& defaultValue)
{
    auto value = settings_->value(key, defaultValue);

    if (QString(value.typeName()) == "QString"
        && (value.toString() == "false" || value.toString() == "true"))
        return value.toBool();

    return value;
}

void
AppSettingsManager::setValue(const QString& key, const QVariant& value)
{
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

QString
AppSettingsManager::getLanguage()
{
    auto pref = getValue(Settings::Key::LANG).toString();
    return pref == "SYSTEM" ? QLocale::system().name() : pref;
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
