/*!
 * Copyright (C) 2020 by Savoir-faire Linux
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

#include "currentdevice.h"

// VideoInputDeviceModel
VideoInputDeviceModel::VideoInputDeviceModel(LRCInstance* lrcInstance, CurrentDevice* currentDevice)
    : QAbstractListModel(currentDevice)
    , lrcInstance_(lrcInstance)
    , currentDevice_(currentDevice)
{}

VideoInputDeviceModel::~VideoInputDeviceModel() {}

int
VideoInputDeviceModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return currentDevice_->get_videoDeviceListSize();
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
    QString currentId = currentDevice_->get_videoDefaultDeviceId();
    auto resultList = match(index(0, 0), DeviceId, QVariant(currentId));
    return resultList.size() > 0 ? resultList[0].row() : 0;
}

// VideoFormatResolutionModel
VideoFormatResolutionModel::VideoFormatResolutionModel(LRCInstance* lrcInstance,
                                                       CurrentDevice* currentDevice)
    : QAbstractListModel(currentDevice)
    , lrcInstance_(lrcInstance)
    , currentDevice_(currentDevice)
{}

VideoFormatResolutionModel::~VideoFormatResolutionModel() {}

int
VideoFormatResolutionModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return currentDevice_->get_videoDefaultDeviceCurrentResRateList().size();
    }
    return 0;
}

QVariant
VideoFormatResolutionModel::data(const QModelIndex& index, int role) const
{
    auto& channelCaps = currentDevice_->get_videoDefaultDeviceCurrentResRateList();
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
    QString currentDeviceId = currentDevice_->get_videoDefaultDeviceId();
    QString currentResolution = currentDevice_->get_videoDefaultDeviceRes();
    auto resultList = match(index(0, 0), Resolution, QVariant(currentResolution));

    return resultList.size() > 0 ? resultList[0].row() : 0;
}

// VideoFormatFpsModel
VideoFormatFpsModel::VideoFormatFpsModel(LRCInstance* lrcInstance, CurrentDevice* currentDevice)
    : QAbstractListModel(currentDevice)
    , lrcInstance_(lrcInstance)
    , currentDevice_(currentDevice)
{}

VideoFormatFpsModel::~VideoFormatFpsModel() {}

int
VideoFormatFpsModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return currentDevice_->get_videoDefaultDeviceCurrentFpsList().size();
    }
    return 0;
}

QVariant
VideoFormatFpsModel::data(const QModelIndex& index, int role) const
{
    auto& fpsList = currentDevice_->get_videoDefaultDeviceCurrentFpsList();
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
    QString currentDeviceId = currentDevice_->get_videoDefaultDeviceId();
    float currentFps = currentDevice_->get_videoDefaultDeviceFps();
    auto resultList = match(index(0, 0), FPS, QVariant(currentFps));

    return resultList.size() > 0 ? resultList[0].row() : 0;
}

// CurrentDevice
CurrentDevice::CurrentDevice(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
    , videoDeviceFilterModel_(new CurrentItemFilterModel(this))
    , videoResFilterModel_(new CurrentItemFilterModel(this))
    , videoFpsFilterModel_(new CurrentItemFilterModel(this))
{
    videoDeviceSourceModel_ = new VideoInputDeviceModel(lrcInstance, this);
    videoResSourceModel_ = new VideoFormatResolutionModel(lrcInstance, this);
    videoFpsSourceModel_ = new VideoFormatFpsModel(lrcInstance, this);

    videoDeviceFilterModel_->setSourceModel(videoDeviceSourceModel_);
    videoResFilterModel_->setSourceModel(videoResSourceModel_);
    videoFpsFilterModel_->setSourceModel(videoFpsSourceModel_);

    videoDeviceFilterModel_->setFilterRole(VideoInputDeviceModel::DeviceName);
    videoResFilterModel_->setFilterRole(VideoFormatResolutionModel::Resolution);
    videoFpsFilterModel_->setFilterRole(VideoFormatFpsModel::FPS);

    connect(lrcInstance_->renderer(), &RenderManager::previewFrameStarted, [this]() {
        // TODO: listen to the correct signals that are needed to be added in daemon or lrc
        auto callId = lrcInstance_->getCurrentCallId();
        if (!callId.isEmpty())
            set_currentRenderingDeviceType(
                lrcInstance_->avModel().getCurrentRenderedDevice(callId).type);
    });

    connect(&lrcInstance_->avModel(),
            &AVModel::defaultVideoDeviceChanged,
            [this](const QString& id) {
                Q_UNUSED(id)
                updateData();
            });

    connect(&lrcInstance_->avModel(),
            &AVModel::videoDeviceSettingsChanged,
            [this](const QString& id) {
                if (get_videoDefaultDeviceId() == id)
                    updateData();
            });

    connect(&lrcInstance_->avModel(),
            &lrc::api::AVModel::audioDeviceEvent,
            this,
            &CurrentDevice::onAudioDeviceEvent);

    connect(&lrcInstance_->avModel(),
            &lrc::api::AVModel::deviceEvent,
            this,
            &CurrentDevice::onVideoDeviceEvent);

    updateData();
}

CurrentDevice::~CurrentDevice() {}

QVariant
CurrentDevice::videoDeviceFilterModel()
{
    return QVariant::fromValue(videoDeviceFilterModel_);
}

QVariant
CurrentDevice::videoDeviceSourceModel()
{
    return QVariant::fromValue(videoDeviceSourceModel_);
}

QVariant
CurrentDevice::videoResFilterModel()
{
    return QVariant::fromValue(videoResFilterModel_);
}

QVariant
CurrentDevice::videoResSourceModel()
{
    return QVariant::fromValue(videoResSourceModel_);
}

QVariant
CurrentDevice::videoFpsFilterModel()
{
    return QVariant::fromValue(videoFpsFilterModel_);
}

QVariant
CurrentDevice::videoFpsSourceModel()
{
    return QVariant::fromValue(videoFpsSourceModel_);
}

void
CurrentDevice::setVideoDefaultDevice(int index, bool useSourceModel)
{
    QString deviceId {};
    auto callId = lrcInstance_->getCurrentCallId();

    if (useSourceModel)
        deviceId = videoDeviceSourceModel_
                       ->data(videoDeviceSourceModel_->index(index, 0),
                              VideoInputDeviceModel::DeviceId)
                       .toString();
    else
        deviceId = videoDeviceFilterModel_
                       ->data(videoDeviceFilterModel_->index(index, 0),
                              VideoInputDeviceModel::DeviceId)
                       .toString();

    lrcInstance_->avModel().setDefaultDevice(deviceId);

    if (!callId.isEmpty())
        lrcInstance_->avModel().switchInputTo(deviceId, callId);
}

void
CurrentDevice::setVideoDefaultDeviceRes(int index)
{
    auto& channelCaps = get_videoDefaultDeviceCurrentResRateList();
    auto settings = lrcInstance_->avModel().getDeviceSettings(get_videoDefaultDeviceId());
    settings.size = videoResFilterModel_
                        ->data(videoResFilterModel_->index(index, 0),
                               VideoFormatResolutionModel::Resolution)
                        .toString();

    for (int i = 0; i < channelCaps.size(); i++) {
        if (channelCaps[i].first == settings.size) {
            settings.rate = channelCaps[i].second.at(0);
            lrcInstance_->avModel().setDeviceSettings(settings);
            return;
        }
    }
}

void
CurrentDevice::setVideoDefaultDeviceFps(int index)
{
    auto settings = lrcInstance_->avModel().getDeviceSettings(get_videoDefaultDeviceId());
    settings.size = get_videoDefaultDeviceRes();
    settings.rate = videoFpsFilterModel_
                        ->data(videoFpsFilterModel_->index(index, 0), VideoFormatFpsModel::FPS_Float)
                        .toFloat();

    lrcInstance_->avModel().setDeviceSettings(settings);
}

void
CurrentDevice::updateData()
{
    set_videoDeviceListSize(lrcInstance_->avModel().getDevices().size());

    if (get_videoDeviceListSize() != 0) {
        auto defaultDevice = lrcInstance_->avModel().getDefaultDevice();
        auto defaultDeviceSettings = lrcInstance_->avModel().getDeviceSettings(defaultDevice);
        auto defaultDeviceCap = lrcInstance_->avModel().getDeviceCapabilities(defaultDevice);
        auto currentResRateList = defaultDeviceCap[defaultDeviceSettings.channel.isEmpty()
                                                       ? "default"
                                                       : defaultDeviceSettings.channel];
        lrc::api::video::FrameratesList fpsList;

        for (int i = 0; i < currentResRateList.size(); i++) {
            if (currentResRateList[i].first == defaultDeviceSettings.size) {
                fpsList = currentResRateList[i].second;
            }
        }

        set_videoDefaultDeviceChannel(defaultDeviceSettings.channel);
        set_videoDefaultDeviceId(defaultDeviceSettings.id);
        set_videoDefaultDeviceName(defaultDeviceSettings.name);
        set_videoDefaultDeviceRes(defaultDeviceSettings.size);
        set_videoDefaultDeviceFps(defaultDeviceSettings.rate);
        set_videoDefaultDeviceCurrentResRateList(currentResRateList);
        set_videoDefaultDeviceCurrentFpsList(fpsList);

        videoDeviceFilterModel_->setCurrentItemFilter(defaultDeviceSettings.name);
        videoResFilterModel_->setCurrentItemFilter(defaultDeviceSettings.size);
        videoFpsFilterModel_->setCurrentItemFilter(static_cast<int>(defaultDeviceSettings.rate));
    } else {
        set_videoDefaultDeviceChannel("");
        set_videoDefaultDeviceId("");
        set_videoDefaultDeviceName("");
        set_videoDefaultDeviceRes("");
        set_videoDefaultDeviceFps(0);
        set_videoDefaultDeviceCurrentResRateList({});
        set_videoDefaultDeviceCurrentFpsList({});

        videoDeviceFilterModel_->setCurrentItemFilter("");
        videoResFilterModel_->setCurrentItemFilter("");
        videoFpsFilterModel_->setCurrentItemFilter(0);
    }

    videoDeviceSourceModel_->reset();
    videoResSourceModel_->reset();
    videoFpsSourceModel_->reset();
}

void
CurrentDevice::onAudioDeviceEvent()
{
    auto& avModel = lrcInstance_->avModel();
    auto inputs = avModel.getAudioInputDevices().size();
    auto outputs = avModel.getAudioOutputDevices().size();
    Q_EMIT audioDeviceListChanged(inputs, outputs);
}

void
CurrentDevice::onVideoDeviceEvent()
{
    auto& avModel = lrcInstance_->avModel();
    auto defaultDevice = avModel.getDefaultDevice();
    QString callId = lrcInstance_->getCurrentCallId();

    // Decide whether a device has plugged, unplugged, or nothing has changed.
    auto deviceList = avModel.getDevices();
    auto currentDeviceListSize = deviceList.size();
    auto previousDeviceListSize = get_videoDeviceListSize();

    DeviceEvent deviceEvent {DeviceEvent::None};
    if (currentDeviceListSize > previousDeviceListSize) {
        if (previousDeviceListSize == 0)
            deviceEvent = DeviceEvent::FirstDevice;
        else
            deviceEvent = DeviceEvent::Added;
    } else if (currentDeviceListSize < previousDeviceListSize) {
        deviceEvent = DeviceEvent::Removed;
    }

    auto cb = [this, currentDeviceListSize, deviceEvent, defaultDevice, callId] {
        auto& avModel = lrcInstance_->avModel();
        if (currentDeviceListSize == 0) {
            avModel.switchInputTo({}, callId);
            avModel.stopPreview();
        } else if (deviceEvent == DeviceEvent::Removed) {
            avModel.switchInputTo(defaultDevice, callId);
        }

        updateData();
        Q_EMIT videoDeviceListChanged(currentDeviceListSize);
    };

    if (deviceEvent == DeviceEvent::Added) {
        updateData();
        Q_EMIT videoDeviceListChanged(currentDeviceListSize);
    } else if (deviceEvent == DeviceEvent::FirstDevice) {
        updateData();

        if (callId.isEmpty()) {
            Q_EMIT videoDeviceAvailable();
        } else {
            avModel.switchInputTo(defaultDevice, callId);
        }

        Q_EMIT videoDeviceListChanged(currentDeviceListSize);
    } else if (lrcInstance_->renderer()->isPreviewing()) {
        // Use QueuedConnection to make sure that it happens at the event loop of current device
        Utils::oneShotConnect(
            lrcInstance_->renderer(),
            &RenderManager::previewRenderingStopped,
            this,
            [cb] { cb(); },
            Qt::QueuedConnection);
    } else {
        cb();
    }
}

const lrc::api::video::ResRateList&
CurrentDevice::get_videoDefaultDeviceCurrentResRateList()
{
    return videoDefaultDeviceCurrentResRateList_;
}

void
CurrentDevice::set_videoDefaultDeviceCurrentResRateList(lrc::api::video::ResRateList resRateList)
{
    videoDefaultDeviceCurrentResRateList_.swap(resRateList);
}

const lrc::api::video::FrameratesList&
CurrentDevice::get_videoDefaultDeviceCurrentFpsList()
{
    return videoDefaultDeviceCurrentFpsList_;
}

void
CurrentDevice::set_videoDefaultDeviceCurrentFpsList(lrc::api::video::FrameratesList rateList)
{
    videoDefaultDeviceCurrentFpsList_.swap(rateList);
}
