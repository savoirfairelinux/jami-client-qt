/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "positioning.h"

#include <gtest/gtest.h>

#include <QDateTime>
#include <QGeoPositionInfo>
#include <QJsonDocument>
#include <QJsonObject>

namespace {

QJsonObject
parse(const QString& message)
{
    return QJsonDocument::fromJson(message.toUtf8()).object();
}

} // namespace

// A computer that does not move keeps reporting the position it got when it
// started, dated from then. Receivers keep only a position newer than the one
// they hold, and forget a peer whose position stopped getting newer: the shared
// position must be dated when it is sent.
TEST(Positioning, APositionIsDatedWhenItIsSent)
{
    const QGeoPositionInfo staleFix(QGeoCoordinate(45.5, -73.6), QDateTime::currentDateTime().addSecs(-3 * 3600));
    const auto before = QDateTime::currentMSecsSinceEpoch();

    const auto position = parse(Positioning::convertToJson(staleFix));

    EXPECT_EQ(position["type"].toString(), "Position");
    EXPECT_DOUBLE_EQ(position["lat"].toDouble(), 45.5);
    EXPECT_DOUBLE_EQ(position["long"].toDouble(), -73.6);
    EXPECT_GE(position["time"].toInteger(), before);
}

// Receivers ignore a location message that carries a single field.
TEST(Positioning, AStopIsDated)
{
    const auto before = QDateTime::currentMSecsSinceEpoch();

    const auto stop = parse(Positioning::stopJson());

    EXPECT_EQ(stop["type"].toString(), "Stop");
    EXPECT_GE(stop["time"].toInteger(), before);
}
