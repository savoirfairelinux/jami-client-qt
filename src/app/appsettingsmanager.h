/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
 * \file appsettingsmanager.h
 */

#pragma once

#include <QMetaEnum>
#include <QObject>
#include <QString>
#include <QStandardPaths>
#include <QWindow> // for QWindow::AutomaticVisibility
#include <QSettings>
#include <QDir>

#include <QTranslator>

extern const QString defaultDownloadPath;

// clang-format off

// Define USE_FRAMELESS_WINDOW_DEFAULT based on the platform
#ifdef Q_OS_LINUX
#define USE_FRAMELESS_WINDOW_DEFAULT false
#else
#define USE_FRAMELESS_WINDOW_DEFAULT true
#endif

// Common key-value pairs for both APPSTORE and non-APPSTORE builds
#define COMMON_KEYS \
    X(MinimizeOnClose, true) \
    X(DownloadPath, defaultDownloadPath) \
    X(ScreenshotPath, {}) \
    X(EnableNotifications, true) \
    X(EnableReadReceipt, true) \
    X(AcceptTransferBelow, 20) \
    X(AutoAcceptFiles, true) \
    X(DisplayHyperlinkPreviews, true) \
    X(AppTheme, "System") \
    X(BaseZoom, 1.0) \
    X(ParticipantsSide, false) \
    X(HideSelf, true) \
    X(HideSpectators, false) \
    X(AutoUpdate, true) \
    X(PluginAutoUpdate, false) \
    X(StartMinimized, false) \
    X(ShowChatviewHorizontally, true) \
    X(NeverShowMeAgain, false) \
    X(WindowGeometry, QRectF(qQNaN(), qQNaN(), 0., 0.)) \
    X(WindowState, QWindow::AutomaticVisibility) \
    X(EnableExperimentalSwarm, false) \
    X(LANG, "SYSTEM") \
    X(PluginStoreEndpoint, "https://plugins.jami.net") \
    X(PositionShareDuration, 15) \
    X(PositionShareLimit, true) \
    X(FlipSelf, true) \
    X(ShowMardownOption, false) \
    X(ChatViewEnterIsNewLine, false) \
    X(ShowSendOption, false) \
    X(EnablePtt, false) \
    X(PttKeys, 32) \
    X(UseFramelessWindow, USE_FRAMELESS_WINDOW_DEFAULT)
#if APPSTORE
#define KEYS COMMON_KEYS
#else
// Additional key-value pairs for non-APPSTORE builds including donation
// related settings.
#define KEYS COMMON_KEYS \
    X(Donation2023VisibleDate, "2023-11-27 05:00") \
    X(IsDonationVisible, true) \
    X(Donation2023EndDate2, "2024-04-01 00:00")
#endif

/*
 * A class to expose settings keys in both c++ and QML.
 * Note: this is using a non-constructable class instead of a
 * namespace allows for QML enum auto-completion in QtCreator.
 * This works well when there is only one enum class. Otherwise,
 * to prevent element name collision when defining multiple enums,
 * use a namespace with:
 *
 *  Q_NAMESPACE
 *  Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")
 */
class Settings : public QObject
{
    Q_OBJECT
public:
    enum class Key {
#define X(key, defaultValue) key,
    KEYS
#undef X
        COUNT__
    };
    Q_ENUM(Key)
    static QString toString(Key key)
    {
        return QMetaEnum::fromType<Key>().valueToKey(
                    static_cast<int>(key));
    }
    static QVariant defaultValue(const Key key)
    {
        switch (key) {
#define X(key, defaultValue) \
        case Key::key: return defaultValue;
    KEYS
#undef X
        default: return {};
        }
    }

private:
    Settings() = delete;
};
Q_DECLARE_METATYPE(Settings::Key)
// clang-format on

class AppSettingsManager : public QObject
{
    Q_OBJECT
public:
    explicit AppSettingsManager(QObject* parent = nullptr);
    ~AppSettingsManager() = default;

    Q_INVOKABLE QVariant getValue(const QString& key, const QVariant& defaultValue = {});
    Q_INVOKABLE void setValue(const QString& key, const QVariant& value = {});

    Q_INVOKABLE QVariant getValue(const Settings::Key key);
    Q_INVOKABLE void setValue(const Settings::Key key, const QVariant& value = {});

    Q_INVOKABLE QVariant getDefault(const Settings::Key key) const;

    QString getLanguage();
    const QString getDictionaryPath();

    void loadTranslations();
    void loadHistory();

Q_SIGNALS:
    void retranslate();
    void reloadHistory();

private:
    QSettings* settings_;
    QVector<QTranslator*> installedTr_ {};
};
