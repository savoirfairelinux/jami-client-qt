/*!
 * Copyright (C) 2015-2024 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

#include <QCryptographicHash>
#include <QDir>

#include <QImage>
#include <QLabel>
#include <QListWidget>
#include <QMessageBox>
#include <QQmlEngine>
#include <QSettings>
#include <QStackedWidget>
#include <QStandardPaths>
#include <QString>
#include <QTextDocument>
#include <QtGlobal>

#include <string>

#ifdef Q_OS_WIN
#include <ciso646>
#include <windows.h>
#undef ERROR
#else
#define LPCWSTR char*
#endif

#include "api/account.h"
#include "api/contactmodel.h"
#include "api/conversationmodel.h"

class LRCInstance;

namespace Utils {

// Helper used to remove app arguments.
void remove_argument(char** argv,
                     int& argc,
                     const std::string& arg_to_remove,
                     std::function<void()> callback);

// Throws if Vulkan cannot be instantiated.
void testVulkanSupport();

// App System
bool CreateStartupLink(const std::wstring& wstrAppName);
void DeleteStartupLink(const std::wstring& wstrAppName);
bool CreateLink(LPCWSTR lpszPathObj, LPCWSTR lpszPathLink);
bool CheckStartupLink(const std::wstring& wstrAppName);
QString GetRingtonePath();
QString GenGUID();
QString GetISODate();
QSize getRealSize(QScreen* screen);
void forceDeleteAsync(const QString& path);
QString getProjectCredits();
void removeOldVersions();

// LRC helpers
lrc::api::profile::Type profileType(const lrc::api::conversation::Info& conv,
                                    const lrc::api::ConversationModel& model);
bool isInteractionGenerated(const lrc::api::interaction::Type& interaction);
bool isContactValid(const QString& contactUid, const lrc::api::ConversationModel& model);
bool getReplyMessageBox(QWidget* widget, const QString& title, const QString& text);

// Image manipulation
constexpr static const QSize defaultAvatarSize {128, 128};
QImage imageFromBase64String(const QString& str, bool circleCrop = true);
QImage imageFromBase64Data(const QByteArray& data, bool circleCrop = true);
QImage accountPhoto(LRCInstance* instance,
                    const QString& accountId,
                    const QSize& size = defaultAvatarSize);
QImage contactPhoto(LRCInstance* instance,
                    const QString& contactUri,
                    const QSize& size = defaultAvatarSize,
                    const QString& accountId = {});
QImage conversationAvatar(LRCInstance* instance,
                          const QString& convId,
                          const QSize& size = defaultAvatarSize,
                          const QString& accountId = {});
QImage getCirclePhoto(const QImage original, int sizePhoto);
QImage halfCrop(const QImage original, bool leftSide);
QColor getAvatarColor(const QString& canonicalUri);
QImage tempConversationAvatar(const QSize& size);
QImage fallbackAvatar(const QString& canonicalUriStr,
                      const QString& letterStr = {},
                      const QSize& size = defaultAvatarSize);
QImage fallbackAvatar(const std::string& alias,
                      const std::string& uri,
                      const QSize& size = defaultAvatarSize);
QByteArray QImageToByteArray(QImage image);
QString byteArrayToBase64String(QByteArray byteArray);
QByteArray base64StringToByteArray(QString base64);
QByteArray QByteArrayFromFile(const QString& filename);
QPixmap generateTintedPixmap(const QString& filename, QColor color);
QPixmap generateTintedPixmap(const QPixmap& pix, QColor color);
QImage scaleAndFrame(const QImage photo, const QSize& size = defaultAvatarSize);
QImage cropImage(const QImage& img);
QPixmap pixmapFromSvg(const QString& svg_resource, const QSize& size);
QImage getQRCodeImage(QString data, int margin);
bool isImage(const QString& fileExt);
QString generateUid();

// Misc
QString humanFileSize(qint64 fileSize);
QString getDebugFilePath();
} // namespace Utils
