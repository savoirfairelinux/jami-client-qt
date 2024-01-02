/****************************************************************************
 *    Copyright (C) 2017-2024 Savoir-faire Linux Inc.                       *
 *   Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>           *
 *                                                                          *
 *   This library is free software; you can redistribute it and/or          *
 *   modify it under the terms of the GNU Lesser General Public             *
 *   License as published by the Free Software Foundation; either           *
 *   version 2.1 of the License, or (at your option) any later version.     *
 *                                                                          *
 *   This library is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
 *   Lesser General Public License for more details.                        *
 *                                                                          *
 *   You should have received a copy of the GNU General Public License      *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/
#include "api/devicemodel.h"

#include "api/accountmodel.h"
#include "callbackshandler.h"
#include "dbus/configurationmanager.h"

#include <account_const.h>

#include <QObject>

#include <list>
#include <mutex>

namespace lrc {

using namespace api;

class DeviceModelPimpl : public QObject
{
    Q_OBJECT
public:
    DeviceModelPimpl(const DeviceModel& linked, const CallbacksHandler& callbacksHandler);
    ~DeviceModelPimpl();

    const CallbacksHandler& callbacksHandler;
    const DeviceModel& linked;

    std::mutex devicesMtx_;
    QString currentDeviceId_;
    QList<Device> devices_;
public Q_SLOTS:
    /**
     * Listen from CallbacksHandler to get when a device name changed or a device is added
     * @param accountId interaction receiver.
     * @param devices A map of device IDs with corresponding labels.
     */
    void slotKnownDevicesChanged(const QString& accountId, const MapStringString devices);

    /**
     * update devices_ when a device is revoked
     * @param accountId
     * @param deviceId
     * @param status SUCCESS = 0, WRONG_PASSWORD = 1, UNKNOWN_DEVICE = 2
     */
    void slotDeviceRevocationEnded(const QString& accountId,
                                   const QString& deviceId,
                                   const int status);
};

DeviceModel::DeviceModel(const account::Info& owner, const CallbacksHandler& callbacksHandler)
    : owner(owner)
    , pimpl_(std::make_unique<DeviceModelPimpl>(*this, callbacksHandler))
{}

DeviceModel::~DeviceModel() {}

QList<Device>
DeviceModel::getAllDevices() const
{
    return pimpl_->devices_;
}

Device
DeviceModel::getDevice(const QString& id) const
{
    std::lock_guard<std::mutex> lock(pimpl_->devicesMtx_);
    auto i = std::find_if(pimpl_->devices_.begin(), pimpl_->devices_.end(), [id](const Device& d) {
        return d.id == id;
    });

    if (i == pimpl_->devices_.end())
        return {};

    return *i;
}

void
DeviceModel::revokeDevice(const QString& id, const QString& password)
{
    ConfigurationManager::instance().revokeDevice(owner.id, id, "password", password);
}

void
DeviceModel::setCurrentDeviceName(const QString& newName)
{
    // Update deamon config
    auto config = owner.accountModel->getAccountConfig(owner.id);
    config.deviceName = newName;
    owner.accountModel->setAccountConfig(owner.id, config);
    // Update model
    std::unique_lock<std::mutex> lock(pimpl_->devicesMtx_);
    for (auto& device : pimpl_->devices_) {
        if (device.id == config.deviceId) {
            device.name = newName;
            lock.unlock();
            Q_EMIT deviceUpdated(device.id);
            return;
        }
    }
}

DeviceModelPimpl::DeviceModelPimpl(const DeviceModel& linked,
                                   const CallbacksHandler& callbacksHandler)
    : linked(linked)
    , callbacksHandler(callbacksHandler)
    , devices_({})
{
    const MapStringString aDetails = ConfigurationManager::instance().getVolatileAccountDetails(
        linked.owner.id);
    currentDeviceId_ = aDetails.value(libjami::Account::ConfProperties::DEVICE_ID);
    const MapStringString accountDevices = ConfigurationManager::instance().getKnownRingDevices(
        linked.owner.id);
    auto it = accountDevices.begin();
    while (it != accountDevices.end()) {
        {
            std::lock_guard<std::mutex> lock(devicesMtx_);
            auto device = Device {/* id= */ it.key(),
                                  /* name= */ it.value(),
                                  /* isCurrent= */ it.key() == currentDeviceId_};
            if (device.isCurrent) {
                currentDeviceId_ = it.key();
                devices_.push_back(device);
            } else {
                devices_.push_back(device);
            }
        }
        ++it;
    }

    connect(&callbacksHandler,
            &CallbacksHandler::knownDevicesChanged,
            this,
            &DeviceModelPimpl::slotKnownDevicesChanged);
    connect(&callbacksHandler,
            &CallbacksHandler::deviceRevocationEnded,
            this,
            &DeviceModelPimpl::slotDeviceRevocationEnded);
}

DeviceModelPimpl::~DeviceModelPimpl()
{
    disconnect(&callbacksHandler,
               &CallbacksHandler::knownDevicesChanged,
               this,
               &DeviceModelPimpl::slotKnownDevicesChanged);
    disconnect(&callbacksHandler,
               &CallbacksHandler::deviceRevocationEnded,
               this,
               &DeviceModelPimpl::slotDeviceRevocationEnded);
}

void
DeviceModelPimpl::slotKnownDevicesChanged(const QString& accountId, const MapStringString devices)
{
    if (accountId != linked.owner.id)
        return;
    auto devicesMap = devices;
    // Update current devices
    QStringList updatedDevices;
    {
        std::lock_guard<std::mutex> lock(devicesMtx_);
        for (auto& device : devices_) {
            if (devicesMap.find(device.id) != devicesMap.end()) {
                if (device.name != devicesMap[device.id]) {
                    updatedDevices.push_back(device.id);
                    device.name = devicesMap[device.id];
                }
                devicesMap.remove(device.id);
            }
        }
    }
    for (const auto& device : updatedDevices)
        Q_EMIT linked.deviceUpdated(device);

    // Add new devices
    QStringList addedDevices;
    {
        std::lock_guard<std::mutex> lock(devicesMtx_);
        auto it = devicesMap.begin();
        while (it != devicesMap.end()) {
            devices_.push_back(Device {/* id= */ it.key(),
                                       /* name= */ it.value(),
                                       /* isCurrent= */ false});
            addedDevices.push_back(it.key());
            ++it;
        }
    }
    for (const auto& device : addedDevices)
        Q_EMIT linked.deviceAdded(device);
}

void
DeviceModelPimpl::slotDeviceRevocationEnded(const QString& accountId,
                                            const QString& deviceId,
                                            const int status)
{
    if (accountId != linked.owner.id)
        return;
    if (status == 0) {
        std::lock_guard<std::mutex> lock(devicesMtx_);
        auto it = std::find_if(devices_.begin(), devices_.end(), [deviceId](const Device& d) {
            return d.id == deviceId;
        });

        if (it != devices_.end())
            devices_.erase(it);
    }

    switch (status) {
    case 0:
        Q_EMIT linked.deviceRevoked(deviceId, DeviceModel::Status::SUCCESS);
        break;
    case 1:
        Q_EMIT linked.deviceRevoked(deviceId, DeviceModel::Status::WRONG_PASSWORD);
        break;
    case 2:
        Q_EMIT linked.deviceRevoked(deviceId, DeviceModel::Status::UNKNOWN_DEVICE);
        break;
    default:
        break;
    }
}

} // namespace lrc

#include "devicemodel.moc"
#include "api/moc_devicemodel.cpp"
