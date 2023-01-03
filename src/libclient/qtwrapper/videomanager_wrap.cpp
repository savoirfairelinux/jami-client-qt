/******************************************************************************
 *    Copyright (C) 2014-2022 Savoir-faire Linux Inc.                         *
 *   Author : Philippe Groarke <philippe.groarke@savoirfairelinux.com>        *
 *   Author : Alexandre Lision <alexandre.lision@savoirfairelinux.com>        *
 *                                                                            *
 *   This library is free software; you can redistribute it and/or            *
 *   modify it under the terms of the GNU Lesser General Public               *
 *   License as published by the Free Software Foundation; either             *
 *   version 2.1 of the License, or (at your option) any later version.       *
 *                                                                            *
 *   This library is distributed in the hope that it will be useful,          *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 *   Lesser General Public License for more details.                          *
 *                                                                            *
 *   You should have received a copy of the Lesser GNU General Public License *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.    *
 *****************************************************************************/
#include "videomanager_wrap.h"

VideoManagerInterface::VideoManagerInterface()
{
#ifdef ENABLE_VIDEO
    using libjami::exportable_callback;
    using libjami::VideoSignal;
    videoHandlers
        = {exportable_callback<VideoSignal::DeviceEvent>([this]() { Q_EMIT deviceEvent(); }),
           exportable_callback<VideoSignal::DecodingStarted>([this](const std::string& id,
                                                                    const std::string& shmPath,
                                                                    int width,
                                                                    int height,
                                                                    bool isMixer) {
               Q_EMIT decodingStarted(QString::fromLatin1(QByteArray::fromStdString(id)),
                                      QString::fromLatin1(QByteArray::fromStdString(shmPath)),
                                      width,
                                      height,
                                      isMixer);
           }),
           exportable_callback<VideoSignal::DecodingStopped>(
               [this](const std::string& id, const std::string& shmPath, bool isMixer) {
                   Q_EMIT decodingStopped(QString::fromLatin1(QByteArray::fromStdString(id)),
                                          QString::fromLatin1(QByteArray::fromStdString(shmPath)),
                                          isMixer);
               })};
#endif
}

VideoManagerInterface::~VideoManagerInterface() {}
