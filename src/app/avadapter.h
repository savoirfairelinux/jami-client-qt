/*!
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
#include "qtutils.h"
#include "rendererinformationlistmodel.h"

#include <QObject>
#include <QVariant>
#include <QString>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class AvAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_SINGLETON

    QML_PROPERTY(bool, muteCamera)
    QML_RO_PROPERTY(QStringList, windowsNames)
    QML_RO_PROPERTY(QList<QVariant>, windowsIds)
    QML_RO_PROPERTY(QVariant, renderersInfoList)

public:
    static AvAdapter* create(QQmlEngine*, QJSEngine*)
    {
        return new AvAdapter(qApp->property("LRCInstance").value<LRCInstance*>());
    }

    explicit AvAdapter(LRCInstance* instance, QObject* parent = nullptr);
    ~AvAdapter() = default;

Q_SIGNALS:
    void screenCaptured(int screenNumber, QString source);
    // TODO: move to future audio device class
    void audioDeviceListChanged(int inputs, int outputs);

protected:
    /**
     * Check if user is sharing a media
     */
    Q_INVOKABLE bool isSharing() const;

    /**
     * @return true if user has a video camera media that is not muted, false otherwise.
     */
    Q_INVOKABLE bool isCapturing() const;

    /**
     * Check if user has a camera (even muted)
     */
    Q_INVOKABLE bool hasCamera() const;

    // Share the screen specificed by screen number (all platforms except Wayland).
    Q_INVOKABLE void shareEntireScreen(int screenNumber);

#ifdef Q_OS_LINUX
    // Share a screen on Wayland.
    // Sharing a screen on Wayland requires getting permission from the user. The logic for
    // this is handled by the ScreenCastPortal class using xdg-desktop-portal.
    // The choice of screen is also handled by xdg-desktop-portal, which is why we don't need
    // an argument for it (whereas we do on other platforms, cf. shareEntireScreen above).
    Q_INVOKABLE void shareEntireScreenWayland();
#endif

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

    // Select window to display (all platforms except Wayland).
    Q_INVOKABLE void shareWindow(const QString& windowProcessId, const QString& windowId, const int fps = -1);

#ifdef Q_OS_LINUX
    // Share a window on Wayland.
    // Sharing a window on Wayland requires getting permission from the user. The logic for
    // this is handled by the ScreenCastPortal class using xdg-desktop-portal.
    // The choice of window is also handled by xdg-desktop-portal, which is why we don't need
    // arguments for it (whereas we do on other platforms, cf. shareWindow above).
    Q_INVOKABLE void shareWindowWayland();
#endif

    // Returns the screensharing resource
    Q_INVOKABLE QString getSharingResource(int screenId = -2,
                                           const QString& windowProcessId = "",
                                           const QString& key = "",
                                           const int fps = -1);

    Q_INVOKABLE void getListWindows();

    // Stop sharing the screen or file
    Q_INVOKABLE void stopSharing(const QString& source = {});

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
#ifdef Q_OS_LINUX
    // This function needs to be called whenever a screen/window share stops on Wayland.
    // Failure to do so can cause subsequent sharing attempts to fail.
    void closePortal(const QString& callId);

    // On Wayland, we need to be informed of call status changes so that we can call
    // closePortal if a call ends while a screen/window share was in progress.
    void onCallStatusChanged(const QString& accountId, const QString& callId);
#endif

private:
    // Get screens arrangement rect relative to primary screen.
    const QRect getAllScreensBoundingRect();

#ifdef Q_OS_LINUX
    // Used internally by shareEntireScreenWayland and shareWindowWayland
    void shareWayland(bool entireScreen);
#endif

    // Get the screen number
    int getScreenNumber(int screenId = 0) const;

    std::unique_ptr<RendererInformationListModel> rendererInformationListModel_;
};
