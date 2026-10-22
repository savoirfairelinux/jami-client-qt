/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "globaltestenvironment.h"
#include "positioning.h"
#include "positionmanager.h"

#include <gtest/gtest.h>

#include <QDateTime>
#include <QGeoPositionInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSignalSpy>
#include <QTest>

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

class PositionReceptionFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        QSignalSpy accountAddedSpy(globalEnv.accountAdapter.get(), &AccountAdapter::accountAdded);
        globalEnv.accountAdapter->createJamiAccount(
            {{"alias", "Walker"}, {"registeredName", ""}, {"password", ""}, {"archivePath", ""}, {"avatar", ""}});
        ASSERT_TRUE(accountAddedSpy.wait(30000));
        accountId = accountAddedSpy.takeFirst().at(0).toString();
    }

    void TearDown() override
    {
        globalEnv.lrcInstance->accountModel().removeAccount(accountId);
        QTRY_COMPARE_WITH_TIMEOUT(globalEnv.lrcInstance->accountModel().getAccountCount(), 0, 10000);
    }

    // As the daemon passes on a location message from a contact.
    void receive(const QString& peer, const QString& body)
    {
        Q_EMIT globalEnv.lrcInstance->accountModel().newPosition(accountId, peer, body, 0, "");
    }

    QString accountId;
};

TEST_F(PositionReceptionFixture, AnAccountKnowsWhileAContactSendsItsPosition)
{
    PositionManager positions(globalEnv.settingsManager.get(), globalEnv.systemTray.get(), globalEnv.lrcInstance.data());
    const QString peer = QString("7").repeated(40);
    EXPECT_FALSE(positions.isReceivingPositions(accountId));

    receive(peer, R"({"type":"Position","lat":45.5,"long":-73.6,"time":1000})");
    EXPECT_TRUE(positions.isReceivingPositions(accountId));
    EXPECT_FALSE(positions.isReceivingPositions("another-account"));

    receive(peer, R"({"type":"Stop","time":2000})");
    EXPECT_FALSE(positions.isReceivingPositions(accountId));
}
