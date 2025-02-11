#pragma once

#include "qtutils.h"

#include <QObject>
#include <QVariant>
#include <QMap>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class LRCInstance;

class DeviceLinkingModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool isPasswordRequired READ isPasswordRequired NOTIFY stateChanged)
    Q_PROPERTY(bool isExporting READ isExporting NOTIFY stateChanged)
    Q_PROPERTY(bool isExportSuccess READ isExportSuccess NOTIFY stateChanged)
    Q_PROPERTY(QString exportedPIN READ exportedPIN NOTIFY stateChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY stateChanged)
    Q_PROPERTY(int deviceAuthState READ deviceAuthState NOTIFY deviceAuthStateChanged)
    Q_PROPERTY(QString ipAddress READ ipAddress NOTIFY ipAddressChanged)

public:
    enum DeviceAuthState {
        Init = 0,
        TokenAvailable = 1,
        Connecting = 2,
        Authenticating = 3,
        InProgress = 4,
        Done = 5,
        Error = 6
    };
    Q_ENUM(DeviceAuthState)

    explicit DeviceLinkingModel(LRCInstance* lrcInstance, QObject* parent = nullptr);

    bool isPasswordRequired() const;
    bool isExporting() const;
    bool isExportSuccess() const;
    QString exportedPIN() const;
    QString errorMessage() const;
    int deviceAuthState() const
    {
        return currentState_;
    }
    QString ipAddress() const { return ipAddress_; }
    Q_INVOKABLE void addDevice(const QString& token);

    Q_INVOKABLE void startExport(const QString& password);

    Q_INVOKABLE void confirmAddDevice();
    Q_INVOKABLE void cancelAddDevice();

Q_SIGNALS:
    void stateChanged();
    void deviceAuthStateChanged();
    void ipAddressChanged();

private:
    bool checkNewStateValidity(int newState) const;
    void handleConnectingSignal();
    void handleAuthenticatingSignal(const QVariantMap& details);
    void handleInProgressSignal();
    void handleDoneSignal(const QVariantMap& details);

    LRCInstance* lrcInstance_ = nullptr;
    int32_t operationId_;
    int currentState_ {DeviceAuthState::Init};
    QString pin_;
    QString errorMsg_;
    bool exporting_ {false};
    bool exportSuccess_ {false};
    QString ipAddress_ {"test"};
};
