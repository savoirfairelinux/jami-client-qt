/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

#include "globaltestenvironment.h"
#include "app/sharedserviceutils.h"
#include "sharedservicesadapter.h"

#include <QSignalSpy>
#include <QTest>
#include <gtest/gtest.h>

TEST(SharedServiceUtils, SanitizesPreferredPorts)
{
    EXPECT_EQ(SharedServiceUtils::sanitizePreferredPort(1023), 0);
    EXPECT_EQ(SharedServiceUtils::sanitizePreferredPort(1024), 1024);
    EXPECT_EQ(SharedServiceUtils::sanitizePreferredPort(65535), 65535);
    EXPECT_EQ(SharedServiceUtils::sanitizePreferredPort(QStringLiteral("65536")), 0);
    EXPECT_EQ(SharedServiceUtils::sanitizePreferredPort(QStringLiteral("not-a-port")), 0);
}

namespace {
const QVariantMap ssh {{"id", "ssh"}, {"name", "SSH"}};
const QVariantMap wiki {{"id", "wiki"}, {"name", "Wiki"}};
const QVariantMap chat {{"id", "chat"}, {"name", "chat"}};
} // namespace

TEST(SharedServiceUtils, GathersTheServicesEachContactOffers)
{
    SharedServiceUtils::OfferedServices offered;
    offered.expect({{"bob-uri", "Bob"}, {"alice-uri", "alice"}});
    EXPECT_TRUE(offered.waiting());

    EXPECT_TRUE(offered.receive("bob-uri", true, {ssh}));
    EXPECT_TRUE(offered.waiting());
    EXPECT_TRUE(offered.receive("alice-uri", true, {wiki, chat}));
    EXPECT_FALSE(offered.waiting());

    // By contact, then by service, whatever their case
    const auto services = offered.services();
    ASSERT_EQ(services.size(), 3);
    EXPECT_EQ(services[0].toMap()["id"], "chat");
    EXPECT_EQ(services[0].toMap()["peerUri"], "alice-uri");
    EXPECT_EQ(services[0].toMap()["peerName"], "alice");
    EXPECT_EQ(services[1].toMap()["id"], "wiki");
    EXPECT_EQ(services[2].toMap()["id"], "ssh");
    EXPECT_EQ(services[2].toMap()["peerUri"], "bob-uri");
    EXPECT_EQ(services[2].toMap()["peerName"], "Bob");
}

TEST(SharedServiceUtils, AContactThatCannotAnswerOffersNothing)
{
    SharedServiceUtils::OfferedServices offered;
    offered.expect({{"bob-uri", "Bob"}});

    EXPECT_TRUE(offered.receive("bob-uri", false, {}));
    EXPECT_FALSE(offered.waiting());
    EXPECT_TRUE(offered.services().isEmpty());
}

TEST(SharedServiceUtils, OnlyTheAwaitedAnswerOfAContactCounts)
{
    SharedServiceUtils::OfferedServices offered;
    offered.expect({{"bob-uri", "Bob"}});

    EXPECT_FALSE(offered.receive("carol-uri", true, {wiki}));
    EXPECT_TRUE(offered.receive("bob-uri", true, {ssh}));
    EXPECT_FALSE(offered.receive("bob-uri", true, {ssh}));
    EXPECT_EQ(offered.services().size(), 1);
}

TEST(SharedServiceUtils, StartingOverForgetsEarlierAnswers)
{
    SharedServiceUtils::OfferedServices offered;
    offered.expect({{"bob-uri", "Bob"}});
    offered.receive("bob-uri", true, {ssh});

    offered.expect({{"bob-uri", "Bob"}});
    EXPECT_TRUE(offered.waiting());
    EXPECT_TRUE(offered.services().isEmpty());
}

class SharedServicesFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        QSignalSpy accountAddedSpy(globalEnv.accountAdapter.get(), &AccountAdapter::accountAdded);
        globalEnv.accountAdapter->createJamiAccount(
            {{"alias", "Visitor"}, {"registeredName", ""}, {"password", ""}, {"archivePath", ""}, {"avatar", ""}});
        ASSERT_TRUE(accountAddedSpy.wait(30000));
        accountId = accountAddedSpy.takeFirst().at(0).toString();
    }

    void TearDown() override
    {
        globalEnv.lrcInstance->accountModel().removeAccount(accountId);
        QTRY_COMPARE_WITH_TIMEOUT(globalEnv.lrcInstance->accountModel().getAccountCount(), 0, 10000);
    }

    QString accountId;
};

TEST_F(SharedServicesFixture, AnAccountWithoutContactsIsOfferedNothingRightAway)
{
    SharedServicesAdapter adapter(globalEnv.lrcInstance.data());

    adapter.refreshOfferedServices(accountId);

    EXPECT_FALSE(adapter.get_loadingOfferedServices());
    EXPECT_TRUE(adapter.get_offeredServices().isEmpty());
}
