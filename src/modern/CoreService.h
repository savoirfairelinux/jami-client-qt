#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantMap>
#include <memory>
#include <QQmlEngine>

// Forward declarations for qtwrapper interfaces
class ConfigurationManagerInterface;
class CallManagerInterface;
class InstanceManagerInterface;

/**
 * CoreService

 *
 * Central singleton service that manages the connection to the jami backend.
 * Abstractions:
 * - Wraps ConfigurationManagerInterface (Accounts)
 * - Wraps CallManagerInterface (Calls/Conversations)
 *
 * Avoids exposing raw "Daemon" or "Wrapper" types directly to QML where possible.
 */
class CoreService : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool isInitialized READ isInitialized NOTIFY initializationChanged)

public:
    static CoreService& instance();
    static QObject* create(QQmlEngine* qmlEngine, QJSEngine* jsEngine);

    // Initialization
    void start();
    bool isInitialized() const;

    // Direct Accessors (for C++ Models)
    ConfigurationManagerInterface* configurationManager() const;
    CallManagerInterface* callManager() const;

    // Helper methods for QML/Models
    Q_INVOKABLE QStringList getAccountList() const;
    Q_INVOKABLE QVariantMap getAccountDetails(const QString& accountId) const;

Q_SIGNALS:
    void initializationChanged();
    void accountsChanged();

private:
    explicit CoreService(QObject* parent = nullptr);
    ~CoreService() override;

    bool m_initialized;
    ConfigurationManagerInterface* m_configManager;
    CallManagerInterface* m_callManager;
    InstanceManagerInterface* m_instanceManager;

    void setupConnections();
};
