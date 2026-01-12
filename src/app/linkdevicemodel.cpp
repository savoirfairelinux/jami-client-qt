/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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

#include "linkdevicemodel.h"
#include "lrcinstance.h"
#include "api/accountmodel.h"

#include "api/account.h"

using namespace lrc::api::account;

LinkDeviceModel::LinkDeviceModel(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
    set_deviceAuthState(static_cast<int>(DeviceAuthState::INIT));
    connect(&lrcInstance_->accountModel(),
            &lrc::api::AccountModel::addDeviceStateChanged,
            this,
            [this](const QString& accountId, uint32_t operationId, int state, const MapStringString& details) {
                if (operationId != operationId_)
                    return;

                auto deviceState = static_cast<DeviceAuthState>(state);

                switch (deviceState) {
                case DeviceAuthState::CONNECTING:
                    handleConnectingSignal();
                    break;
                case DeviceAuthState::AUTHENTICATING:
                    handleAuthenticatingSignal(Utils::mapStringStringToVariantMap(details));
                    break;
                case DeviceAuthState::IN_PROGRESS:
                    handleInProgressSignal();
                    break;
                case DeviceAuthState::DONE:
                    handleDoneSignal(Utils::mapStringStringToVariantMap(details));
                    break;
                default:
                    break;
                }
            });
}

void
LinkDeviceModel::addDevice(const QString& token)
{
    set_tokenErrorMessage("");
    auto errorMessage = QObject::tr("Unrecognized new device identifier. Please follow the instructions above.");

    QString trimmedToken = token.trimmed();
    if (!trimmedToken.startsWith("jami-auth://") || ((trimmedToken.length() != 59) && (trimmedToken.length() != 83))) {
        set_tokenErrorMessage(errorMessage);
        return;
    }

    int32_t result = lrcInstance_->accountModel().addDevice(lrcInstance_->getCurrentAccountInfo().id, trimmedToken);
    if (result > 0) {
        operationId_ = result;
    } else {
        set_tokenErrorMessage(errorMessage);
    }
}

void
LinkDeviceModel::handleConnectingSignal()
{
    set_deviceAuthState(static_cast<int>(DeviceAuthState::CONNECTING));
}

void
LinkDeviceModel::handleAuthenticatingSignal(const QVariantMap& details)
{
    QString peerAddress = details.value("peer_address").toString();
    set_ipAddress(peerAddress);
    set_deviceAuthState(static_cast<int>(DeviceAuthState::AUTHENTICATING));
}

void
LinkDeviceModel::handleInProgressSignal()
{
    set_deviceAuthState(static_cast<int>(DeviceAuthState::IN_PROGRESS));
}

void
LinkDeviceModel::handleDoneSignal(const QVariantMap& details)
{
    QString errorString = details.value("error").toString();
    if (!errorString.isEmpty() && errorString != "none") {
        auto error = mapLinkDeviceError(errorString.toStdString());
        set_linkDeviceError(getLinkDeviceString(error));
        set_deviceAuthState(static_cast<int>(DeviceAuthState::DONE));
    } else {
        set_deviceAuthState(static_cast<int>(DeviceAuthState::DONE));
    }
}

void
LinkDeviceModel::confirmAddDevice()
{
    handleInProgressSignal();
    lrcInstance_->accountModel().confirmAddDevice(lrcInstance_->getCurrentAccountInfo().id, operationId_);
}

void
LinkDeviceModel::cancelAddDevice()
{
    handleInProgressSignal();
    lrcInstance_->accountModel().cancelAddDevice(lrcInstance_->getCurrentAccountInfo().id, operationId_);
}

void
LinkDeviceModel::reset()
{
    set_deviceAuthState(static_cast<int>(DeviceAuthState::INIT));

    set_linkDeviceError("");
    set_ipAddress("");
    set_tokenErrorMessage("");
}
