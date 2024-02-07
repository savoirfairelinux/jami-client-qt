/*!
 * Copyright (C) 2015-2024 Savoir-faire Linux Inc.
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

#include "utilsadapter.h"

#include "lrcinstance.h"
#include "systemtray.h"
#include "utils.h"
#include "version.h"

#include "api/pluginmodel.h"
#include "api/datatransfermodel.h"

#include <QApplication>
#include <QBuffer>
#include <QClipboard>
#include <QFileInfo>
#include <QRegExp>
#include <QMimeData>
#include <QMimeDatabase>

UtilsAdapter::UtilsAdapter(AppSettingsManager* settingsManager,
                           SystemTray* systemTray,
                           LRCInstance* instance,
                           QObject* parent)
    : QmlAdapterBase(instance, parent)
    , clipboard_(QApplication::clipboard())
    , systemTray_(systemTray)
    , settingsManager_(settingsManager)
{
    if (lrcInstance_->avModel().getRecordPath().isEmpty()) {
        lrcInstance_->avModel().setRecordPath(getDefaultRecordPath());
    }
    set_isRTL(isRTL());
}

QVariant
UtilsAdapter::getAppValue(const QString& key, const QVariant& defaultValue)
{
    return settingsManager_->getValue(key, defaultValue);
}

void
UtilsAdapter::setAppValue(const QString& key, const QVariant& value)
{
    settingsManager_->setValue(key, value);
}

QVariant
UtilsAdapter::getAppValue(const Settings::Key key)
{
    return settingsManager_->getValue(key);
}

void
UtilsAdapter::setAppValue(const Settings::Key key, const QVariant& value)
{
    if (key == Settings::Key::BaseZoom) {
        if (value.toDouble() < 0.1 || value.toDouble() > 2.0)
            return;
    }
    settingsManager_->setValue(key, value);
    // If we change the lang preference, reload the translations
    if (key == Settings::Key::LANG) {
        settingsManager_->loadTranslations();
        set_isRTL(isRTL());
        Q_EMIT changeLanguage();
    } else if (key == Settings::Key::BaseZoom)
        Q_EMIT changeFontSize();
    else if (key == Settings::Key::DisplayHyperlinkPreviews)
        settingsManager_->loadHistory();
    else if (key == Settings::Key::EnableExperimentalSwarm)
        Q_EMIT showExperimentalCallSwarm();
    else if (key == Settings::Key::ShowChatviewHorizontally)
        Q_EMIT chatviewPositionChanged();
    else if (key == Settings::Key::AppTheme)
        Q_EMIT appThemeChanged();
    else if (key == Settings::Key::UseFramelessWindow)
        Q_EMIT useFramelessWindowChanged();
#if !APPSTORE
    // Any donation campaign-related keys can trigger a donation campaign check
    else if (key == Settings::Key::IsDonationVisible
             || key == Settings::Key::Donation2023VisibleDate
             || key == Settings::Key::Donation2023EndDate2)
        Q_EMIT donationCampaignSettingsChanged();
#endif
}

QVariant
UtilsAdapter::getDefault(const Settings::Key key)
{
    return settingsManager_->getDefault(key);
}

void
UtilsAdapter::setToDefault(const Settings::Key key)
{
    setAppValue(key, settingsManager_->getDefault(key));
}

const QString
UtilsAdapter::getProjectCredits()
{
    return Utils::getProjectCredits();
}

const QString
UtilsAdapter::getVersionStr()
{
    return QString(VERSION_STRING);
}

void
UtilsAdapter::setClipboardText(QString text)
{
    clipboard_->setText(text, QClipboard::Clipboard);
}

const QString
UtilsAdapter::qStringFromFile(const QString& filename)
{
    return Utils::QByteArrayFromFile(filename);
}

const QString
UtilsAdapter::getStyleSheet(const QString& name, const QString& source)
{
    auto simplifiedCSS = source.simplified().replace("'", "\"");
    static auto baseScript = QString::fromLatin1("(function() {"
                                                 "    var node = document.createElement('style');"
                                                 "    node.id = '%1';"
                                                 "    node.innerHTML = '%2';"
                                                 "    document.head.appendChild(node);"
                                                 "})()");
    return baseScript.arg(name, simplifiedCSS);
}

const QString
UtilsAdapter::getLocalDataPath()
{
    QDir dataDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation));
    dataDir.cdUp();
    return dataDir.absolutePath() + "/jami";
}

const QString
UtilsAdapter::getCachePath()
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
}

QString
UtilsAdapter::getDefaultRecordPath() const
{
    auto defaultDirectory = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation)
                            + "/Jami";
    QDir dir(defaultDirectory);
    if (!dir.exists())
        dir.mkpath(".");
    return defaultDirectory;
}

bool
UtilsAdapter::createStartupLink()
{
    return Utils::CreateStartupLink(L"Jami");
}

QString
UtilsAdapter::GetRingtonePath()
{
    return Utils::GetRingtonePath();
}

bool
UtilsAdapter::checkStartupLink()
{
    return Utils::CheckStartupLink(L"Jami");
}

const QString
UtilsAdapter::getBestName(const QString& accountId, const QString& uid)
{
    const auto& conv = lrcInstance_->getConversationFromConvUid(uid);
    if (!conv.participants.isEmpty())
        return lrcInstance_->getAccountInfo(accountId).contactModel->bestNameForContact(
            conv.participants[0].uri);
    return QString();
}

QString
UtilsAdapter::getBestNameForUri(const QString& accountId, const QString& uri)
{
    return lrcInstance_->getAccountInfo(accountId).contactModel->bestNameForContact(uri);
}

QString
UtilsAdapter::getBestIdForUri(const QString& accountId, const QString& uri)
{
    return lrcInstance_->getAccountInfo(accountId).contactModel->bestIdForContact(uri);
}

QString
UtilsAdapter::getConvIdForUri(const QString& accountId, const QString& uri)
{
    try {
        auto* convModel = lrcInstance_->getAccountInfo(accountId).conversationModel.get();
        auto convInfo = convModel->getConversationForPeerUri(uri);
        if (!convInfo)
            return {};
        return convInfo->get().uid;
    } catch (const std::out_of_range& e) {
        qDebug() << e.what();
        return "";
    }
}

const QString
UtilsAdapter::getPeerUri(const QString& accountId, const QString& uid)
{
    try {
        auto* convModel = lrcInstance_->getAccountInfo(accountId).conversationModel.get();
        const auto& convInfo = convModel->getConversationForUid(uid).value();
        return convInfo.get().participants.front().uri;
    } catch (const std::out_of_range& e) {
        qDebug() << e.what();
        return "";
    }
}

QString
UtilsAdapter::getBestId(const QString& accountId)
{
    if (accountId.isEmpty())
        return {};
    return lrcInstance_->accountModel().bestIdForAccount(accountId);
}

const QString
UtilsAdapter::getBestId(const QString& accountId, const QString& uid)
{
    const auto& conv = lrcInstance_->getConversationFromConvUid(uid);
    if (!conv.participants.isEmpty())
        return lrcInstance_->getAccountInfo(accountId).contactModel->bestIdForContact(
            conv.participants[0].uri);
    return QString();
}

void
UtilsAdapter::setConversationFilter(const QString& filter)
{
    lrcInstance_->getCurrentConversationModel()->setFilter(filter);
}

int
UtilsAdapter::getAccountListSize()
{
    return lrcInstance_->accountModel().getAccountList().size();
}

bool
UtilsAdapter::hasCall(const QString& accountId)
{
    auto activeCalls = lrcInstance_->getActiveCalls(accountId);
    for (const auto& callId : activeCalls) {
        auto& accountInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        if (accountInfo.callModel->hasCall(callId)) {
            return true;
        }
    }
    return false;
}

const QString
UtilsAdapter::getCallConvForAccount(const QString& accountId)
{
    // TODO: Currently returning first call, establish priority according to state?
    for (const auto& callId : lrcInstance_->getActiveCalls(accountId)) {
        auto& accountInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        if (accountInfo.callModel->hasCall(callId)) {
            return lrcInstance_->getConversationFromCallId(callId, accountId).uid;
        }
    }
    return "";
}

const QString
UtilsAdapter::getCallId(const QString& accountId, const QString& convUid)
{
    auto const& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
    if (convInfo.uid.isEmpty()) {
        return {};
    }

    if (auto* call = lrcInstance_->getCallInfoForConversation(convInfo, false)) {
        return call->id;
    }

    return {};
}

int
UtilsAdapter::getCallStatus(const QString& callId)
{
    const auto callStatus = lrcInstance_->getCallInfo(callId, lrcInstance_->get_currentAccountId());
    return static_cast<int>(callStatus->status);
}

const QString
UtilsAdapter::getCallStatusStr(int statusInt)
{
    const auto status = static_cast<lrc::api::call::Status>(statusInt);
    return lrc::api::call::to_string(status);
}

QString
UtilsAdapter::getStringUTF8(QString string)
{
    return string.toUtf8();
}

QString
UtilsAdapter::getRecordQualityString(int value)
{
    auto valueStr = QString::number(static_cast<float>(value) / 100, 'f', 1);
    return value ? tr("%1 Mbps").arg(valueStr) : tr("Default");
}

QString
UtilsAdapter::getCurrentPath()
{
    return QDir::currentPath();
}

QString
UtilsAdapter::stringSimplifier(QString input)
{
    return input.simplified();
}

QString
UtilsAdapter::toNativeSeparators(QString inputDir)
{
    return QDir::toNativeSeparators(inputDir);
}

QString
UtilsAdapter::toFileInfoName(QString inputFileName)
{
    QFileInfo fi(inputFileName);
    return fi.fileName();
}

QString
UtilsAdapter::toFileAbsolutepath(QString inputFileName)
{
    QFileInfo fi(inputFileName);
    return fi.absolutePath();
}

QString
UtilsAdapter::getAbsPath(QString path)
{
    static auto fileSchemeRe = QRegularExpression("^file:\\/{2,3}");
    // Note: this function is used on urls returned from qml-FileDialogs which
    // contain 'file:///' for reasons we don't understand.
    // TODO: this logic can be refactored into the JamiFileDialog component.
#ifdef Q_OS_WIN
    return path.replace(fileSchemeRe, "").replace("\n", "").replace("\r", "");
#else
    return path.replace(fileSchemeRe, "/").replace("\n", "").replace("\r", "");
#endif
}

QString
UtilsAdapter::fileName(const QString& path)
{
    QFileInfo fi(path);
    return fi.fileName();
}

QString
UtilsAdapter::dirName(const QString& path)
{
    QDir dir(path);
    return dir.dirName();
}

QString
UtilsAdapter::getExt(const QString& path)
{
    QFileInfo fi(path);
    return fi.completeSuffix();
}

bool
UtilsAdapter::isImage(const QString& fileExt)
{
    return Utils::isImage(fileExt);
}

QString
UtilsAdapter::humanFileSize(qint64 fileSize)
{
    return Utils::humanFileSize(fileSize);
}

void
UtilsAdapter::setSystemTrayIconVisible(bool visible)
{
    systemTray_->setVisible(visible);
}

QString
UtilsAdapter::getDirDocument()
{
    return QDir::toNativeSeparators(
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation));
}

QString
UtilsAdapter::getDirScreenshot()
{
    QString screenshotPath = lrcInstance_->accountModel().screenshotDirectory;
    if (screenshotPath.isEmpty()) {
        QString folderName = "Jami";
        auto picture = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
        QDir dir;
        dir.mkdir(picture + QDir::separator() + folderName);
        screenshotPath = picture + QDir::separator() + folderName;
        setScreenshotPath(screenshotPath);
        lrcInstance_->accountModel().screenshotDirectory = screenshotPath;
    }
    return screenshotPath;
}

QString
UtilsAdapter::getDirDownload()
{
    QString downloadPath = QDir::toNativeSeparators(lrcInstance_->accountModel().downloadDirectory);
    if (downloadPath.isEmpty()) {
        downloadPath = lrc::api::DataTransferModel::createDefaultDirectory();
        setDownloadPath(downloadPath);
        lrcInstance_->accountModel().downloadDirectory = downloadPath;
    }
#ifdef Q_OS_WIN
    int pos = downloadPath.lastIndexOf(QChar('\\'));
#else
    int pos = downloadPath.lastIndexOf(QChar('/'));
#endif
    if (pos == downloadPath.length() - 1)
        downloadPath.truncate(pos);
    return downloadPath;
}

void
UtilsAdapter::setRunOnStartUp(bool state)
{
    if (Utils::CheckStartupLink(L"Jami")) {
        if (!state) {
            Utils::DeleteStartupLink(L"Jami");
        }
    } else if (state) {
        Utils::CreateStartupLink(L"Jami");
    }
}

void
UtilsAdapter::setDownloadPath(QString dir)
{
    setAppValue(Settings::Key::DownloadPath, dir);
    if (!dir.endsWith(QDir::separator()))
        dir += QDir::separator();
    lrcInstance_->accountModel().downloadDirectory = dir;
}

void
UtilsAdapter::setScreenshotPath(QString dir)
{
    setAppValue(Settings::Key::ScreenshotPath, dir);
    if (!dir.endsWith(QDir::separator()))
        dir += QDir::separator();
    lrcInstance_->accountModel().screenshotDirectory = dir;
}

void
UtilsAdapter::monitor(const bool& continuous)
{
    disconnect(debugMessageReceivedConnection_);
    if (continuous)
        debugMessageReceivedConnection_
            = QObject::connect(&lrcInstance_->behaviorController(),
                               &lrc::api::BehaviorController::debugMessageReceived,
                               this,
                               [this](const QString& data) {
                                   logList_.append(data);
                                   if (logList_.size() >= LOGSLIMIT) {
                                       logList_.removeFirst();
                                   }
                                   Q_EMIT debugMessageReceived(data);
                               });
    lrcInstance_->monitor(continuous);
}

QVariantMap
UtilsAdapter::supportedLang()
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
    auto trDir = QDir(appDir + QDir::separator() + "jami" + QDir::separator() + "translations");
    QStringList trFiles = trDir.entryList(QStringList() << "jami_client_qt_*.qm", QDir::Files);
    QVariantMap result;
    result["SYSTEM"] = tr("System");
    // Get available locales
    QRegExp regex("jami_client_qt_(.*).qm");
    QSet<QString> nativeNames;
    for (const auto& f : trFiles) {
        regex.indexIn(f);
        auto captured = regex.capturedTexts();
        if (captured.size() == 2) {
            auto nativeName = QLocale(captured[1]).nativeLanguageName();
            if (nativeName.isEmpty()) // If a locale doesn't have any nativeLanguageName, ignore it.
                continue;
            // Avoid to show potential duplicates.
            if (!nativeNames.contains(nativeName)) {
                result[captured[1]] = nativeName;
                nativeNames.insert(nativeName);
            }
        }
    }
    return result;
}

QString
UtilsAdapter::tempCreationImage(const QString& imageId) const
{
    if (imageId == "temp")
        return Utils::QByteArrayFromFile(
            QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "tmpSwarmImage");
    if (lrcInstance_->getCurrentConversationModel())
        return lrcInstance_->getCurrentConversationModel()->avatar(imageId);
    return {};
}

void
UtilsAdapter::setTempCreationImageFromString(const QString& image, const QString& imageId)
{
    // Compress the image before saving
    auto img = Utils::imageFromBase64String(image, false);
    setTempCreationImageFromImage(img, imageId);
}

void
UtilsAdapter::setTempCreationImageFromFile(const QString& path, const QString& imageId)
{
    // Compress the image before saving
    auto image = Utils::QByteArrayFromFile(path);
    auto img = Utils::imageFromBase64Data(image, false);
    setTempCreationImageFromImage(img, imageId);
}

void
UtilsAdapter::setTempCreationImageFromImage(const QImage& image, const QString& imageId)
{
    // Compress the image before saving
    QByteArray ba;
    QBuffer bu(&ba);
    if (!image.isNull()) {
        auto img = Utils::scaleAndFrame(image, QSize(256, 256));
        img.save(&bu, "PNG");
    }
    // Save the image
    if (imageId == "temp") {
        QFile file(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                   + "tmpSwarmImage");
        file.open(QIODevice::WriteOnly);
        file.write(ba.toBase64());
        file.close();
        Q_EMIT lrcInstance_->base64SwarmAvatarChanged();
    } else {
        lrcInstance_->getCurrentConversationModel()->updateConversationInfos(imageId,
                                                                             {{"avatar",
                                                                               ba.toBase64()}});
    }
}

bool
UtilsAdapter::getContactPresence(const QString& accountId, const QString& uri)
{
    try {
        if (lrcInstance_->getAccountInfo(accountId).profileInfo.uri == uri)
            return true; // It's the same account
        auto info = lrcInstance_->getAccountInfo(accountId).contactModel->getContact(uri);
        return info.isPresent;
    } catch (...) {
    }
    return false;
}

QString
UtilsAdapter::getContactBestName(const QString& accountId, const QString& uri)
{
    try {
        if (lrcInstance_->getAccountInfo(accountId).profileInfo.uri == uri)
            return lrcInstance_->accountModel().bestNameForAccount(
                accountId); // It's the same account
        return lrcInstance_->getAccountInfo(accountId).contactModel->bestNameForContact(uri);
    } catch (...) {
    }
    return {};
}

lrc::api::member::Role
UtilsAdapter::getParticipantRole(const QString& accountId, const QString& convId, const QString& uri)
{
    try {
        return lrcInstance_->getAccountInfo(accountId).conversationModel->memberRole(convId, uri);
    } catch (...) {
    }
    return lrc::api::member::Role::MEMBER;
}

bool
UtilsAdapter::luma(const QColor& color) const
{
    return (0.2126 * color.red() + 0.7152 * color.green() + 0.0722 * color.blue())
           < 153 /* .6 * 256 */;
}

#if __has_include(<gio/gio.h>)
void
settingsCallback(GSettings* self, gchar* key, gpointer user_data)
{
    QString keyString = key;
    if (keyString == "color-scheme" || keyString == "gtk-theme") {
        Q_EMIT((UtilsAdapter*) (user_data))->appThemeChanged();
    }
}
#endif

#if defined(WIN32) && __has_include(<winrt/Windows.Foundation.h>)
bool
readAppsUseLightThemeRegistry(bool getValue)
{
    auto returnValue = true;
    HKEY hKey;
    auto lResult
        = RegOpenKeyEx(HKEY_CURRENT_USER,
                       TEXT("Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"),
                       0,
                       KEY_READ,
                       &hKey);

    if (lResult != ERROR_SUCCESS) {
        RegCloseKey(hKey);
        return false;
    }

    DWORD dwBufferSize(sizeof(DWORD));
    DWORD nResult(0);
    LONG nError = ::RegQueryValueExW(hKey,
                                     TEXT("AppsUseLightTheme"),
                                     0,
                                     NULL,
                                     reinterpret_cast<LPBYTE>(&nResult),
                                     &dwBufferSize);
    if (nError != ERROR_SUCCESS) {
        returnValue = false;
    } else if (getValue) {
        returnValue = !nResult;
    }

    RegCloseKey(hKey);
    return returnValue;
}
#endif

bool
UtilsAdapter::isSystemThemeDark()
{
#if __has_include(<gio/gio.h>)
    if (!settings) {
        settings = g_settings_new("org.gnome.desktop.interface");
        if (!settings)
            return false;
        g_signal_connect(settings, "changed", G_CALLBACK(settingsCallback), this);
    }
    if (!schema) {
        g_object_get(settings, "settings-schema", &schema, nullptr);
        if (!schema)
            return false;
    }
    std::vector<std::string> keys = {"gtk-color-scheme", "color-scheme", "gtk-theme"};
    auto** gtk_keys = g_settings_schema_list_keys(schema);
    for (const auto& key : keys) {
        auto hasKey = false;
        for (int i = 0; gtk_keys[i]; i++) {
            if (key == gtk_keys[i]) {
                hasKey = true;
                break;
            }
        }
        if (hasKey) {
            if (auto* valueCstr = g_settings_get_string(settings, key.c_str())) {
                QString value = valueCstr;
                if (!value.isEmpty()) {
                    return value.contains("dark", Qt::CaseInsensitive)
                           || value.contains("black", Qt::CaseInsensitive);
                }
            }
        }
    }
    return false;
#else
#if defined(WIN32) && __has_include(<winrt/Windows.Foundation.h>)
#if WATCHSYSTEMTHEME
    if (!settings) {
        settings = UISettings();
        settings.ColorValuesChanged([this](auto&&...) { Q_EMIT appThemeChanged(); });
    }
#endif
    return readAppsUseLightThemeRegistry(true);
#else
    qWarning("System theme detection is not implemented or is not supported");
    return false;
#endif // WIN32
#endif // __has_include(<gio/gio.h>)
}

bool
UtilsAdapter::useApplicationTheme()
{
    QString theme = getAppValue(Settings::Key::AppTheme).toString();
    if (theme == "Dark")
        return true;
    else if (theme == "Light")
        return false;
    return isSystemThemeDark();
}

bool
UtilsAdapter::hasNativeDarkTheme() const
{
#if __has_include(<gio/gio.h>)
    return true;
#else
#if defined(WIN32) && __has_include(<winrt/Windows.Foundation.h>)
    return readAppsUseLightThemeRegistry(false);
#else
    return false;
#endif
#endif
}

QString
UtilsAdapter::getOneline(const QString& input)
{
    auto output = input;
    auto index = output.indexOf("\n");
    if (index > 0)
        output.truncate(index);
    return output;
}

QVariantMap
UtilsAdapter::getVideoPlayer(const QString& resource, const QString& bgColor)
{
    static const QString htmlVideo
        = "<body style='margin:0;padding:0;'>"
          "<video autoplay muted loop "
          "style='width:100%;height:100%;outline:none;background-color:%2;"
          "object-fit:cover;' "
          "src='%1' type='video/webm'/></body>";
    return {
        {"isVideo", true},
        {"html", htmlVideo.arg(resource, bgColor)},
    };
}

bool
UtilsAdapter::isRTL()
{
    auto pref = getAppValue(Settings::Key::LANG).toString();
    pref = pref == "SYSTEM" ? QLocale::system().name() : pref;
    static const QStringList rtlLanguages {
        // as defined by ISO 639-1
        "ar", // Arabic
        "he", // Hebrew
        "fa", // Persian (Farsi)
        "ur", // Urdu
        "ps", // Pashto
        "ku", // Kurdish
        "sd", // Sindhi
        "dv", // Dhivehi (Maldivian)
        "yi", // Yiddish
        "am", // Amharic
        "ti", // Tigrinya
        "kk"  // Kazakh (in Arabic script)
    };
    return rtlLanguages.contains(pref);
}

bool
UtilsAdapter::isSystemTrayIconVisible()
{
    if (!systemTray_)
        return false;
    return systemTray_->geometry() != QRect();
}

QString
UtilsAdapter::base64Encode(const QString& input)
{
    QByteArray byteArray = input.toUtf8();
    return byteArray.toBase64();
}

bool
UtilsAdapter::fileExists(const QString& filePath)
{
    return QFile::exists(filePath);
}

QString
UtilsAdapter::getStandardTempLocation()
{
    return QStandardPaths::writableLocation(
        static_cast<QStandardPaths::StandardLocation>(QStandardPaths::TempLocation));
}

QString
UtilsAdapter::getMimeNameForUrl(const QUrl& fileUrl) const
{
    QMimeDatabase db;
    QMimeType mime = db.mimeTypeForUrl(fileUrl);
    return mime.name();
}

QUrl
UtilsAdapter::urlFromLocalPath(const QString& filePath) const
{
    return QUrl::fromLocalFile(filePath);
}

#ifdef ENABLE_TESTS
// Must only be used for testing purposes
QString
UtilsAdapter::createDummyImage() const
{
    // Create an QImage
    QImage image(256, 256, QImage::Format_ARGB32);
    image.fill(QColor(255, 255, 255, 255));

    QByteArray ba;
    QBuffer bu(&ba);
    image.save(&bu, "PNG");

    // Save the image to a file
    QFile file(QDir::tempPath() + "/dummy.png");
    if (file.open(QIODevice::WriteOnly)) {
        file.write(ba);
        file.close();
        qInfo() << "Dummy image created" << QDir::tempPath() + "/dummy.png";
        return QDir::tempPath() + "/dummy.png";
    } else {
        qWarning() << "Could not create dummy image";
        return "";
    }
}
#endif

bool
UtilsAdapter::isWayland() const
{
    return !qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY");
}
