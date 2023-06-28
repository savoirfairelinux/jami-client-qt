#pragma once

#include "networkmanager.h"
class LRCInstance;
class ConnectivityMonitor;
class AbstractAppVersionManager : public NetworkManager
{
    Q_OBJECT
public:
    explicit AbstractAppVersionManager(ConnectivityMonitor* cm, QObject* parent = nullptr);
    ~AbstractAppVersionManager() = default;
    virtual Q_INVOKABLE void checkForUpdates(bool quiet = false) = 0;
    virtual Q_INVOKABLE void applyUpdates(bool beta = false) = 0;
    virtual Q_INVOKABLE bool isUpdaterEnabled() = 0;
    virtual Q_INVOKABLE bool isAutoUpdaterEnabled() = 0;
    virtual Q_INVOKABLE void setAutoUpdateCheck(bool state) = 0;
};

Q_DECLARE_METATYPE(AbstractAppVersionManager*)
