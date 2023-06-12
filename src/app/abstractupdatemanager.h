/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Xavier Jouslin de Noray <xavier.jouslindenoray@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include "networkmanager.h"

class LRCInstance;
class ConnectivityMonitor;

class AbstractUpdateManager : public NetworkManager
{
    Q_OBJECT
public:
    explicit AbstractUpdateManager(ConnectivityMonitor* cm, QObject* parent = nullptr)
        : NetworkManager(cm, parent)
    {}

    ~AbstractUpdateManager() = default;
    /**
     * @brief call by the update routine, this compare the version of local and remote
     * @param quiet if true, the auto update is triggered
     */
    virtual Q_INVOKABLE void checkForUpdates(bool quiet = false) = 0;
    /**
     * @brief call by the update routine, this apply the update
     * @param beta if true, the beta version is applied
     */
    virtual Q_INVOKABLE void applyUpdates(bool beta = false) = 0;
    /**
     * @brief return true if the updater is enabled
     */
    virtual Q_INVOKABLE bool isUpdaterEnabled() = 0;
    /**
     * @brief return true if the auto updater is enabled
     */
    virtual Q_INVOKABLE bool isAutoUpdaterEnabled() = 0;
    /**
     * @brief set the auto updater state
     * @param state the new state
     */
    virtual Q_INVOKABLE void setAutoUpdateCheck(bool state) = 0;
};

Q_DECLARE_METATYPE(AbstractUpdateManager*)
