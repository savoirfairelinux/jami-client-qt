#pragma once

#include "networkmanager.h"
class LRCInstance;
class ConnectivityMonitor;
class AbstractUpdateManager : public NetworkManager
{
    Q_OBJECT
public:
    explicit AbstractUpdateManager(ConnectivityMonitor* cm, QObject* parent = nullptr);
    ~AbstractUpdateManager() = default;
    virtual Q_INVOKABLE bool isAutoUpdaterEnabled() = 0;
};

Q_DECLARE_METATYPE(AbstractUpdateManager*)
