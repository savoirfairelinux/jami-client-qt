/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "updatemanager.h"

#ifdef ENABLE_SPARKLE
#include <Sparkle/Sparkle.h>
#endif

#ifdef BETA
static constexpr bool isBeta = true;
#else
static constexpr bool isBeta = false;
#endif

#ifdef ENABLE_SPARKLE
 struct UpdateManager::Impl
{

    Impl()
    {
        updaterController_ = [[SPUStandardUpdaterController alloc] initWithStartingUpdater: true
                                                                           updaterDelegate: nil
                                                                        userDriverDelegate: nil];
    };

    void checkForUpdates()
    {
        [updaterController_ checkForUpdates: nil];
    };

    void setAutoUpdateCheck(bool state)
    {
        updaterController_.updater.updateCheckInterval = 3600 * 24;
        updaterController_.updater.automaticallyChecksForUpdates = state;
    };

    bool isAutoUpdaterEnabled()
    {
        return updaterController_.updater.automaticallyChecksForUpdates;
    };

    bool isUpdaterEnabled() {
        return true;
    };

    SPUStandardUpdaterController* updaterController_;

};
#else
struct UpdateManager::Impl
{
    void checkForUpdates() {};

    void setAutoUpdateCheck(bool state) {};

    bool isAutoUpdaterEnabled()
    {
        return false;
    };
    bool isUpdaterEnabled()
    {
        return false;
    };
};
#endif

UpdateManager::UpdateManager(const QString& url,
                             ConnectivityMonitor* cm,
                             LRCInstance* instance,
                             QObject* parent)
    : NetworkManager(cm, parent)
    , pimpl_(std::make_unique<Impl>())
{}

UpdateManager::~UpdateManager()
{}

void
UpdateManager::checkForUpdates(bool quiet)
{
    Q_UNUSED(quiet)
    pimpl_->checkForUpdates();
}

void
UpdateManager::applyUpdates(bool beta)
{
    Q_UNUSED(beta)
}

void
UpdateManager::cancelUpdate()
{}


void
UpdateManager::cancelDownload()
{}

void
UpdateManager::setAutoUpdateCheck(bool state)
{
    pimpl_->setAutoUpdateCheck(state);
}

bool
UpdateManager::isCurrentVersionBeta()
{
    return isBeta;
}

bool
UpdateManager::isUpdaterEnabled()
{
    return pimpl_->isUpdaterEnabled();
}

bool
UpdateManager::isAutoUpdaterEnabled()
{
    return pimpl_->isAutoUpdaterEnabled();
}
