#pragma once

#include "api/account.h"

#include "qmladapterbase.h"
#include "qtutils.h"

#include <QObject>
#include <QVariant>
#include <QMap>

class LRCInstance;

class DeviceLinkingModel : public QObject
{
    Q_OBJECT
    QML_PROPERTY(QString, tokenErrorMessage);
    QML_PROPERTY(QString, linkDeviceError);
    QML_PROPERTY(lrc::api::account::DeviceAuthState, deviceAuthState);
    QML_PROPERTY(QString, ipAddress);

public:

    explicit DeviceLinkingModel(LRCInstance* lrcInstance, QObject* parent = nullptr);

    lrc::api::account::DeviceAuthState deviceAuthState() const { return currentState_; }
    Q_INVOKABLE void addDevice(const QString& token);

    Q_INVOKABLE void confirmAddDevice();
    Q_INVOKABLE void cancelAddDevice();

private:
    bool checkNewStateValidity(lrc::api::account::DeviceAuthState newState) const;
    void handleConnectingSignal();
    void handleAuthenticatingSignal(const QVariantMap& details);
    void handleInProgressSignal();
    void handleDoneSignal(const QVariantMap& details);

    LRCInstance* lrcInstance_ = nullptr;
    int32_t operationId_;
    lrc::api::account::DeviceAuthState currentState_ {lrc::api::account::DeviceAuthState::INIT};
};
