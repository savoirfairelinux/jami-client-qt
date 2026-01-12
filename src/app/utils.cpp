/*
 * Copyright (C) 2015-2026 Savoir-faire Linux Inc.
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

#include "utils.h"

#include "jamiavatartheme.h"
#include "lrcinstance.h"
#include "global.h"

#include <api/contact.h>

#include <QApplication>
#include <QBitmap>
#include <QErrorMessage>
#include <QFile>
#include <QMessageBox>
#include <QObject>
#include <QPainter>
#include <QPropertyAnimation>
#include <QScreen>
#include <QDateTime>
#include <QSvgRenderer>
#include <QTranslator>
#include <QtConcurrent/QtConcurrent>
#include <QUuid>

#ifdef Q_OS_WIN
#include <lmcons.h>
#include <shlguid.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <shobjidl.h>
#include <windows.h>
#endif

#include <BitMatrix.h>
#include <MultiFormatWriter.h>

// Removes the given argument from the command line arguments, and invokes the callback
// function with the removed argument if it was found.
// This is required for custom args as quick_test_main_with_setup() will
// fail if given an invalid command-line argument.
void
Utils::remove_argument(char** argv, int& argc, const std::string& arg_to_remove, std::function<void()> callback)
{
    // Remove arg_to_remove from argv, as quick_test_main_with_setup() will
    // fail if given an invalid command-line argument.
    auto new_end = std::remove_if(argv + 1, argv + argc, [&](char* arg_ptr) {
        if (std::string(arg_ptr).compare(arg_to_remove) == 0) {
            // Invoke the callback function with the removed argument.
            callback();
            return true;
        } else {
            return false;
        }
    });

    // If any occurrences were removed…
    if (new_end != argv + argc) {
        // Adjust the argument count.
        argc = std::distance(argv, new_end);
    }
}

void
Utils::testVulkanSupport()
{
#if defined(Q_OS_WIN)
    // Checks Vulkan support using the Vulkan functions loaded directly
    // from vulkan-1.dll.
    struct DllLoader
    {
        explicit DllLoader(const std::string& filename)
            : module(LoadLibraryA(filename.c_str()))
        {
            if (module == nullptr) {
                throw std::runtime_error("Unable to load module.");
            }
        }
        ~DllLoader()
        {
            FreeLibrary(module);
        }
        HMODULE module;
    } vk {"vulkan-1.dll"};

    typedef void*(__stdcall * PFN_vkGetInstanceProcAddr)(void*, const char*);
    auto vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr) GetProcAddress(vk.module, "vkGetInstanceProcAddr");
    if (!vkGetInstanceProcAddr) {
        throw std::runtime_error("Missing vkGetInstanceProcAddr proc.");
    }

    typedef int(__stdcall * PFN_vkCreateInstance)(int*, void*, void**);
    auto vkCreateInstance = (PFN_vkCreateInstance) vkGetInstanceProcAddr(vk.module, "vkCreateInstance");
    if (!vkCreateInstance) {
        throw std::runtime_error("Missing vkCreateInstance proc.");
    }

    void* instance = 0;
    int VkInstanceCreateInfo[16] = {1};
    auto result = vkCreateInstance(VkInstanceCreateInfo, 0, &instance);
    if (!instance || result != 0) {
        throw std::runtime_error("Unable to create Vulkan instance.");
    }
#endif
}

bool
Utils::CreateStartupLink(const std::wstring& wstrAppName)
{
#ifdef Q_OS_WIN
    TCHAR szPath[MAX_PATH];
    GetModuleFileName(NULL, szPath, MAX_PATH);

    std::wstring programPath(szPath);

    TCHAR startupPath[MAX_PATH];
    SHGetFolderPathW(NULL, CSIDL_STARTUP, NULL, 0, startupPath);

    std::wstring linkPath(startupPath);
    linkPath += std::wstring(TEXT("\\") + wstrAppName + TEXT(".lnk"));

    return Utils::CreateLink(programPath.c_str(), linkPath.c_str());
#else
    Q_UNUSED(wstrAppName)
    QString desktopPath;
    /* cmake should set JAMI_INSTALL_PREFIX, otherwise it checks the following dirs
     *  - /usr/<data dir>
     *  - /usr/local/<data dir>
     *  - default install data dir
     */

#ifdef JAMI_INSTALL_PREFIX
    desktopPath = JAMI_INSTALL_PREFIX;
    desktopPath += "/jami/net.jami.Jami.desktop";
#else
    desktopPath = "share/jami/net.jami.Jami.desktop";
    QStringList paths = {"/usr/" + desktopPath,
                         "/usr/local/" + desktopPath,
                         QDir::currentPath() + "/../../install/client-qt/" + desktopPath};
    for (QString filename : paths) {
        if (QFile::exists(filename)) {
            desktopPath = filename;
            break;
        }
    }
#endif

    if (desktopPath.isEmpty() || !(QFile::exists(desktopPath))) {
        qDebug() << "Error while attempting to locate .desktop file at" << desktopPath;
        return false;
    }

    qDebug() << "Linking autostart file from" << desktopPath;

    QString desktopFile = QStandardPaths::locate(QStandardPaths::ConfigLocation, "autostart/net.jami.Jami.desktop");
    if (!desktopFile.isEmpty()) {
        QFileInfo symlinkInfo(desktopFile);
        if (symlinkInfo.isSymLink()) {
            if (symlinkInfo.symLinkTarget() == desktopPath) {
                qDebug() << desktopFile << "already points to" << desktopPath;
                return true;
            } else {
                qDebug() << desktopFile << "exists but does not point to" << desktopPath;
                QFile::remove(desktopFile);
            }
        }
    } else {
        QString autoStartDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/autostart";

        if (!QDir(autoStartDir).exists()) {
            if (QDir().mkdir(autoStartDir)) {
                qDebug() << "Created autostart directory:" << autoStartDir;
            } else {
                qWarning() << "Error while creating autostart directory:" << autoStartDir;
                return false;
            }
        }
        desktopFile = autoStartDir + "/net.jami.Jami.desktop";
    }

    QFile srcFile(desktopPath);
    bool result = srcFile.link(desktopFile);
    qDebug() << desktopFile << (result ? "-> " + desktopPath + " created successfully" : "unable to be created");
    return result;
#endif
}

bool
Utils::CreateLink(LPCWSTR lpszPathObj, LPCWSTR lpszPathLink)
{
#ifdef Q_OS_WIN
    HRESULT hres;
    IShellLink* psl;

    hres = CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER, IID_IShellLink, (LPVOID*) &psl);
    if (SUCCEEDED(hres)) {
        IPersistFile* ppf;
        psl->SetPath(lpszPathObj);
        psl->SetArguments(TEXT("--minimized"));

        hres = psl->QueryInterface(IID_IPersistFile, (LPVOID*) &ppf);
        if (SUCCEEDED(hres)) {
            hres = ppf->Save(lpszPathLink, TRUE);
            ppf->Release();
        }
        psl->Release();
    }
    return hres;
#else
    Q_UNUSED(lpszPathObj)
    Q_UNUSED(lpszPathLink)
    return true;
#endif
}

void
Utils::DeleteStartupLink(const std::wstring& wstrAppName)
{
#ifdef Q_OS_WIN
    TCHAR startupPath[MAX_PATH];
    SHGetFolderPathW(NULL, CSIDL_STARTUP, NULL, 0, startupPath);

    std::wstring linkPath(startupPath);
    linkPath += std::wstring(TEXT("\\") + wstrAppName + TEXT(".lnk"));

    DeleteFile(linkPath.c_str());

#else
    Q_UNUSED(wstrAppName)
    QString desktopFile = QStandardPaths::locate(QStandardPaths::ConfigLocation, "autostart/net.jami.Jami.desktop");
    if (!desktopFile.isEmpty()) {
        try {
            QFile::remove(desktopFile);
            qDebug() << "Autostart disabled," << desktopFile << "removed";
        } catch (...) {
            qDebug() << "Unable to remove" << desktopFile;
        }
    } else {
        qDebug() << desktopFile << "does not exist";
    }
#endif
}

bool
Utils::CheckStartupLink(const std::wstring& wstrAppName)
{
#ifdef Q_OS_WIN
    TCHAR startupPath[MAX_PATH];
    SHGetFolderPathW(NULL, CSIDL_STARTUP, NULL, 0, startupPath);

    std::wstring linkPath(startupPath);
    linkPath += std::wstring(TEXT("\\") + wstrAppName + TEXT(".lnk"));
    return PathFileExists(linkPath.c_str());
#else
    Q_UNUSED(wstrAppName)
    return (!QStandardPaths::locate(QStandardPaths::ConfigLocation, "autostart/net.jami.Jami.desktop").isEmpty());
#endif
}

void
Utils::removeOldVersions()
{
#ifdef Q_OS_WIN
    /*
     * As per: https://git.jami.net/savoirfairelinux/ring-client-windows/issues/429
     * NB: As only the 64-bit version of this application is distributed, we will only
     * remove 1. the configuration reg keys for Ring-x64, 2. the startup links for Ring,
     * 3. the winsparkle reg keys. The NSIS uninstall reg keys for Jami-x64 are removed
     * by the MSI installer.
     * Uninstallation of Ring, either 32-bit or 64-bit, is left to the user.
     * The current version of Jami will attempt to kill Ring.exe upon start if a startup
     * link is found.
     */
    QString node64 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node";
    QString hkcuSoftwareKey = "HKEY_CURRENT_USER\\Software\\";
    QString uninstKey = "\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\";
    QString company = "Savoir-faire Linux Inc.";

    /*
     * 1. Configuration reg keys for Ring-x64.
     */
    QSettings(hkcuSoftwareKey + "jami.net\\Ring", QSettings::NativeFormat).remove("");
    QSettings(hkcuSoftwareKey + "ring.cx", QSettings::NativeFormat).remove("");

    /*
     * 2. Unset Ring as a startup application.
     */
    if (Utils::CheckStartupLink(TEXT("Ring"))) {
        qDebug() << "Found startup link for Ring. Removing it and killing Ring.exe.";
        Utils::DeleteStartupLink(TEXT("Ring"));
        QProcess process;
        process.start("taskkill", QStringList() << "/im" << "Ring.exe" << "/f");
        process.waitForFinished();
    }

    /*
     * 3. Remove registry entries for winsparkle(both Jami-x64 and Ring-x64).
     */
    QSettings(hkcuSoftwareKey + company, QSettings::NativeFormat).remove("");
#else
    return;
#endif
}

QString
Utils::GetRingtonePath()
{
#ifdef Q_OS_WIN
    return QCoreApplication::applicationDirPath() + "\\ringtones\\default.opus";
#else
    return QString("/usr/share/jami/ringtones/default.opus");
#endif
}

QString
Utils::GenGUID()
{
#ifdef Q_OS_WIN
    GUID gidReference;
    wchar_t* str;
    HRESULT hCreateGuid = CoCreateGuid(&gidReference);
    if (hCreateGuid == S_OK) {
        StringFromCLSID(gidReference, &str);
        auto gStr = QString::fromWCharArray(str);
        return gStr.remove("{").remove("}").toLower();
    } else
        return QString();
#else
    return QString("");
#endif
}

QString
Utils::GetISODate()
{
#ifdef Q_OS_WIN
    SYSTEMTIME lt;
    GetSystemTime(&lt);
    return QString("%1-%2-%3T%4:%5:%6Z")
        .arg(lt.wYear)
        .arg(lt.wMonth, 2, 10, QChar('0'))
        .arg(lt.wDay, 2, 10, QChar('0'))
        .arg(lt.wHour, 2, 10, QChar('0'))
        .arg(lt.wMinute, 2, 10, QChar('0'))
        .arg(lt.wSecond, 2, 10, QChar('0'));
#else
    return QString();
#endif
}

QImage
Utils::accountPhoto(LRCInstance* instance, const QString& accountId, const QSize& size)
{
    QImage photo;
    try {
        auto& accInfo = instance->accountModel().getAccountInfo(accountId.isEmpty() ? instance->get_currentAccountId()
                                                                                    : accountId);
        auto bestName = instance->accountModel().bestNameForAccount(accInfo.id);
        if (!accInfo.profileInfo.avatar.isEmpty()) {
            photo = imageFromBase64String(accInfo.profileInfo.avatar);
            if (photo.isNull()) {
                qWarning() << "Invalid image for account " << bestName;
            }
        }
        if (photo.isNull()) {
            QString name = bestName == accInfo.profileInfo.uri ? QString() : bestName;
            QString prefix = accInfo.profileInfo.type == profile::Type::JAMI ? "jami:" : "sip:";
            photo = fallbackAvatar(prefix + accInfo.profileInfo.uri, name, size);
        }
    } catch (const std::exception& e) {
        qDebug() << e.what() << "; Using default avatar";
        photo = fallbackAvatar(QString(), QString(), size);
    }
    return Utils::scaleAndFrame(photo, size);
}

QImage
Utils::contactPhoto(LRCInstance* instance, const QString& contactUri, const QSize& size, const QString& accountId)
{
    QImage photo;
    try {
        auto& accInfo = instance->accountModel().getAccountInfo(accountId.isEmpty() ? instance->get_currentAccountId()
                                                                                    : accountId);
        auto contactPhoto = accInfo.contactModel->avatar(contactUri);
        if (!contactPhoto.isEmpty()) {
            photo = imageFromBase64String(contactPhoto);
            if (!photo.isNull())
                return Utils::scaleAndFrame(photo, size);
        }
        // If no avatar is found, generate one
        auto contactInfo = accInfo.contactModel->getContact(contactUri);
        auto bestName = accInfo.contactModel->bestNameForContact(contactUri);
        if (accInfo.profileInfo.type == profile::Type::SIP && contactInfo.profileInfo.type == profile::Type::TEMPORARY) {
            photo = Utils::fallbackAvatar(QString(), QString());
        } else if (contactInfo.profileInfo.type == profile::Type::TEMPORARY && contactInfo.profileInfo.uri.isEmpty()) {
            photo = Utils::fallbackAvatar(QString(), QString());
        } else {
            auto avatarName = contactInfo.profileInfo.uri == bestName ? QString() : bestName;
            photo = Utils::fallbackAvatar("jami:" + contactInfo.profileInfo.uri, avatarName);
        }
    } catch (const std::exception&) {
        photo = fallbackAvatar("jami:" + contactUri, QString(), size);
    }
    return Utils::scaleAndFrame(photo, size);
}

QImage
Utils::conversationAvatar(LRCInstance* instance, const QString& convId, const QSize& size, const QString& accountId)
{
    QImage avatar(size, QImage::Format_ARGB32_Premultiplied);
    avatar.fill(Qt::transparent);
    QPainter painter(&avatar);
    painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
    try {
        auto& accInfo = instance->accountModel().getAccountInfo(accountId.isEmpty() ? instance->get_currentAccountId()
                                                                                    : accountId);
        auto* convModel = accInfo.conversationModel.get();
        auto avatarb64 = convModel->avatar(convId);
        if (!avatarb64.isEmpty()) {
            auto photo = imageFromBase64String(avatarb64, true);
            if (!photo.isNull()) {
                return scaleAndFrame(photo, size);
            }
            qWarning() << "Unable to load image from Base64 data for conversation " << convId;
        }
        // Else, generate an avatar
        auto members = convModel->peersForConversation(convId);
        if (members.size() < 1)
            return avatar;
        auto getPhoto = [&](const auto& uri) {
            return uri == accInfo.profileInfo.uri ? accountPhoto(instance, accountId, size)
                                                  : contactPhoto(instance, uri, size, "");
        };
        if (members.size() == 1) {
            // Only member in the swarm or 1:1, draw only peer's avatar
            auto peerAvatar = getPhoto(members[0]);
            painter.drawImage(avatar.rect(), peerAvatar);
            return avatar;
        }
        // Else, combine avatars
        auto peerAAvatar = getPhoto(members[0]);
        auto peerBAvatar = getPhoto(members[1]);
        peerAAvatar = Utils::halfCrop(peerAAvatar, true);
        peerBAvatar = Utils::halfCrop(peerBAvatar, false);
        painter.drawImage(avatar.rect(), peerAAvatar);
        painter.drawImage(avatar.rect(), peerBAvatar);
    } catch (const std::exception& e) {
        C_DBG << e.what();
    }
    return avatar;
}

QImage
Utils::tempConversationAvatar(const QSize& size)
{
    QString img = QByteArrayFromFile(getTempSwarmAvatarPath());
    if (img.isEmpty())
        return fallbackAvatar(QString(), QString(), size);
    return scaleAndFrame(imageFromBase64String(img, true), size);
}

QImage
Utils::imageFromBase64String(const QString& str, bool circleCrop)
{
    if (str.isEmpty())
        return {};
    return imageFromBase64Data(Utils::base64StringToByteArray(str), circleCrop);
}

QImage
Utils::imageFromBase64Data(const QByteArray& data, bool circleCrop)
{
    QImage img;

    if (img.loadFromData(data)) {
        if (circleCrop) {
            return Utils::getCirclePhoto(img, img.size().width());
        }
        return img;
    }
    return {};
}

QImage
Utils::getCirclePhoto(const QImage original, int sizePhoto)
{
    QImage target(sizePhoto, sizePhoto, QImage::Format_ARGB32_Premultiplied);
    target.fill(Qt::transparent);

    QPainter painter(&target);
    painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
    painter.setBrush(QBrush(Qt::white));
    auto scaledPhoto = original.scaled(sizePhoto, sizePhoto, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation)
                           .convertToFormat(QImage::Format_ARGB32_Premultiplied);
    int marginX = 0;
    int marginY = 0;

    if (scaledPhoto.width() > sizePhoto) {
        marginX = (scaledPhoto.width() - sizePhoto) / 2;
    }
    if (scaledPhoto.height() > sizePhoto) {
        marginY = (scaledPhoto.height() - sizePhoto) / 2;
    }

    painter.drawEllipse(0, 0, sizePhoto, sizePhoto);
    painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
    painter.drawImage(0, 0, scaledPhoto, marginX, marginY);

    return target;
}

QImage
Utils::halfCrop(const QImage original, bool leftSide)
{
    auto width = original.size().width();
    auto height = original.size().height();
    QImage target(width, height, QImage::Format_ARGB32_Premultiplied);
    target.fill(Qt::transparent);

    QPainter painter(&target);
    painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
    painter.setBrush(QBrush(Qt::white));
    painter.drawRect(leftSide ? 0 : width / 2 + 2, 0, width / 2 - (leftSide ? 2 : 0), height);
    painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
    painter.drawImage(0, 0, original, 0, 0);
    return target;
}

QSize
Utils::getRealSize(QScreen* screen)
{
#ifdef Q_OS_WIN
    DEVMODE dmThisScreen;
    ZeroMemory(&dmThisScreen, sizeof(dmThisScreen));
    EnumDisplaySettings((const wchar_t*) screen->name().utf16(), ENUM_CURRENT_SETTINGS, (DEVMODE*) &dmThisScreen);
    return QSize(dmThisScreen.dmPelsWidth, dmThisScreen.dmPelsHeight);
#else
    Q_UNUSED(screen)
    return {};
#endif
}

void
Utils::forceDeleteAsync(const QString& path)
{
    /*
     * Keep deleting file until the process holding it let go,
     * or the file itself does not exist anymore.
     */
    auto futureResult = QtConcurrent::run([path] {
        QFile file(path);
        if (!QFile::exists(path))
            return;
        int retries {0};
        while (!file.remove() && retries < 5) {
            qDebug().noquote() << "\n" << file.errorString() << "\n";
            QThread::msleep(10);
            ++retries;
        }
    });
}

QString
Utils::getProjectCredits()
{
    QFile projectCreditsFile(":/misc/projectcredits.html");
    if (!projectCreditsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug().noquote() << " Project Credits failed to load";
        return {};
    }
    QTextStream in(&projectCreditsFile);
    return in.readAll().arg(QObject::tr("We would like to thank our contributors, whose efforts "
                                        "over many years have made this software what it is."),
                            QObject::tr("Developers"),
                            QObject::tr("Media"),
                            QObject::tr("Community Management"),
                            QObject::tr("Special thanks to"),
                            QObject::tr("This is a list of people who have made a significant investment "
                                        "of time, with useful results, into Jami. Any such contributors "
                                        "who want to be added to the list should contact us."));
}

QString
Utils::getAvailableDictionariesJson()
{
    QFile availableDictionariesFile(":/misc/available_dictionaries.json");
    if (!availableDictionariesFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug().noquote() << "Available Dictionaries file failed to load";
        return {};
    }
    return QString(availableDictionariesFile.readAll());
}

inline QString
removeEndlines(const QString& str)
{
    QString trimmed(str);
    trimmed.remove(QChar('\n'));
    trimmed.remove(QChar('\r'));
    return trimmed;
}

lrc::api::profile::Type
Utils::profileType(const lrc::api::conversation::Info& conv, const lrc::api::ConversationModel& model)
{
    try {
        auto contact = model.owner.contactModel->getContact(conv.participants[0].uri);
        return contact.profileInfo.type;
    } catch (const std::out_of_range& e) {
        qDebug() << e.what();
        return lrc::api::profile::Type::INVALID;
    }
}

bool
Utils::isInteractionGenerated(const lrc::api::interaction::Type& type)
{
    return type == lrc::api::interaction::Type::CALL || type == lrc::api::interaction::Type::CONTACT;
}

bool
Utils::isContactValid(const QString& contactUid, const lrc::api::ConversationModel& model)
{
    try {
        const auto contact = model.owner.contactModel->getContact(contactUid);
        return (contact.profileInfo.type == lrc::api::profile::Type::PENDING
                || contact.profileInfo.type == lrc::api::profile::Type::TEMPORARY
                || contact.profileInfo.type == lrc::api::profile::Type::JAMI
                || contact.profileInfo.type == lrc::api::profile::Type::SIP)
               && !contact.profileInfo.uri.isEmpty();
    } catch (const std::out_of_range& e) {
        qDebug() << e.what();
        return false;
    }
}

bool
Utils::getReplyMessageBox(QWidget* widget, const QString& title, const QString& text)
{
    if (QMessageBox::question(widget, title, text, QMessageBox::Yes | QMessageBox::No) == QMessageBox::Yes)
        return true;
    return false;
}

QColor
Utils::getAvatarColor(const QString& canonicalUri)
{
    if (canonicalUri.isEmpty()) {
        return JamiAvatarTheme::defaultAvatarColor_;
    }
    auto h = QString(QCryptographicHash::hash(canonicalUri.toLocal8Bit(), QCryptographicHash::Md5).toHex());
    if (h.isEmpty() || h.isNull()) {
        return JamiAvatarTheme::defaultAvatarColor_;
    }
    auto colorIndex = std::string("0123456789abcdef").find(h.at(0).toLatin1());
    return JamiAvatarTheme::avatarColors_[colorIndex];
}

/*!
 * Generate a QImage representing a default user avatar, when the user doesn't provide it.
 * If the name passed is empty, then the default avatar picture will be displayed instead
 * of a letter.
 *
 * @param canonicalUri uri containing the account type prefix used to obtain the bgcolor
 * @param name the string used to acquire the letter centered in the avatar
 * @param size the dimensions of the desired image
 */
QImage
Utils::fallbackAvatar(const QString& canonicalUri, const QString& name, const QSize& size)
{
    auto sizeToUse = size.height() >= defaultAvatarSize.height() ? size : defaultAvatarSize;

    QImage avatar(sizeToUse, QImage::Format_ARGB32);
    avatar.fill(Qt::transparent);

    QPainter painter(&avatar);
    painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
    painter.setPen(Qt::transparent);

    // background circle
    painter.setBrush(getAvatarColor(canonicalUri).lighter(110));
    painter.drawEllipse(avatar.rect());

    // if a letter was passed, then we paint a letter in the circle,
    // otherwise we draw the default avatar icon
    QString trimmedName(name);
    const static QRegularExpression newlineRe("[\\n\\t\\r]");
    if (!trimmedName.remove(newlineRe).isEmpty()) {
        auto unicode = trimmedName.toUcs4().at(0);
        if (unicode >= 0x1F000 && unicode <= 0x1FFFF) {
            // emoticon
            auto letter = QString::fromUcs4(reinterpret_cast<char32_t*>(&unicode), 1);
            QFont font(QString("Segoe UI Emoji").split(QLatin1Char(',')), avatar.height() / 2.66667, QFont::Medium);
            painter.setFont(font);
            QRect emojiRect(avatar.rect());
            emojiRect.moveTop(-6);
            painter.drawText(emojiRect, letter, QTextOption(Qt::AlignCenter));
        } else if (unicode >= 0x0000 && unicode <= 0x00FF) {
            // basic Latin
            auto letter = trimmedName.at(0).toUpper();
            QFont font(QString("Arial").split(QLatin1Char(',')), avatar.height() / 2.66667, QFont::Medium);
            painter.setFont(font);
            painter.setPen(Qt::white);
            painter.drawText(avatar.rect(), QString(letter), QTextOption(Qt::AlignCenter));
        } else {
            auto letter = QString::fromUcs4(reinterpret_cast<char32_t*>(&unicode), 1);
            QFont font(QString("Arial").split(QLatin1Char(',')), avatar.height() / 2.66667, QFont::Medium);
            painter.setFont(font);
            painter.setPen(Qt::white);
            painter.drawText(avatar.rect(), QString(letter), QTextOption(Qt::AlignCenter));
        }
    } else {
        QRect overlayRect = avatar.rect();
        qreal margin = (0.05 * overlayRect.width());
        overlayRect.moveLeft(overlayRect.left() + margin * 0.5);
        overlayRect.moveTop(overlayRect.top() + margin * 0.5);
        overlayRect.setWidth(overlayRect.width() - margin);
        overlayRect.setHeight(overlayRect.height() - margin);
        painter.drawPixmap(overlayRect, QPixmap(":/images/default_avatar_overlay.svg"));
    }

    return avatar.scaled(size, Qt::KeepAspectRatio, Qt::SmoothTransformation);
}

QImage
Utils::fallbackAvatar(const std::string& alias, const std::string& uri, const QSize& size)
{
    return fallbackAvatar(QString::fromStdString(uri), QString::fromStdString(alias), size);
}

QByteArray
Utils::QImageToByteArray(QImage image)
{
    QByteArray ba;
    QBuffer buffer(&ba);
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "PNG");
    return ba;
}

QString
Utils::byteArrayToBase64String(QByteArray byteArray)
{
    return QString::fromLatin1(byteArray.toBase64().data());
}

QByteArray
Utils::base64StringToByteArray(QString base64)
{
    return QByteArray::fromBase64(base64.toLatin1());
}

QImage
Utils::cropImage(const QImage& img)
{
    auto w = img.width();
    auto h = img.height();
    if (w > h) {
        return img.copy({(w - h) / 2, 0, h, h});
    }
    return img.copy({0, (h - w) / 2, w, w});
}

QPixmap
Utils::pixmapFromSvg(const QString& svg_resource, const QSize& size)
{
    QSvgRenderer svgRenderer(svg_resource);
    QPixmap pixmap(size);
    pixmap.fill(Qt::transparent);
    QPainter pixPainter(&pixmap);
    svgRenderer.render(&pixPainter);
    return pixmap;
}

QImage
Utils::getQRCodeImage(QString data, int margin)
{
    try {
        ZXing::MultiFormatWriter writer(ZXing::BarcodeFormat::QRCode);
        writer.setEccLevel(0);
        writer.setMargin(margin);
        auto bitMatrix = writer.encode(data.toStdString(), 0, 0);
        int qrwidth = bitMatrix.width();
        int qrheight = bitMatrix.height();

        // Create QImage with the QR code data
        QImage result(qrwidth, qrheight, QImage::Format_Mono);
        result.fill(1); // Fill with white

        // Copy the bitmap data to QImage
        for (int y = 0; y < qrheight; y++) {
            for (int x = 0; x < qrwidth; x++) {
                if (bitMatrix.get(x, y)) {
                    result.setPixel(x, y, 0);
                }
            }
        }
        return result;
    } catch (const std::exception& e) {
        qWarning() << "Failed to generate QR code:" << e.what();
        return QImage();
    }
}

QByteArray
Utils::QByteArrayFromFile(const QString& filename)
{
    QFile file(filename);
    if (!file.exists()) {
        qDebug() << "QByteArrayFromFile: file does not exist" << filename;
    }
    if (file.open(QIODevice::ReadOnly)) {
        return file.readAll();
    }
    qDebug() << "QByteArrayFromFile: unable to open file" << filename;
    return {};
}

QPixmap
Utils::generateTintedPixmap(const QString& filename, QColor color)
{
    QPixmap px(filename);
    QImage tmpImage = px.toImage();
    for (int y = 0; y < tmpImage.height(); y++) {
        for (int x = 0; x < tmpImage.width(); x++) {
            color.setAlpha(tmpImage.pixelColor(x, y).alpha());
            tmpImage.setPixelColor(x, y, color);
        }
    }
    return QPixmap::fromImage(tmpImage);
}

QPixmap
Utils::generateTintedPixmap(const QPixmap& pix, QColor color)
{
    QPixmap px = pix;
    QImage tmpImage = px.toImage();
    for (int y = 0; y < tmpImage.height(); y++) {
        for (int x = 0; x < tmpImage.width(); x++) {
            color.setAlpha(tmpImage.pixelColor(x, y).alpha());
            tmpImage.setPixelColor(x, y, color);
        }
    }
    return QPixmap::fromImage(tmpImage);
}

QImage
Utils::scaleAndFrame(const QImage photo, const QSize& size)
{
    return photo.scaled(size, Qt::KeepAspectRatio, Qt::SmoothTransformation);
}

QString
Utils::humanFileSize(qint64 fileSize)
{
    float fileSizeF = static_cast<float>(fileSize);
    float thresh = 1024;

    if (abs(fileSizeF) < thresh) {
        return QString::number(fileSizeF) + " B";
    }
    QString units[] = {"KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"};
    int unit_position = -1;
    do {
        fileSizeF /= thresh;
        ++unit_position;
    } while (abs(fileSizeF) >= thresh && unit_position < units->size() - 1);
    /*
     * Round up to two decimal.
     */
    fileSizeF = roundf(fileSizeF * 100) / 100;
    return QString::number(fileSizeF) + " " + units[unit_position];
}

QString
Utils::getDebugFilePath()
{
    QDir logPath(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation));
    logPath.cdUp();
    return QString(logPath.absolutePath() + "/jami/jami.log");
}

bool
Utils::isImage(const QString& fileExt)
{
    if (fileExt == "png" || fileExt == "jpg" || fileExt == "jpeg")
        return true;
    return false;
}

QString
Utils::generateUid()
{
    return QUuid::createUuid().toString(QUuid::Id128);
}

QString
Utils::getTempSwarmAvatarPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QDir::separator() + "tmpSwarmImage";
}

QVariantMap
Utils::mapStringStringToVariantMap(const MapStringString& map)
{
    QVariantMap variantMap;
    for (auto it = map.constBegin(); it != map.constEnd(); ++it) {
        variantMap.insert(it.key(), it.value());
    }
    return variantMap;
}
