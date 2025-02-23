#include "devicelinkingmodel.h"
#include "lrcinstance.h"
#include "api/accountmodel.h"

#include "api/account.h"

using namespace lrc::api::account;

DeviceLinkingModel::DeviceLinkingModel(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
    set_deviceAuthState(static_cast<int>(DeviceAuthState::INIT));
    connect(&lrcInstance_->accountModel(),
            &lrc::api::AccountModel::addDeviceStateChanged,
            this,
            [this](const QString& accountId,
                   uint32_t operationId,
                   int state,
                   const MapStringString& details) {
                if (operationId != operationId_)
                    return;

                auto deviceState = static_cast<DeviceAuthState>(state);

                qWarning() << "Processing signal:" << accountId << ":" << operationId << ":"
                        << static_cast<int>(state) << details;

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
DeviceLinkingModel::addDevice(const QString& token)
{
    set_tokenErrorMessage("");
    auto errorMessage = QObject::tr("New device identifier is not recognized.\nPlease follow above instruction.");

    if (!token.startsWith("jami-auth://") || (token.length() != 59)) {
        set_tokenErrorMessage(errorMessage);
        return;
    }

    int32_t result = lrcInstance_->accountModel().addDevice(lrcInstance_->getCurrentAccountInfo().id,
                                                       token);
    if (result > 0) {
        operationId_ = result;
    } else {
        set_tokenErrorMessage(errorMessage);
    }
}


void
DeviceLinkingModel::handleConnectingSignal()
{
    set_deviceAuthState(static_cast<int>(DeviceAuthState::CONNECTING));
}

void
DeviceLinkingModel::handleAuthenticatingSignal(const QVariantMap& details)
{
    QString peerAddress = details.value("peer_address").toString();
    set_ipAddress(peerAddress);
    set_deviceAuthState(static_cast<int>(DeviceAuthState::AUTHENTICATING));
}

void
DeviceLinkingModel::handleInProgressSignal()
{
    set_deviceAuthState(static_cast<int>(DeviceAuthState::IN_PROGRESS));
}

void
DeviceLinkingModel::handleDoneSignal(const QVariantMap& details)
{
    QString errorString = details.value("error").toString();
    if (!errorString.isEmpty() && errorString != "none") {
        auto error = mapLinkDeviceError(errorString.toStdString());
        set_linkDeviceError(getLinkDeviceString(error));
        set_deviceAuthState(static_cast<int>(DeviceAuthState::ERROR));
    } else {
        set_deviceAuthState(static_cast<int>(DeviceAuthState::DONE));
    }
}


void
DeviceLinkingModel::confirmAddDevice()
{
    handleInProgressSignal();
    lrcInstance_->accountModel().confirmAddDevice(lrcInstance_->getCurrentAccountInfo().id, operationId_);
}

void
DeviceLinkingModel::cancelAddDevice()
{
    handleInProgressSignal();
    lrcInstance_->accountModel().cancelAddDevice(lrcInstance_->getCurrentAccountInfo().id, operationId_);
}

void
DeviceLinkingModel::reset()
{
    set_deviceAuthState(static_cast<int>(DeviceAuthState::INIT));

    set_linkDeviceError("");
    set_ipAddress("");
    set_tokenErrorMessage("");
}
