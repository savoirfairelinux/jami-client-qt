#include "abstractupdatemanager.h"

AbstractUpdateManager::AbstractUpdateManager(ConnectivityMonitor* cm, QObject* parent)
    : NetworkManager(cm, parent)
{}
