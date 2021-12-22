/*
 * Copyright (C) 2008 Remko Troncon
 */

#include "sparkleupdater.h"

#include <Cocoa/Cocoa.h>
#include <Sparkle/Sparkle.h>
#include <QDebug>

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
