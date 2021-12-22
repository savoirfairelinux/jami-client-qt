/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

#include "sparkleupdater.h"

#ifdef ENABLE_SPARKLE
//#include <Cocoa/Cocoa.h>
#include <QDebug>
#include <Sparkle/Sparkle.h>
SPUStandardUpdaterController* updaterController;

SparkleUpdater::SparkleUpdater()
{
    updaterController = [[SPUStandardUpdaterController alloc] initWithStartingUpdater: false updaterDelegate: nil userDriverDelegate: nil];
}

SparkleUpdater::~SparkleUpdater(){}

void SparkleUpdater::checkForUpdates()
{
    [updaterController startUpdater];
    if ([updaterController.updater canCheckForUpdates]) {
        [updaterController.updater checkForUpdates];
    }
}
#endif
