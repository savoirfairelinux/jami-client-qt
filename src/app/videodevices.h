/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

#include "lrcinstance.h"
#include "qtutils.h"

#include "api/devicemodel.h"

#include <QObject>

class VideoDevices;

class VideoInputDeviceModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Role { DeviceName = Qt::UserRole + 1, DeviceId };
    Q_ENUM(Role)

    explicit VideoInputDeviceModel(LRCInstance* lrcInstance, VideoDevices* videoDeviceInstance);
    ~VideoInputDeviceModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset()
    {
        beginResetModel();
        endResetModel();
    }

    // Get model index of the current device
    Q_INVOKABLE int getCurrentIndex() const;

private:
    LRCInstance* lrcInstance_ {nullptr};
    VideoDevices* const videoDevices_;
};

class VideoFormatResolutionModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Role { Resolution = Qt::UserRole + 1 };
    Q_ENUM(Role)

    explicit VideoFormatResolutionModel(LRCInstance* lrcInstance, VideoDevices* videoDeviceInstance);
    ~VideoFormatResolutionModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset()
    {
        beginResetModel();
        endResetModel();
    }

    // Get model index of the current device
    Q_INVOKABLE int getCurrentIndex() const;

private:
    LRCInstance* lrcInstance_ {nullptr};
    VideoDevices* const videoDevices_;
};

class VideoFormatFpsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role { FPS = Qt::UserRole + 1, FPS_Float };
    Q_ENUM(Role)

    explicit VideoFormatFpsModel(LRCInstance* lrcInstance, VideoDevices* videoDeviceInstance);
    ~VideoFormatFpsModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset()
    {
        beginResetModel();
        endResetModel();
    }

    // Get model index of the current device
    Q_INVOKABLE int getCurrentIndex() const;

private:
    LRCInstance* lrcInstance_;
    VideoDevices* const videoDevices_;
};

class VideoDevices : public QObject
{
    Q_OBJECT
    QML_RO_PROPERTY(int, listSize)

    QML_RO_PROPERTY(QString, defaultChannel)
    QML_RO_PROPERTY(QString, defaultId)
    QML_RO_PROPERTY(QString, defaultName)
    QML_RO_PROPERTY(QString, defaultRes)
    QML_RO_PROPERTY(int, defaultFps)
    QML_PROPERTY(int, screenSharingDefaultFps)

    QML_RO_PROPERTY(QVariant, deviceSourceModel)
    QML_RO_PROPERTY(QVariant, resSourceModel)
    QML_RO_PROPERTY(QVariant, fpsSourceModel)
    QML_RO_PROPERTY(QVariant, sharingFpsSourceModel)

public:
    explicit VideoDevices(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~VideoDevices() = default;

    Q_INVOKABLE void setDefaultDevice(int index);
    Q_INVOKABLE const QString getDefaultDevice();
    Q_INVOKABLE QString startDevice(const QString& deviceId, bool force = false);
    Q_INVOKABLE void stopDevice(const QString& deviceId);
    Q_INVOKABLE void setDefaultDeviceRes(int index);
    Q_INVOKABLE void setDefaultDeviceFps(int index);
    Q_INVOKABLE void setDisplayFPS(const QString& fps);

    const lrc::api::video::ResRateList& get_defaultResRateList();
    void set_defaultResRateList(lrc::api::video::ResRateList resRateList);

    const lrc::api::video::FrameratesList& get_defaultFpsList();
    void set_defaultFpsList(lrc::api::video::FrameratesList rateList);

Q_SIGNALS:
    void deviceAvailable();
    void deviceListChanged(int inputs);

private Q_SLOTS:
    void onVideoDeviceEvent();

private:
    // Used to classify capture device events.
    enum class DeviceEvent { FirstDevice, Added, Removed, None };

    void updateData();

    LRCInstance* lrcInstance_;

    VideoInputDeviceModel* deviceListModel_;
    VideoFormatResolutionModel* resListModel_;
    VideoFormatFpsModel* fpsListModel_;

    lrc::api::video::ResRateList defaultResRateList_;
    lrc::api::video::FrameratesList defaultFpsList_;
    lrc::api::video::FrameratesList sharingFpsListModel_;

    constexpr static const char DEVICE_DESKTOP[] = "desktop";
    constexpr static const char CHANNEL_DEFAULT[] = "default";

    bool deviceOpen_ {false};
};
