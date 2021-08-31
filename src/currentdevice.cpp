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

#include "lrcinstance.h"

#include "api/newdevicemodel.h"

VideoInputDeviceModel::VideoInputDeviceModel(LRCInstance* lrcInstance, QObject* parent)
    : QAbstractListModel(parent)
    , lrcInstance_(lrcInstance)
{}

VideoInputDeviceModel::~VideoInputDeviceModel() {}

int
VideoInputDeviceModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        return lrcInstance_->avModel().getDevices().size();
    }
    return 0;
}

QVariant
VideoInputDeviceModel::data(const QModelIndex& index, int role) const
{
    auto deviceList = lrcInstance_->avModel().getDevices();
    if (!index.isValid()) {
        return QVariant();
    }

    auto currentDeviceSetting = lrcInstance_->avModel().getDeviceSettings(deviceList[index.row()]);

    switch (role) {
    case Role::DeviceName:
        return QVariant(currentDeviceSetting.name);
    }
    return QVariant();
}

QHash<int, QByteArray>
VideoInputDeviceModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[DeviceName] = "DeviceName";
    return roles;
}

void
VideoInputDeviceModel::reset()
{
    beginResetModel();
    endResetModel();
}

VideoFormatResolutionModel::VideoFormatResolutionModel(LRCInstance* lrcInstance, QObject* parent)
    : QAbstractListModel(parent)
    , lrcInstance_(lrcInstance)
{}

VideoFormatFpsModel::VideoFormatFpsModel(LRCInstance* lrcInstance, QObject* parent)
    : QAbstractListModel(parent)
    , lrcInstance_(lrcInstance)
{}

CurrentDevice::CurrentDevice(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
    , videoDeviceFilterModel_(new CurrentItemFilterModel(this))
    , videoResFilterModel_(new CurrentItemFilterModel(this))
    , videoFpsFilterModel_(new CurrentItemFilterModel(this))
{
    auto videoDeviceModel = new VideoInputDeviceModel(lrcInstance, this);
    auto videoResModel = new VideoFormatResolutionModel(lrcInstance, this);
    auto videoFpsModel = new VideoFormatFpsModel(lrcInstance, this);

    videoDeviceFilterModel_->setSourceModel(videoDeviceModel);
    videoResFilterModel_->setSourceModel(videoResModel);
    videoFpsFilterModel_->setSourceModel(videoFpsModel);

    videoDeviceFilterModel_->setFilterRole(VideoInputDeviceModel::DeviceName);
    videoResFilterModel_->setFilterRole(VideoFormatResolutionModel::Resolution);
    videoFpsFilterModel_->setFilterRole(VideoFormatFpsModel::FPS);

    connect(lrcInstance_->renderer(), &RenderManager::previewFrameStarted, [this]() {
        // TODO: listen to the correct signals that are needed to be added in daemon or lrc
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(
            lrcInstance_->get_selectedConvUid());
        auto call = lrcInstance_->getCallInfoForConversation(convInfo);
        auto callId = call ? call->id : QString();
        if (!callId.isEmpty())
            set_currentRenderingDeviceType(
                lrcInstance_->avModel().getCurrentRenderedDevice(callId).type);
    });

    auto defaultDevice = lrcInstance_->avModel().getDefaultDevice();
    auto defaultDeviceSettings = lrcInstance_->avModel().getDeviceSettings(defaultDevice);
    set_videoDefaultDeviceName(defaultDeviceSettings.name);
    set_videoDefaultDeviceRes(defaultDeviceSettings.size);
    set_videoDefaultDeviceFps(defaultDeviceSettings.rate);
}

CurrentDevice::~CurrentDevice() {}
