/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include <QCoreApplication>
#include <QLibraryInfo>

#include <locale.h>

const QString defaultDownloadPath = QStandardPaths::writableLocation(
    QStandardPaths::DownloadLocation);

AppSettingsManager::AppSettingsManager(QObject* parent)
    : QObject(parent)
    , settings_(new QSettings("jami.net", "Jami", this))
{
    for (int i = 0; i < static_cast<int>(Settings::Key::COUNT__); ++i) {
        auto key = static_cast<Settings::Key>(i);
        if (!settings_->contains(Settings::toString(key)))
            setValue(key, Settings::defaultValue(key));
    }
}

QVariant
AppSettingsManager::getValue(const Settings::Key key)
{
    auto value = settings_->value(Settings::toString(key), Settings::defaultValue(key));

    if (QString(value.typeName()) == "QString"
        && (value.toString() == "false" || value.toString() == "true"))
        return value.toBool();

    return value;
}

void
AppSettingsManager::setValue(const Settings::Key key, const QVariant& value)
{
    settings_->setValue(Settings::toString(key), value);
}

void
AppSettingsManager::loadTranslations()
{
#if defined(Q_OS_LINUX) && defined(JAMI_INSTALL_PREFIX)
    QString appDir = JAMI_INSTALL_PREFIX;
#else
    QString appDir = qApp->applicationDirPath() + QDir::separator() + "share";
#endif

    // Remove previously installed translators
    for (auto* tr : installedTr_)
        qApp->removeTranslator(tr);
    installedTr_.clear();

    auto pref = getValue(Settings::Key::LANG).toString();

    QString locale_name = pref == "SYSTEM" ? QLocale::system().name() : pref;
    qDebug() << QString("Using locale: %1").arg(locale_name);
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

    QTranslator* lrcTranslator_lang = new QTranslator(qApp);
    QTranslator* lrcTranslator_name = new QTranslator(qApp);
    if (locale_name != locale_lang) {
        if (lrcTranslator_lang->load(appDir + QDir::separator() + "libringclient" + QDir::separator()
                                     + "translations" + QDir::separator() + "lrc_" + locale_lang)) {
            qApp->installTranslator(lrcTranslator_lang);
            installedTr_.append(lrcTranslator_lang);
        }
    }
    if (lrcTranslator_name->load(appDir + QDir::separator() + "libringclient" + QDir::separator()
                                 + "translations" + QDir::separator() + "lrc_" + locale_name)) {
        qApp->installTranslator(lrcTranslator_name);
        installedTr_.append(lrcTranslator_name);
    }

    QTranslator* mainTranslator_lang = new QTranslator(qApp);
    QTranslator* mainTranslator_name = new QTranslator(qApp);
    if (locale_name != locale_lang) {
        if (mainTranslator_lang->load(appDir + QDir::separator() + "ring" + QDir::separator()
                                      + "translations" + QDir::separator() + "ring_client_windows_"
                                      + locale_lang)) {
            qApp->installTranslator(mainTranslator_lang);
            installedTr_.append(mainTranslator_lang);
        }
    }
    if (mainTranslator_name->load(appDir + QDir::separator() + "ring" + QDir::separator()
                                  + "translations" + QDir::separator() + "ring_client_windows_"
                                  + locale_name)) {
        qApp->installTranslator(mainTranslator_name);
        installedTr_.append(mainTranslator_name);
    }

    Q_EMIT retranslate();
}