#include "devicelinkingmodel.h"
#include "lrcinstance.h"
#include "api/accountmodel.h"
#include "global.h"
#include "qtutils.h"

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
                   int state,
                   const MapStringString& details) {
                if (operationId != operationId_)
                    return;

                if (!checkNewStateValidity(state)) {
                    qWarning() << "Invalid state transition:" << currentState_ << "->" << state;
                    return;
                }

                qDebug() << "Processing signal:" << accountId << ":" << operationId << ":" << state
                        << details;

                switch (state) {
                case DeviceAuthState::Init:
                    break;
                case DeviceAuthState::Connecting:
                    handleConnectingSignal();
                    break;
                case DeviceAuthState::Authenticating:
                    handleAuthenticatingSignal(mapStringStringToVariantMap(details));
                    break;
                case DeviceAuthState::InProgress:
                    handleInProgressSignal();
                    break;
                case DeviceAuthState::Done:
                    handleDoneSignal(mapStringStringToVariantMap(details));
                    break;
                case DeviceAuthState::TokenAvailable:
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
        currentState_ = DeviceAuthState::Init;
        Q_EMIT deviceAuthStateChanged();
    } else {
        currentState_ = DeviceAuthState::Error;
        errorMsg_ = "Failed to start device linking";
        Q_EMIT deviceAuthStateChanged();
    }
}

bool
DeviceLinkingModel::checkNewStateValidity(int newState) const
{
    QVector<int> validStates;

    switch (currentState_) {
    case DeviceAuthState::Init:
        validStates = {DeviceAuthState::Connecting, DeviceAuthState::Done};
        break;
    case DeviceAuthState::Connecting:
        validStates = {DeviceAuthState::Authenticating, DeviceAuthState::Done};
        break;
    case DeviceAuthState::Authenticating:
        validStates = {DeviceAuthState::InProgress, DeviceAuthState::Done};
        break;
    case DeviceAuthState::InProgress:
        validStates = {DeviceAuthState::InProgress, DeviceAuthState::Done};
        break;
    case DeviceAuthState::Error:
    case DeviceAuthState::Done:
        validStates = {DeviceAuthState::Done};
        break;
    default:
        return false;
    }

    return validStates.contains(newState);
}

void
DeviceLinkingModel::handleConnectingSignal()
{
    currentState_ = DeviceAuthState::Connecting;
    Q_EMIT deviceAuthStateChanged();
}

void
DeviceLinkingModel::handleAuthenticatingSignal(const QVariantMap& details)
{
    QString peerAddress = details.value("peerAddress").toString();
    ipAddress_ = peerAddress;
    currentState_ = DeviceAuthState::Authenticating;
    Q_EMIT deviceAuthStateChanged();
    Q_EMIT ipAddressChanged();
}

void
DeviceLinkingModel::handleInProgressSignal()
{
    currentState_ = DeviceAuthState::InProgress;
    Q_EMIT deviceAuthStateChanged();
}

void
DeviceLinkingModel::handleDoneSignal(const QVariantMap& details)
{
    QString errorString = details.value("error").toString();
    if (!errorString.isEmpty() && errorString != "none") {
        currentState_ = DeviceAuthState::Error;
        errorMsg_ = errorString;
    } else {
        currentState_ = DeviceAuthState::Done;
    }
    Q_EMIT deviceAuthStateChanged();
}


QString
DeviceLinkingModel::errorMessage() const
{
    return errorMsg_;
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
