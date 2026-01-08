#include "CoreService.h"

// Include the actual qtwrapper headers
// These are available because we updated src/modern/CMakeLists.txt to link qtwrapper
#include "configurationmanager_wrap.h" 
#include "callmanager_wrap.h"
#include "instancemanager_wrap.h"
#include "dbus/configurationmanager.h"
#include "dbus/callmanager.h"

#include <QDebug>


CoreService& CoreService::instance()
{
    static CoreService* s_instance = new CoreService();
    return *s_instance;
}

CoreService::CoreService(QObject* parent)
    : QObject(parent)
    , m_initialized(false)
    , m_configManager(nullptr)
    , m_callManager(nullptr)
{
}

CoreService::~CoreService()
{
    qDebug() << "[CoreService] Destroying...";

    // Stop the daemon thread loop and join threads.
    // This avoids race conditions where background threads fire signals
    // to destroyed wrapper objects.
    libjami::fini();

    // Manually delete children to control order (reverse of creation)
    if (m_instanceManager) { delete m_instanceManager; m_instanceManager = nullptr; }
    // Do not delete singletons
    // if (m_callManager) { delete m_callManager; m_callManager = nullptr; }
    // if (m_configManager) { delete m_configManager; m_configManager = nullptr; }
    qDebug() << "[CoreService] Destroyed.";
}

void CoreService::start()
{
    if (m_initialized) return;

    qDebug() << "[CoreService] Starting backend connection...";

    // Use singletons for managers to share signal handlers registered by InstanceManager
    m_configManager = &ConfigurationManager::instance();
    m_callManager = &CallManager::instance();
    
    m_instanceManager = new InstanceManagerInterface(false);
    m_instanceManager->setParent(this);

    setupConnections();


    m_initialized = true;
    Q_EMIT initializationChanged();
    qDebug() << "[CoreService] Backend services started.";
}

bool CoreService::isInitialized() const
{
    return m_initialized;
}

ConfigurationManagerInterface* CoreService::configurationManager() const
{
    return m_configManager;
}

CallManagerInterface* CoreService::callManager() const
{
    return m_callManager;
}

void CoreService::setupConnections()
{
    if (!m_configManager) return;

    // Connect raw backend signals to CoreService signals
    connect(m_configManager, &ConfigurationManagerInterface::accountsChanged, 
            this, &CoreService::accountsChanged);
    
    // Debug logging for sanity check
    connect(m_configManager, &ConfigurationManagerInterface::accountsChanged, [](){
        qDebug() << "[CoreService] Detected accounts changed.";
    });
}

QStringList CoreService::getAccountList() const
{
    if (!m_configManager) return {};
    return m_configManager->getAccountList();
}

QVariantMap CoreService::getAccountDetails(const QString& accountId) const
{
    if (!m_configManager) return {};
    auto details = m_configManager->getAccountDetails(accountId);
    QVariantMap result;
    for (auto it = details.begin(); it != details.end(); ++it) {
        result.insert(it.key(), it.value());
    }
    return result;
}
