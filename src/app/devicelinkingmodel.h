#pragma once

#include "api/account.h"

#include "qmladapterbase.h"
#include "qtutils.h"

#include <QObject>
#include <QVariant>
#include <QMap>

class LRCInstance;

class DeviceAuthStateEnum : public QObject {
    Q_OBJECT
public:
    enum State {
        INIT = static_cast<int>(lrc::api::account::DeviceAuthState::INIT),
        TOKEN_AVAILABLE = static_cast<int>(lrc::api::account::DeviceAuthState::TOKEN_AVAILABLE),
        CONNECTING = static_cast<int>(lrc::api::account::DeviceAuthState::CONNECTING),
        AUTHENTICATING = static_cast<int>(lrc::api::account::DeviceAuthState::AUTHENTICATING),
        IN_PROGRESS = static_cast<int>(lrc::api::account::DeviceAuthState::IN_PROGRESS),
        DONE = static_cast<int>(lrc::api::account::DeviceAuthState::DONE),
        ERROR = static_cast<int>(lrc::api::account::DeviceAuthState::ERROR)
    };
    Q_ENUM(State)
};

class DeviceLinkingModel : public QObject
{
    Q_OBJECT
    QML_PROPERTY(QString, tokenErrorMessage);
    QML_PROPERTY(QString, linkDeviceError);
    QML_PROPERTY(int, deviceAuthState);
    QML_PROPERTY(QString, ipAddress);

public:

    explicit DeviceLinkingModel(LRCInstance* lrcInstance, QObject* parent = nullptr);

    Q_INVOKABLE void addDevice(const QString& token);

    Q_INVOKABLE void confirmAddDevice();
    Q_INVOKABLE void cancelAddDevice();
    Q_INVOKABLE void reset();

private:
    bool checkNewStateValidity(lrc::api::account::DeviceAuthState newState) const;
    void handleConnectingSignal();
    void handleAuthenticatingSignal(const QVariantMap& details);
    void handleInProgressSignal();
    void handleDoneSignal(const QVariantMap& details);

    LRCInstance* lrcInstance_ = nullptr;
    uint32_t operationId_;
};
