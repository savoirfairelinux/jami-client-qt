#include "devicelinkingmodel.h"
#include "lrcinstance.h"
#include "api/accountmodel.h"

#include "api/account.h"

using namespace lrc::api::account;

// Convert a MapStringString to a QVariantMap
inline QVariantMap
mapStringStringToVariantMap(const MapStringString& map)
{
    QVariantMap variantMap;
    for (auto it = map.constBegin(); it != map.constEnd(); ++it) {
        variantMap.insert(it.key(), it.value());
    }
    return variantMap;
}

DeviceLinkingModel::DeviceLinkingModel(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
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
                    handleAuthenticatingSignal(mapStringStringToVariantMap(details));
                    break;
                case DeviceAuthState::IN_PROGRESS:
                    handleInProgressSignal();
                    break;
                case DeviceAuthState::DONE:
                    handleDoneSignal(mapStringStringToVariantMap(details));
                    break;
                default:
                    break;
                }
            });
}

void
DeviceLinkingModel::addDevice(const QString& token)
{
    int32_t result = lrcInstance_->accountModel().addDevice(lrcInstance_->getCurrentAccountInfo().id,
                                                       token);
    qWarning() << "addDevice operation id: " << result;
    if (result > 0) {
        operationId_ = result;
    } else {
        set_tokenErrorMessage("New device identifier is not recognized.\nPlease follow above instruction.");
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
        set_linkDeviceError(errorString);
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
