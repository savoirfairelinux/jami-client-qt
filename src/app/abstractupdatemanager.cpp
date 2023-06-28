#include "abstractupdatemanager.h"

AbstractAppVersionManager::AbstractAppVersionManager(ConnectivityMonitor* cm, QObject* parent)
    : NetworkManager(cm, parent)
{}
