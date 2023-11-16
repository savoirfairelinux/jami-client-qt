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

#include "videodevices.h"

#include "api/devicemodel.h"

VideoInputDeviceModel::VideoInputDeviceModel(LRCInstance* lrcInstance,
                                             VideoDevices* videoDeviceInstance)
    : QAbstractListModel(videoDeviceInstance)
    , lrcInstance_(lrcInstance)
    , videoDevices_(videoDeviceInstance)
{}

VideoInputDeviceModel::~VideoInputDeviceModel() {}

int
VideoInputDeviceModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return videoDevices_->get_listSize();
    }
    return 0;
}

QVariant
VideoInputDeviceModel::data(const QModelIndex& index, int role) const
{
    auto deviceList = lrcInstance_->avModel().getDevices();
    if (!index.isValid() || deviceList.size() == 0 || index.row() >= deviceList.size()) {
        return QVariant();
    }

    auto currentDeviceSetting = lrcInstance_->avModel().getDeviceSettings(deviceList[index.row()]);

    switch (role) {
    case Role::DeviceName:
        return QVariant(currentDeviceSetting.name);
    case Role::DeviceId:
        return QVariant(currentDeviceSetting.id);
    }
    return QVariant();
}

QHash<int, QByteArray>
VideoInputDeviceModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[DeviceName] = "DeviceName";
    roles[DeviceId] = "DeviceId";
    return roles;
}

int
VideoInputDeviceModel::getCurrentIndex() const
{
    QString currentId = videoDevices_->get_defaultId();
    auto resultList = match(index(0, 0), DeviceId, QVariant(currentId));
    return resultList.size() > 0 ? resultList[0].row() : 0;
}

// VideoFormatResolutionModel
VideoFormatResolutionModel::VideoFormatResolutionModel(LRCInstance* lrcInstance,
                                                       VideoDevices* videoDeviceInstance)
    : QAbstractListModel(videoDeviceInstance)
    , lrcInstance_(lrcInstance)
    , videoDevices_(videoDeviceInstance)
{}

VideoFormatResolutionModel::~VideoFormatResolutionModel() {}

int
VideoFormatResolutionModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return videoDevices_->get_defaultResRateList().size();
    }
    return 0;
}

QVariant
VideoFormatResolutionModel::data(const QModelIndex& index, int role) const
{
    auto& channelCaps = videoDevices_->get_defaultResRateList();
    if (!index.isValid() || channelCaps.size() <= index.row() || channelCaps.size() == 0) {
        return QVariant();
    }

    switch (role) {
    case Role::Resolution:
        return QVariant(channelCaps.at(index.row()).first);
    }

    return QVariant();
}

QHash<int, QByteArray>
VideoFormatResolutionModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[Resolution] = "Resolution";
    return roles;
}

int
VideoFormatResolutionModel::getCurrentIndex() const
{
    QString currentResolution = videoDevices_->get_defaultRes();
    auto resultList = match(index(0, 0), Resolution, QVariant(currentResolution));
    return resultList.size() > 0 ? resultList[0].row() : 0;
}

VideoFormatFpsModel::VideoFormatFpsModel(LRCInstance* lrcInstance, VideoDevices* videoDeviceInstance)
    : QAbstractListModel(videoDeviceInstance)
    , lrcInstance_(lrcInstance)
    , videoDevices_(videoDeviceInstance)
{}

VideoFormatFpsModel::~VideoFormatFpsModel() {}

int
VideoFormatFpsModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return videoDevices_->get_defaultFpsList().size();
    }
    return 0;
}

QVariant
VideoFormatFpsModel::data(const QModelIndex& index, int role) const
{
    auto& fpsList = videoDevices_->get_defaultFpsList();
    if (!index.isValid() || fpsList.size() == 0 || index.row() >= fpsList.size()) {
        return QVariant();
    }

    switch (role) {
    case Role::FPS:
        return QVariant(static_cast<int>(fpsList[index.row()]));
    case Role::FPS_Float:
        return QVariant(fpsList[index.row()]);
    }

    return QVariant();
}

QHash<int, QByteArray>
VideoFormatFpsModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[FPS] = "FPS";
    roles[FPS_Float] = "FPS_Float";
    return roles;
}

int
VideoFormatFpsModel::getCurrentIndex() const
{
    float currentFps = videoDevices_->get_defaultFps();
    auto resultList = match(index(0, 0), FPS, QVariant(currentFps));
    return resultList.size() > 0 ? resultList[0].row() : 0;
}

VideoDevices::VideoDevices(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
    deviceListModel_ = new VideoInputDeviceModel(lrcInstance, this);
    resListModel_ = new VideoFormatResolutionModel(lrcInstance, this);
    fpsListModel_ = new VideoFormatFpsModel(lrcInstance, this);

    connect(&lrcInstance_->avModel(),
            &lrc::api::AVModel::deviceEvent,
            this,
            &VideoDevices::onVideoDeviceEvent);

    auto displaySettings = lrcInstance_->avModel().getDeviceSettings(DEVICE_DESKTOP);

    auto desktopFpsSource = lrcInstance_->avModel().getDeviceCapabilities(DEVICE_DESKTOP);
    if (desktopFpsSource.contains(CHANNEL_DEFAULT) && !desktopFpsSource[CHANNEL_DEFAULT].empty()) {
        sharingFpsListModel_ = desktopFpsSource[CHANNEL_DEFAULT][0].second;
        if (sharingFpsListModel_.indexOf(displaySettings.rate) >= 0)
            set_screenSharingDefaultFps(displaySettings.rate);
    }
    updateData();
}

void
VideoDevices::setDefaultDevice(int index)
{
    if (!listSize_) {
        return;
    }

    QString deviceId {};
    auto callId = lrcInstance_->getCurrentCallId();

    deviceId = deviceListModel_
                   ->data(deviceListModel_->index(index, 0), VideoInputDeviceModel::DeviceId)
                   .toString();

    lrcInstance_->avModel().setDefaultDevice(deviceId);

    if (!callId.isEmpty())
        lrcInstance_->getCurrentCallModel()->replaceDefaultCamera(callId, deviceId);

    updateData();
}

const QString
VideoDevices::getDefaultDevice()
{
    auto idx = deviceListModel_->getCurrentIndex();
    auto rendererId = QString("camera://")
                      + deviceListModel_
                            ->data(deviceListModel_->index(idx, 0), VideoInputDeviceModel::DeviceId)
                            .toString();
    return rendererId;
}

QString
VideoDevices::startDevice(const QString& id, bool force)
{
    if (id.isEmpty())
        return {};
    auto& avModel = lrcInstance_->avModel();
    if (avModel.hasRenderer(id)) {
        // If the device is already started AND we're NOT trying to
        // force a format change, we can do nothing and return the
        // renderer id.
        if (!force) {
            return id;
        }
        avModel.stopPreview(id);
    }
    deviceOpen_ = true;
    return avModel.startPreview(id);
}

void
VideoDevices::stopDevice(const QString& id)
{
    if (!id.isEmpty()) {
        lrcInstance_->avModel().stopPreview(id);
        deviceOpen_ = false;
    }
}

void
VideoDevices::setDefaultDeviceRes(int index)
{
    auto& channelCaps = get_defaultResRateList();
    auto settings = lrcInstance_->avModel().getDeviceSettings(get_defaultId());
    settings.size = resListModel_
                        ->data(resListModel_->index(index, 0),
                               VideoFormatResolutionModel::Resolution)
                        .toString();

    for (int i = 0; i < channelCaps.size(); i++) {
        if (channelCaps[i].first == settings.size) {
            settings.rate = channelCaps[i].second.at(0);
            lrcInstance_->avModel().setDeviceSettings(settings);
            break;
        }
    }

    updateData();
}

void
VideoDevices::setDefaultDeviceFps(int index)
{
    auto settings = lrcInstance_->avModel().getDeviceSettings(get_defaultId());
    settings.size = get_defaultRes();
    settings.rate = fpsListModel_
                        ->data(fpsListModel_->index(index, 0), VideoFormatFpsModel::FPS_Float)
                        .toFloat();

    lrcInstance_->avModel().setDeviceSettings(settings);

    updateData();
}

void
VideoDevices::setDisplayFPS(const QString& fps)
{
    auto settings = lrcInstance_->avModel().getDeviceSettings(DEVICE_DESKTOP);
    settings.id = DEVICE_DESKTOP;
    settings.rate = fps.toInt();
    lrcInstance_->avModel().setDeviceSettings(settings);
    set_screenSharingDefaultFps(fps.toInt());
}

void
VideoDevices::updateData()
{
    set_listSize(lrcInstance_->avModel().getDevices().size());

    if (get_listSize() != 0) {
        auto defaultDevice = lrcInstance_->avModel().getDefaultDevice();
        auto defaultDeviceSettings = lrcInstance_->avModel().getDeviceSettings(defaultDevice);
        auto defaultDeviceCap = lrcInstance_->avModel().getDeviceCapabilities(defaultDevice);
        auto currentResRateList = defaultDeviceCap[defaultDeviceSettings.channel.isEmpty()
                                                       ? CHANNEL_DEFAULT
                                                       : defaultDeviceSettings.channel];
        lrc::api::video::FrameratesList fpsList;
        for (int i = 0; i < currentResRateList.size(); i++) {
            if (currentResRateList[i].first == defaultDeviceSettings.size) {
                fpsList = currentResRateList[i].second;
            }
        }

        set_defaultChannel(defaultDeviceSettings.channel);
        set_defaultId(defaultDeviceSettings.id);
        set_defaultName(defaultDeviceSettings.name);
        set_defaultRes(defaultDeviceSettings.size);
        set_defaultFps(defaultDeviceSettings.rate);
        set_defaultResRateList(currentResRateList);
        set_defaultFpsList(fpsList);
    } else {
        set_defaultChannel("");
        set_defaultId("");
        set_defaultName("");
        set_defaultRes("");
        set_defaultFps(0);
        set_defaultResRateList({});
        set_defaultFpsList({});
    }

    deviceListModel_->reset();
    resListModel_->reset();
    fpsListModel_->reset();

    set_deviceSourceModel(QVariant::fromValue(deviceListModel_));
    set_resSourceModel(QVariant::fromValue(resListModel_));
    set_fpsSourceModel(QVariant::fromValue(fpsListModel_));
    set_sharingFpsSourceModel(QVariant::fromValue(sharingFpsListModel_.toList()));
}

void
VideoDevices::onVideoDeviceEvent()
{
    auto& avModel = lrcInstance_->avModel();
    QString callId = lrcInstance_->getCurrentCallId();

    // Decide whether a device has plugged, unplugged, or nothing has changed.
    auto deviceList = avModel.getDevices();
    auto currentDeviceListSize = deviceList.size();
    auto previousDeviceListSize = get_listSize();

    DeviceEvent deviceEvent {DeviceEvent::None};
    if (currentDeviceListSize > previousDeviceListSize) {
        if (previousDeviceListSize == 0)
            deviceEvent = DeviceEvent::FirstDevice;
        else
            deviceEvent = DeviceEvent::Added;
    } else if (currentDeviceListSize < previousDeviceListSize) {
        deviceEvent = DeviceEvent::Removed;
    }

    if (deviceEvent == DeviceEvent::Added) {
        updateData();
        Q_EMIT deviceListChanged(currentDeviceListSize);
    } else if (deviceEvent == DeviceEvent::FirstDevice) {
        updateData();

        if (callId.isEmpty())
            Q_EMIT deviceAvailable();

        Q_EMIT deviceListChanged(currentDeviceListSize);
    } else if (deviceOpen_) {
        updateData();
    }
}

const lrc::api::video::ResRateList&
VideoDevices::get_defaultResRateList()
{
    return defaultResRateList_;
}

void
VideoDevices::set_defaultResRateList(lrc::api::video::ResRateList resRateList)
{
    defaultResRateList_.swap(resRateList);
}

const lrc::api::video::FrameratesList&
VideoDevices::get_defaultFpsList()
{
    return defaultFpsList_;
}

void
VideoDevices::set_defaultFpsList(lrc::api::video::FrameratesList rateList)
{
    defaultFpsList_.swap(rateList);
}
