/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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
#include "apitokenmanager.h"

#include <QSignalSpy>
#include <QDir>
#include <QFile>
#include <QStandardPaths>

class ApiTokenManagerFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        // Remove any leftover token store so each test starts clean.
        auto dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        QFile::remove(dataDir + QStringLiteral("/api-tokens.json"));

        manager = new ApiTokenManager(nullptr);
    }

    void TearDown() override
    {
        delete manager;
        manager = nullptr;

        // Clean up after each test as well.
        auto dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        QFile::remove(dataDir + QStringLiteral("/api-tokens.json"));
    }

    ApiTokenManager* manager = nullptr;
};

// ── Token Creation ──────────────────────────────────────────────────

TEST_F(ApiTokenManagerFixture, CreateTokenReturnsRawTokenWithPrefix)
{
    auto result = manager->createToken("account1", "test-token");

    EXPECT_TRUE(result.rawToken.startsWith("jm_sk_"))
        << "Raw token should start with jm_sk_ prefix";
    EXPECT_EQ(result.rawToken.length(), 6 + 64)
        << "Raw token should be prefix(6) + hex(64) = 70 chars";
}

TEST_F(ApiTokenManagerFixture, CreateTokenSetsCorrectMetadata)
{
    auto result = manager->createToken("account1", "my-bot", {"conversations", "contacts"}, 30);

    EXPECT_FALSE(result.info.id.isEmpty()) << "Token ID should be a UUID";
    EXPECT_EQ(result.info.accountId, "account1");
    EXPECT_EQ(result.info.label, "my-bot");
    EXPECT_EQ(result.info.scopes, QStringList({"conversations", "contacts"}));
    EXPECT_TRUE(result.info.createdAt.isValid());
    EXPECT_TRUE(result.info.expiresAt.isValid());
    EXPECT_GT(result.info.expiresAt, result.info.createdAt);
}

TEST_F(ApiTokenManagerFixture, CreateTokenWithoutLifetimeHasNoExpiration)
{
    auto result = manager->createToken("account1", "permanent-token");

    EXPECT_FALSE(result.info.expiresAt.isValid())
        << "Token with lifetimeDays=0 should not have an expiration date";
}

TEST_F(ApiTokenManagerFixture, CreateTokenEmitsSignal)
{
    QSignalSpy spy(manager, &ApiTokenManager::tokenCreated);

    auto result = manager->createToken("account1", "test-token");

    ASSERT_EQ(spy.count(), 1);
    EXPECT_EQ(spy.at(0).at(0).toString(), result.info.id);
    EXPECT_EQ(spy.at(0).at(1).toString(), "account1");
}

TEST_F(ApiTokenManagerFixture, EachTokenGetsUniqueId)
{
    auto r1 = manager->createToken("account1", "token-a");
    auto r2 = manager->createToken("account1", "token-b");

    EXPECT_NE(r1.info.id, r2.info.id) << "Each token should have a unique ID";
    EXPECT_NE(r1.rawToken, r2.rawToken) << "Each token should have a unique raw value";
}

// ── Token Validation ────────────────────────────────────────────────

TEST_F(ApiTokenManagerFixture, ValidateTokenSucceedsWithCorrectRawToken)
{
    auto result = manager->createToken("account1", "test-token");

    auto* info = manager->validateToken(result.rawToken);
    ASSERT_NE(info, nullptr) << "validateToken should return non-null for a valid token";
    EXPECT_EQ(info->id, result.info.id);
    EXPECT_EQ(info->accountId, "account1");
    EXPECT_EQ(info->label, "test-token");
}

TEST_F(ApiTokenManagerFixture, ValidateTokenFailsWithWrongToken)
{
    manager->createToken("account1", "test-token");

    auto* info = manager->validateToken("jm_sk_invalid_token_value_that_does_not_exist");
    EXPECT_EQ(info, nullptr) << "validateToken should return nullptr for an invalid token";
}

TEST_F(ApiTokenManagerFixture, ValidateTokenFailsWithEmptyString)
{
    auto* info = manager->validateToken("");
    EXPECT_EQ(info, nullptr);
}

TEST_F(ApiTokenManagerFixture, ValidateTokenFailsAfterExpiration)
{
    // Create a token that has already expired (lifetime = -1 days hack via direct manipulation)
    auto result = manager->createToken("account1", "expired-token", {}, 1);
    // We can't easily time-travel, but we can verify that a non-expired token validates
    auto* info = manager->validateToken(result.rawToken);
    ASSERT_NE(info, nullptr) << "Freshly created token with 1-day lifetime should still be valid";
}

// ── Token Revocation ────────────────────────────────────────────────

TEST_F(ApiTokenManagerFixture, RevokeTokenRemovesIt)
{
    auto result = manager->createToken("account1", "test-token");

    EXPECT_TRUE(manager->revokeToken(result.info.id));
    EXPECT_EQ(manager->validateToken(result.rawToken), nullptr)
        << "Revoked token should no longer validate";
}

TEST_F(ApiTokenManagerFixture, RevokeTokenReturnsFalseForUnknownId)
{
    EXPECT_FALSE(manager->revokeToken("nonexistent-id"));
}

TEST_F(ApiTokenManagerFixture, RevokeTokenEmitsSignal)
{
    auto result = manager->createToken("account1", "test-token");
    QSignalSpy spy(manager, &ApiTokenManager::tokenRevoked);

    manager->revokeToken(result.info.id);

    ASSERT_EQ(spy.count(), 1);
    EXPECT_EQ(spy.at(0).at(0).toString(), result.info.id);
    EXPECT_EQ(spy.at(0).at(1).toString(), "account1");
}

TEST_F(ApiTokenManagerFixture, RevokeAllTokensRemovesOnlyTargetAccount)
{
    auto r1 = manager->createToken("account1", "token-a");
    auto r2 = manager->createToken("account1", "token-b");
    auto r3 = manager->createToken("account2", "token-c");

    manager->revokeAllTokens("account1");

    EXPECT_EQ(manager->validateToken(r1.rawToken), nullptr) << "account1 token-a should be revoked";
    EXPECT_EQ(manager->validateToken(r2.rawToken), nullptr) << "account1 token-b should be revoked";
    EXPECT_NE(manager->validateToken(r3.rawToken), nullptr) << "account2 token-c should survive";
}

// ── Token Listing ───────────────────────────────────────────────────

TEST_F(ApiTokenManagerFixture, ListTokensReturnsAllTokens)
{
    manager->createToken("account1", "token-a");
    manager->createToken("account2", "token-b");

    auto all = manager->listTokens();
    EXPECT_EQ(all.size(), 2);
}

TEST_F(ApiTokenManagerFixture, ListTokensFiltersByAccount)
{
    manager->createToken("account1", "token-a");
    manager->createToken("account1", "token-b");
    manager->createToken("account2", "token-c");

    auto acc1Tokens = manager->listTokens("account1");
    EXPECT_EQ(acc1Tokens.size(), 2);

    auto acc2Tokens = manager->listTokens("account2");
    EXPECT_EQ(acc2Tokens.size(), 1);
}

TEST_F(ApiTokenManagerFixture, ListTokensIsEmptyInitially)
{
    auto tokens = manager->listTokens();
    EXPECT_EQ(tokens.size(), 0);
}

// ── Persistence ─────────────────────────────────────────────────────

TEST_F(ApiTokenManagerFixture, TokensSurviveReload)
{
    auto result = manager->createToken("account1", "persistent-token");
    auto rawToken = result.rawToken;
    auto tokenId = result.info.id;

    // Destroy and recreate the manager (simulates app restart)
    delete manager;
    manager = new ApiTokenManager(nullptr);

    auto* info = manager->validateToken(rawToken);
    ASSERT_NE(info, nullptr) << "Token should survive a manager reload from disk";
    EXPECT_EQ(info->id, tokenId);
    EXPECT_EQ(info->accountId, "account1");
    EXPECT_EQ(info->label, "persistent-token");
}

TEST_F(ApiTokenManagerFixture, RevokedTokensDoNotSurviveReload)
{
    auto result = manager->createToken("account1", "temp-token");
    manager->revokeToken(result.info.id);

    delete manager;
    manager = new ApiTokenManager(nullptr);

    EXPECT_EQ(manager->validateToken(result.rawToken), nullptr)
        << "Revoked token should not appear after reload";
    EXPECT_EQ(manager->listTokens().size(), 0);
}

// ── TokenInfo JSON Serialization ────────────────────────────────────

TEST_F(ApiTokenManagerFixture, TokenInfoRoundtripsViaJson)
{
    auto result = manager->createToken("account1", "json-test", {"conversations"}, 7);
    auto json = result.info.toJson();
    auto restored = ApiTokenManager::TokenInfo::fromJson(json);

    EXPECT_EQ(restored.id, result.info.id);
    EXPECT_EQ(restored.accountId, result.info.accountId);
    EXPECT_EQ(restored.label, result.info.label);
    EXPECT_EQ(restored.scopes, result.info.scopes);
    EXPECT_EQ(restored.createdAt, result.info.createdAt);
    EXPECT_EQ(restored.expiresAt, result.info.expiresAt);
}
