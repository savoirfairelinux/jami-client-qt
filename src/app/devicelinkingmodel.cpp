#include "devicelinkingmodel.h"
#include "lrcinstance.h"
#include "api/accountmodel.h"
#include "global.h"
#include "qtutils.h"

#include "api/account.h"
#include "api/conversation.h"

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
            &AccountModel::addDeviceStateChanged,
            this,
            [this](const QString& accountId,
                   uint32_t operationId,
                   DeviceAuthState state,
                   const MapStringString& details) {
                if (operationId != operationId_)
                    return;

                if (!checkNewStateValidity(state)) {
                    qWarning() << "Invalid state transition:" << static_cast<int>(currentState_) 
                              << "->" << static_cast<int>(state);
                    return;
                }

                qDebug() << "Processing signal:" << accountId << ":" << operationId << ":" 
                        << static_cast<int>(state) << details;

                currentState_ = state;
                Q_EMIT deviceAuthStateChanged();

                switch (state) {
                case DeviceAuthState::INIT:
                    break;
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
                case DeviceAuthState::TOKEN_AVAILABLE:
                    break;
                case DeviceAuthState::ERROR:
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
        currentState_ = DeviceAuthState::INIT;
        Q_EMIT deviceAuthStateChanged();
    } else {
        currentState_ = DeviceAuthState::ERROR;
        errorMsg_ = "Failed to start device linking";
        Q_EMIT deviceAuthStateChanged();
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
    Q_EMIT deviceAuthStateChanged();
}

void
DeviceLinkingModel::handleAuthenticatingSignal(const QVariantMap& details)
{
    QString peerAddress = details.value("peerAddress").toString();
    ipAddress_ = peerAddress;
    currentState_ = DeviceAuthState::AUTHENTICATING;
    Q_EMIT deviceAuthStateChanged();
    Q_EMIT ipAddressChanged();
}

void
DeviceLinkingModel::handleInProgressSignal()
{
    currentState_ = DeviceAuthState::IN_PROGRESS;
    Q_EMIT deviceAuthStateChanged();
}

void
DeviceLinkingModel::handleDoneSignal(const QVariantMap& details)
{
    QString errorString = details.value("error").toString();
    if (!errorString.isEmpty() && errorString != "none") {
        currentState_ = DeviceAuthState::ERROR;
        errorMsg_ = errorString;
    } else {
        currentState_ = DeviceAuthState::DONE;
    }
    Q_EMIT deviceAuthStateChanged();
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
