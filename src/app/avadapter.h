/*!
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
#include "lrcinstance.h"

#include <QObject>
#include <QVariant>
#include <QString>
#include <qtutils.h>

#include "rendererinformationlistmodel.h"

class AvAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    // TODO: currentRenderingDeviceType is only used in QML to check if
    // we're sharing or not, so it should maybe just be a boolean.
    QML_RO_PROPERTY(lrc::api::video::DeviceType, currentRenderingDeviceType)
    QML_RO_PROPERTY(QString, currentRenderingDeviceId)
    QML_PROPERTY(bool, muteCamera)
    QML_RO_PROPERTY(QStringList, windowsNames)
    QML_RO_PROPERTY(QList<QVariant>, windowsIds)
    QML_RO_PROPERTY(QVariant, renderersInfoList)

public:
    explicit AvAdapter(LRCInstance* instance, QObject* parent = nullptr);
    ~AvAdapter() = default;

Q_SIGNALS:
    void screenCaptured(int screenNumber, QString source);
    // TODO: move to future audio device class
    void audioDeviceListChanged(int inputs, int outputs);

protected:
    void safeInit() override {};

    /**
     * Check if user is sharing a media
     */
    Q_INVOKABLE bool isSharing() const;

    /**
     * Check if user is showing a camera
     */
    Q_INVOKABLE bool isCapturing() const;

    /**
     * Check if user has a camera (even muted)
     */
    Q_INVOKABLE bool hasCamera() const;

    // Share the screen specificed by screen number.
    Q_INVOKABLE void shareEntireScreen(int screenNumber);

    // Share the all screens connected.
    Q_INVOKABLE void shareAllScreens();

    // Take snap shot of the screen and return emitting signal.
    Q_INVOKABLE void captureScreen(int screenNumber);

    // Take snap shot of the all screens and return by emitting signal.
    Q_INVOKABLE void captureAllScreens();

    // Share a media file.
    Q_INVOKABLE void shareFile(const QString& filePath);

    // Select screen area to display (from all screens).
    Q_INVOKABLE void shareScreenArea(unsigned x, unsigned y, unsigned width, unsigned height);

    // Select window to display.
    Q_INVOKABLE void shareWindow(const QString& windowId);

    // Returns the screensharing resource
    Q_INVOKABLE QString getSharingResource(int screenId, const QString& key);

    Q_INVOKABLE void getListWindows();

    // Stop sharing the screen or file
    Q_INVOKABLE void stopSharing();

    Q_INVOKABLE void startAudioMeter();
    Q_INVOKABLE void stopAudioMeter();

    Q_INVOKABLE void setDeviceName(const QString& deviceName);

    Q_INVOKABLE void enableCodec(unsigned int id, bool isToEnable);
    Q_INVOKABLE void increaseCodecPriority(unsigned int id, bool isVideo);
    Q_INVOKABLE void decreaseCodecPriority(unsigned int id, bool isVideo);

    Q_INVOKABLE void resetRendererInfo();
    Q_INVOKABLE void setRendererInfo();

    // TODO: to be removed
    Q_INVOKABLE bool getHardwareAcceleration();
    Q_INVOKABLE void setHardwareAcceleration(bool accelerate);

private Q_SLOTS:
    void updateRenderersFPSInfo(QPair<QString, QString> fpsInfo);
    void onAudioDeviceEvent();
    void onRendererStarted(const QString& id, const QSize& size);
    void onRendererStopped(const QString& id);

private:
    // Get screens arrangement rect relative to primary screen.
    const QRect getAllScreensBoundingRect();

    // Get the screen number
    int getScreenNumber(int screenId = 0) const;

    std::unique_ptr<RendererInformationListModel> rendererInformationListModel_;
};
