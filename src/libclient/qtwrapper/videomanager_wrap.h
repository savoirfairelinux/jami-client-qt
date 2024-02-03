/******************************************************************************
 *    Copyright (C) 2014-2024 Savoir-faire Linux Inc.                         *
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
#pragma once

// libstdc++
#include <functional>

// Qt
#include <QtCore/QObject>
#include <QtCore/QCoreApplication>
#include <QtCore/QByteArray>
#include <QtCore/QThread>
#include <QtCore/QList>
#include <QtCore/QMap>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QVariant>
#include <QtCore/QTimer>

// Ring
#include <videomanager_interface.h>

#include "typedefs.h"
#include "conversions_wrap.hpp"

class VideoManagerInterface : public QObject
{
    Q_OBJECT

    friend class VideoManagerSignalProxy;

public:
    VideoManagerInterface();
    ~VideoManagerInterface();

#ifdef ENABLE_VIDEO
    std::map<std::string, std::shared_ptr<libjami::CallbackWrapperBase>> videoHandlers;
#endif

public Q_SLOTS: // METHODS
    void applySettings(const QString& name, MapStringString settings)
    {
#ifdef ENABLE_VIDEO
        libjami::applySettings(name.toStdString(), convertMap(settings));
#else
        Q_UNUSED(name)
        Q_UNUSED(settings)
#endif
    }

    MapStringMapStringVectorString getCapabilities(const QString& name)
    {
        MapStringMapStringVectorString ret;
#ifdef ENABLE_VIDEO
        std::map<std::string, std::map<std::string, std::vector<std::string>>> temp;
        temp = libjami::getCapabilities(name.toStdString());

        for (auto& x : temp) {
            QMap<QString, VectorString> ytemp;
            for (auto& y : x.second) {
                ytemp[QString(y.first.c_str())] = convertVectorString(y.second);
            }
            ret[QString(x.first.c_str())] = ytemp;
        }
#else
        Q_UNUSED(name)
#endif
        return ret;
    }

    QString getDefaultDevice()
    {
#ifdef ENABLE_VIDEO
        return QString::fromStdString(libjami::getDefaultDevice().c_str());
#else
        return QString();
#endif
    }

    QStringList getDeviceList()
    {
#ifdef ENABLE_VIDEO
        QStringList temp = convertStringList(libjami::getDeviceList());
#else
        QStringList temp;
#endif
        return temp;
    }

    MapStringString getSettings(const QString& device)
    {
#ifdef ENABLE_VIDEO
        MapStringString temp = convertMap(libjami::getSettings(device.toStdString()));
#else
        Q_UNUSED(device)
        MapStringString temp;
#endif
        return temp;
    }

    void setDefaultDevice(const QString& name)
    {
#ifdef ENABLE_VIDEO
        libjami::setDefaultDevice(name.toStdString());
#else
        Q_UNUSED(name)
#endif
    }

    QString openVideoInput(const QString& resource)
    {
#ifdef ENABLE_VIDEO
        return libjami::openVideoInput(resource.toLatin1().toStdString()).c_str();
#endif
    }

    bool closeVideoInput(const QString& resource)
    {
#ifdef ENABLE_VIDEO
        return libjami::closeVideoInput(resource.toLatin1().toStdString());
#endif
    }

    void startAudioDevice()
    {
        libjami::startAudioDevice();
    }

    void stopAudioDevice()
    {
        libjami::stopAudioDevice();
    }

    bool registerSinkTarget(const QString& sinkID, const libjami::SinkTarget& target)
    {
#ifdef ENABLE_VIDEO
        return libjami::registerSinkTarget(sinkID.toStdString(), target);
#else
        Q_UNUSED(sinkID)
        Q_UNUSED(target)
        return false;
#endif
    }

    bool getDecodingAccelerated()
    {
        return libjami::getDecodingAccelerated();
    }

    void setDecodingAccelerated(bool state)
    {
        libjami::setDecodingAccelerated(state);
    }

    bool getEncodingAccelerated()
    {
        return libjami::getEncodingAccelerated();
    }

    void setEncodingAccelerated(bool state)
    {
        libjami::setEncodingAccelerated(state);
    }

    void stopLocalRecorder(const QString& path)
    {
        libjami::stopLocalRecorder(path.toStdString());
    }

    QString startLocalMediaRecorder(const QString& videoInputId, const QString& path)
    {
        return QString::fromStdString(
            libjami::startLocalMediaRecorder(videoInputId.toStdString(), path.toStdString()));
    }

    MapStringString getRenderer(const QString& id)
    {
        return convertMap(libjami::getRenderer(id.toStdString()));
    }

    QString createMediaPlayer(const QString& path)
    {
        return QString::fromStdString(libjami::createMediaPlayer(path.toStdString()));
    }

    bool closeMediaPlayer(const QString& id)
    {
        return libjami::closeMediaPlayer(id.toStdString());
    }

    bool pausePlayer(const QString& id, bool pause)
    {
        return libjami::pausePlayer(id.toStdString(), pause);
    }

    bool mutePlayerAudio(const QString& id, bool mute)
    {
        return libjami::mutePlayerAudio(id.toStdString(), mute);
    }

    bool playerSeekToTime(const QString& id, int time)
    {
        return libjami::playerSeekToTime(id.toStdString(), time);
    }

    qint64 getPlayerPosition(const QString& id)
    {
        return libjami::getPlayerPosition(id.toStdString());
    }

    qint64 getPlayerDuration(const QString& id)
    {
        return libjami::getPlayerDuration(id.toStdString());
    }

    void setAutoRestart(const QString& id, bool restart)
    {
        libjami::setAutoRestart(id.toStdString(), restart);
    }

Q_SIGNALS: // SIGNALS
    void deviceEvent();
    void decodingStarted(
        const QString& id, const QString& shmPath, int width, int height, bool isMixer);
    void decodingStopped(const QString& id, const QString& shmPath, bool isMixer);
    void fileOpened(const QString& path, const MapStringString& info);
};

namespace org {
namespace ring {
namespace Ring {
typedef ::VideoManagerInterface VideoManager;
}
} // namespace ring
} // namespace org
