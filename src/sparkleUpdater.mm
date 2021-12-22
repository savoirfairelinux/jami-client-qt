/*
 * Copyright (C) 2008 Remko Troncon
 */

#include "sparkleUpdater.h"

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
    if ([updaterController.updater canCheckForUpdates]) {
        [updaterController.updater checkForUpdates];
    }
}
