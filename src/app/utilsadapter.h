/*
 * Copyright (C) 2015-2023 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Mingrui Zhang   <mingrui.zhang@savoirfairelinux.com>
 * Author: Aline Gondim Santos   <aline.gondimsantos@savoirfairelinux.com>
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

#include "qmladapterbase.h"
#include "appsettingsmanager.h"
#include "qtutils.h"

#include <api/member.h>

#include <QApplication>
#include <QObject>

#if __has_include(<gio/gio.h>)
#include <gio/gio.h>
#endif

#if defined(WIN32) && __has_include(<winrt/Windows.Foundation.h>)
#include <winrt/Windows.Foundation.h>

#define WATCHSYSTEMTHEME __has_include(<winrt/Windows.UI.ViewManagement.h>)

#if WATCHSYSTEMTHEME
#include <winrt/Windows.UI.ViewManagement.h>
#endif

using winrt::Windows::UI::ViewManagement::UISettings;
#endif

class QClipboard;
class SystemTray;

#define LOGSLIMIT 10000

#if defined(WIN32) && __has_include(<winrt/Windows.Foundation.h>)
/**
 * @brief Read if "AppsUseLightTheme" registry exists and its value
 *
 * @param getValue false to check if registry exists;
 *
 * @param getValue true if want the registry value.
 * @return if getValue is true, returns if the native theme is Dark (defaults to false).
 */
bool readAppsUseLightThemeRegistry(bool getValue);
#endif

class UtilsAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_PROPERTY(QStringList, logList)
    QML_RO_PROPERTY(bool, isRTL)
public:
    explicit UtilsAdapter(AppSettingsManager* settingsManager,
                          SystemTray* systemTray,
                          LRCInstance* instance,
                          QObject* parent = nullptr);
    ~UtilsAdapter() = default;

    Q_INVOKABLE QVariant getAppValue(const QString& key, const QVariant& defaultValue = {});
    Q_INVOKABLE void setAppValue(const QString& key, const QVariant& value);
    Q_INVOKABLE QVariant getAppValue(const Settings::Key key);
    Q_INVOKABLE void setAppValue(const Settings::Key key, const QVariant& value);
    Q_INVOKABLE QVariant getDefault(const Settings::Key key);
    Q_INVOKABLE void setToDefault(const Settings::Key key);

    Q_INVOKABLE const QString getProjectCredits();
    Q_INVOKABLE const QString getVersionStr();
    Q_INVOKABLE void setClipboardText(QString text);
    Q_INVOKABLE const QString qStringFromFile(const QString& filename);
    Q_INVOKABLE const QString getStyleSheet(const QString& name, const QString& source);
    Q_INVOKABLE const QString getLocalDataPath();
    Q_INVOKABLE const QString getCachePath();
    Q_INVOKABLE bool createStartupLink();
    Q_INVOKABLE QString GetRingtonePath();
    Q_INVOKABLE bool checkStartupLink();
    Q_INVOKABLE void setConversationFilter(const QString& filter);
    Q_INVOKABLE const QString getBestName(const QString& accountId, const QString& uid);
    Q_INVOKABLE QString getBestNameForUri(const QString& accountId, const QString& uri);
    Q_INVOKABLE QString getBestIdForUri(const QString& accountId, const QString& uri);
    Q_INVOKABLE QString getConvIdForUri(const QString& accountId, const QString& uri);
    Q_INVOKABLE const QString getPeerUri(const QString& accountId, const QString& uid);
    Q_INVOKABLE QString getBestId(const QString& accountId);
    Q_INVOKABLE const QString getBestId(const QString& accountId, const QString& uid);
    Q_INVOKABLE int getAccountListSize();
    Q_INVOKABLE bool hasCall(const QString& accountId);
    Q_INVOKABLE const QString getCallConvForAccount(const QString& accountId);
    Q_INVOKABLE const QString getCallId(const QString& accountId, const QString& convUid);
    Q_INVOKABLE int getCallStatus(const QString& callId);
    Q_INVOKABLE const QString getCallStatusStr(int statusInt);
    Q_INVOKABLE QString getStringUTF8(QString string);
    Q_INVOKABLE QString getRecordQualityString(int value);
    Q_INVOKABLE QString getCurrentPath();
    Q_INVOKABLE QString stringSimplifier(QString input);
    Q_INVOKABLE QString toNativeSeparators(QString inputDir);
    Q_INVOKABLE QString toFileInfoName(QString inputFileName);
    Q_INVOKABLE QString toFileAbsolutepath(QString inputFileName);
    Q_INVOKABLE QString getAbsPath(QString path);
    Q_INVOKABLE QString dirName(const QString& path);
    Q_INVOKABLE QString fileName(const QString& path);
    Q_INVOKABLE QString getExt(const QString& path);
    Q_INVOKABLE bool isImage(const QString& fileExt);
    Q_INVOKABLE QString humanFileSize(qint64 fileSize);
    Q_INVOKABLE void setSystemTrayIconVisible(bool visible);
    Q_INVOKABLE QString getDirDocument();
    Q_INVOKABLE QString getDirScreenshot();
    Q_INVOKABLE QString getDirDownload();
    Q_INVOKABLE void setRunOnStartUp(bool state);
    Q_INVOKABLE void setDownloadPath(QString dir);
    Q_INVOKABLE void setScreenshotPath(QString dir);
    Q_INVOKABLE void monitor(const bool& continuous);
    Q_INVOKABLE QVariantMap supportedLang();
    Q_INVOKABLE QString tempCreationImage(const QString& imageId = "temp") const;
    Q_INVOKABLE void setTempCreationImageFromString(const QString& image = "",
                                                    const QString& imageId = "temp");
    Q_INVOKABLE void setTempCreationImageFromFile(const QString& path,
                                                  const QString& imageId = "temp");
    Q_INVOKABLE void setTempCreationImageFromImage(const QImage& image,
                                                   const QString& imageId = "temp");

    // For Swarm details page
    Q_INVOKABLE bool getContactPresence(const QString& accountId, const QString& uri);
    Q_INVOKABLE QString getContactBestName(const QString& accountId, const QString& uri);
    Q_INVOKABLE lrc::api::member::Role getParticipantRole(const QString& accountId,
                                                          const QString& convId,
                                                          const QString& uri);
    Q_INVOKABLE bool luma(const QColor& color) const;
    Q_INVOKABLE bool useApplicationTheme();
    Q_INVOKABLE bool hasNativeDarkTheme() const;

    Q_INVOKABLE QString getOneline(const QString& input);

    Q_INVOKABLE QVariantMap getVideoPlayer(const QString& resource, const QString& bgColor);

    Q_INVOKABLE bool isRTL();
    Q_INVOKABLE bool isSystemTrayIconVisible();

    Q_INVOKABLE QString base64Encode(const QString& input);
    Q_INVOKABLE bool fileExists(const QString& filePath);
    Q_INVOKABLE QString getStandardTempLocation();
    Q_INVOKABLE QString getMimeNameForUrl(const QUrl& fileUrl) const;
    Q_INVOKABLE QUrl urlFromLocalPath(const QString& filePath) const;

#ifdef ENABLE_TESTS
    Q_INVOKABLE QString createDummyImage() const;
#endif
    Q_INVOKABLE bool isWayland() const;
Q_SIGNALS:
    void debugMessageReceived(const QString& message);
    void changeFontSize();
    void chatviewPositionChanged();
    void appThemeChanged();
    void showExperimentalCallSwarm();
    void changeLanguage();
    void donationCampaignSettingsChanged();

private:
    QClipboard* clipboard_;
    SystemTray* systemTray_;
    AppSettingsManager* settingsManager_;

    QMetaObject::Connection debugMessageReceivedConnection_;
    QString getDefaultRecordPath() const;

    bool isSystemThemeDark();
#if __has_include(<gio/gio.h>)
    GSettings* settings {nullptr};
    GSettingsSchema* schema {nullptr};
#endif

#if WATCHSYSTEMTHEME
    UISettings settings = NULL;
#endif
};
Q_DECLARE_METATYPE(UtilsAdapter*)
