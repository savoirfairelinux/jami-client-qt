/*
 * Copyright (C) 2008 Remko Troncon
 */

#include "sparkleUpdater.h"

#include <Cocoa/Cocoa.h>
#include <Sparkle/Sparkle.h>
#include <QDebug>

SPUStandardUpdaterController* updaterController;

SparkleUpdater::SparkleUpdater(const QString& aUrl)
{
    updaterController = [[SPUStandardUpdaterController alloc] initWithStartingUpdater: false updaterDelegate: nil userDriverDelegate: nil];
    NSURL* url = [NSURL URLWithString:
            [NSString stringWithUTF8String: aUrl.toUtf8().data()]];
    [updaterController.updater setFeedURL: url];
}

SparkleUpdater::~SparkleUpdater(){}

void SparkleUpdater::checkForUpdates()
{
    if ([updaterController.updater canCheckForUpdates]) {
        [updaterController.updater checkForUpdates];
    }
}
