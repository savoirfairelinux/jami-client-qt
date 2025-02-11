#pragma once

#include "lrcinstance.h"
#include "qtutils.h"
#include "api/account.h"

#include <QObject>
#include <QVariant>
#include <QMap>

#include <wizardviewstepmodel.h>

class DeviceLinkingModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY stateChanged)
    Q_PROPERTY(lrc::api::account::DeviceAuthState deviceAuthState READ deviceAuthState NOTIFY deviceAuthStateChanged)
    Q_PROPERTY(QString ipAddress READ ipAddress NOTIFY ipAddressChanged)

public:

    explicit DeviceLinkingModel(LRCInstance* lrcInstance, QObject* parent = nullptr);

    QString errorMessage() const { return errorMsg_; }
    lrc::api::account::DeviceAuthState deviceAuthState() const { return currentState_; }
    QString ipAddress() const { return ipAddress_; }
    Q_INVOKABLE void addDevice(const QString& token);

    Q_INVOKABLE void confirmAddDevice();
    Q_INVOKABLE void cancelAddDevice();

Q_SIGNALS:
    void stateChanged();
    void deviceAuthStateChanged();
    void ipAddressChanged();

private:
    bool checkNewStateValidity(lrc::api::account::DeviceAuthState newState) const;
    void handleConnectingSignal();
    void handleAuthenticatingSignal(const QVariantMap& details);
    void handleInProgressSignal();
    void handleDoneSignal(const QVariantMap& details);

    LRCInstance* lrcInstance_ = nullptr;
    int32_t operationId_;
    lrc::api::account::DeviceAuthState currentState_ {lrc::api::account::DeviceAuthState::INIT};
    QString errorMsg_;
    QString ipAddress_;
};
