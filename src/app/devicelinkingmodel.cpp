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
                if (!checkNewStateValidity(deviceState)) {
                    qWarning() << "Invalid state transition:" << static_cast<int>(currentState_)
                              << "->" << static_cast<int>(deviceState);
                    return;
                }

                qDebug() << "Processing signal:" << accountId << ":" << operationId << ":"
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
    auto result = lrcInstance_->accountModel().addDevice(lrcInstance_->getCurrentAccountInfo().id,
                                                       token);
    if (result > 0) {
        operationId_ = result;
    } else {
        tokenErrorMessage_ = "New device identifier is not recognized.\nPlease follow above instruction.";
    }
}

bool
DeviceLinkingModel::checkNewStateValidity(DeviceAuthState newState) const
{
    QVector<DeviceAuthState> validStates;

    switch (currentState_) {
    case DeviceAuthState::INIT:
        validStates = {DeviceAuthState::CONNECTING, DeviceAuthState::DONE, DeviceAuthState::TOKEN_AVAILABLE};
        break;
    case DeviceAuthState::TOKEN_AVAILABLE:
        validStates = {DeviceAuthState::CONNECTING, DeviceAuthState::DONE};
        break;
    case DeviceAuthState::CONNECTING:
        validStates = {DeviceAuthState::AUTHENTICATING, DeviceAuthState::DONE};
        break;
    case DeviceAuthState::AUTHENTICATING:
        validStates = {DeviceAuthState::IN_PROGRESS, DeviceAuthState::DONE};
        break;
    case DeviceAuthState::IN_PROGRESS:
        validStates = {DeviceAuthState::IN_PROGRESS, DeviceAuthState::DONE};
        break;
    case DeviceAuthState::ERROR:
    case DeviceAuthState::DONE:
        validStates = {DeviceAuthState::DONE};
        break;
    }

    return validStates.contains(newState);
}

void
DeviceLinkingModel::handleConnectingSignal()
{
    currentState_ = DeviceAuthState::CONNECTING;
}

void
DeviceLinkingModel::handleAuthenticatingSignal(const QVariantMap& details)
{
    QString peerAddress = details.value("peerAddress").toString();
    ipAddress_ = peerAddress;
    currentState_ = DeviceAuthState::AUTHENTICATING;
}

void
DeviceLinkingModel::handleInProgressSignal()
{
    currentState_ = DeviceAuthState::IN_PROGRESS;
}

void
DeviceLinkingModel::handleDoneSignal(const QVariantMap& details)
{
    QString errorString = details.value("error").toString();
    if (!errorString.isEmpty() && errorString != "none") {
        linkDeviceError_ = errorString;
        currentState_ = DeviceAuthState::ERROR;
    } else {
        currentState_ = DeviceAuthState::DONE;
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
