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
#include "apiserver.h"
#include "apitokenmanager.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSignalSpy>
#include <QStandardPaths>
#include <QTest>
#include <QWebSocket>

// ── Helper ──────────────────────────────────────────────────────────

// Synchronous HTTP request helper — waits for the reply and returns body + status.
struct HttpResponse
{
    int statusCode = 0;
    QByteArray body;
    QJsonDocument json() const { return QJsonDocument::fromJson(body); }
    QJsonObject jsonObj() const { return json().object(); }
    QJsonArray jsonArr() const { return json().array(); }
};

static HttpResponse
httpRequest(QNetworkAccessManager* nam,
            const QString& method,
            const QUrl& url,
            const QString& bearerToken = {},
            const QJsonObject& bodyObj = {})
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!bearerToken.isEmpty())
        request.setRawHeader("Authorization", ("Bearer " + bearerToken).toUtf8());

    QNetworkReply* reply = nullptr;
    QByteArray bodyData;
    if (!bodyObj.isEmpty())
        bodyData = QJsonDocument(bodyObj).toJson(QJsonDocument::Compact);

    if (method == "GET")
        reply = nam->get(request);
    else if (method == "HEAD")
        reply = nam->sendCustomRequest(request, "HEAD");
    else if (method == "POST")
        reply = nam->post(request, bodyData);
    else if (method == "PUT")
        reply = nam->put(request, bodyData);
    else if (method == "DELETE")
        reply = nam->deleteResource(request);
    else
        return {};

    // Wait for reply (with timeout)
    QSignalSpy finished(reply, &QNetworkReply::finished);
    finished.wait(5000);

    HttpResponse resp;
    resp.statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    resp.body = reply->readAll();
    reply->deleteLater();
    return resp;
}

// ── Fixture ─────────────────────────────────────────────────────────

class ApiServerFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        // Ensure a clean token store for each test.
        auto dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        QFile::remove(dataDir + QStringLiteral("/api-tokens.json"));

        nam = new QNetworkAccessManager();
        server = new ApiServer(globalEnv.lrcInstance.data(), nullptr);
        ASSERT_TRUE(server->start(0)); // port 0 = let OS pick a free port
        baseUrl = QStringLiteral("http://127.0.0.1:%1").arg(server->port());
        masterToken = server->apiToken();
    }

    void TearDown() override
    {
        server->stop();
        delete server;
        delete nam;

        auto dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        QFile::remove(dataDir + QStringLiteral("/api-tokens.json"));
    }

    HttpResponse get(const QString& path, const QString& token = {})
    {
        return httpRequest(nam, "GET", QUrl(baseUrl + path), token.isEmpty() ? masterToken : token);
    }

    HttpResponse post(const QString& path, const QJsonObject& body = {}, const QString& token = {})
    {
        return httpRequest(nam, "POST", QUrl(baseUrl + path), token.isEmpty() ? masterToken : token, body);
    }

    HttpResponse put(const QString& path, const QJsonObject& body = {}, const QString& token = {})
    {
        return httpRequest(nam, "PUT", QUrl(baseUrl + path), token.isEmpty() ? masterToken : token, body);
    }

    HttpResponse del(const QString& path, const QString& token = {})
    {
        return httpRequest(nam, "DELETE", QUrl(baseUrl + path), token.isEmpty() ? masterToken : token);
    }

    HttpResponse getNoAuth(const QString& path)
    {
        return httpRequest(nam, "GET", QUrl(baseUrl + path));
    }

    HttpResponse head(const QString& path, const QString& token = {})
    {
        return httpRequest(nam, "HEAD", QUrl(baseUrl + path), token.isEmpty() ? masterToken : token);
    }

    HttpResponse headNoAuth(const QString& path)
    {
        return httpRequest(nam, "HEAD", QUrl(baseUrl + path));
    }

    QString createSipAccount()
    {
        QSignalSpy accountAddedSpy(&globalEnv.lrcInstance->accountModel(), &AccountModel::accountAdded);
        globalEnv.accountAdapter->createSIPAccount(QVariantMap());
        EXPECT_TRUE(accountAddedSpy.wait(10000));
        EXPECT_EQ(accountAddedSpy.count(), 1);

        const auto args = accountAddedSpy.takeFirst();
        const auto accountId = args.at(0).toString();
        globalEnv.lrcInstance->set_currentAccountId(accountId);
        QTest::qWait(250);
        return accountId;
    }

    ApiServer* server = nullptr;
    QNetworkAccessManager* nam = nullptr;
    QString baseUrl;
    QString masterToken;
};

// ── Server Lifecycle ────────────────────────────────────────────────

TEST_F(ApiServerFixture, ServerStartsAndReportsPort)
{
    EXPECT_GT(server->port(), 0) << "Server should report a valid port";
}

TEST_F(ApiServerFixture, MasterTokenHasCorrectFormat)
{
    EXPECT_TRUE(masterToken.startsWith("jm_sk_"));
    EXPECT_EQ(masterToken.length(), 6 + 64);
}

TEST_F(ApiServerFixture, ServerStopResetsPort)
{
    server->stop();
    EXPECT_EQ(server->port(), 0);
}

// ── Authentication ──────────────────────────────────────────────────

TEST_F(ApiServerFixture, RequestWithoutTokenReturns401)
{
    auto resp = getNoAuth("/api/account");
    EXPECT_EQ(resp.statusCode, 401);
}

TEST_F(ApiServerFixture, RequestWithInvalidTokenReturns401)
{
    auto resp = httpRequest(nam, "GET", QUrl(baseUrl + "/api/account"), "jm_sk_bogus");
    EXPECT_EQ(resp.statusCode, 401);
}

TEST_F(ApiServerFixture, RequestWithMasterTokenReturns200)
{
    const auto accountId = createSipAccount();
    auto resp = get("/api/account");
    EXPECT_EQ(resp.statusCode, 200);
}

// ── Account Routes ──────────────────────────────────────────────────

TEST_F(ApiServerFixture, GetCurrentAccountUsesJamiWebCompatibleShape)
{
    const auto accountId = createSipAccount();

    auto resp = get("/api/account");
    EXPECT_EQ(resp.statusCode, 200);

    const auto obj = resp.jsonObj();
    EXPECT_EQ(obj["id"].toString(), accountId);
    EXPECT_TRUE(obj.contains("details"));
    EXPECT_TRUE(obj.contains("volatileDetails"));
    EXPECT_TRUE(obj.contains("devices"));
}

// ── Token Management Routes ─────────────────────────────────────────

TEST_F(ApiServerFixture, CreateTokenReturns201)
{
    const auto accountId = createSipAccount();

    QJsonObject body;
    body["name"] = "test-bot";
    body["scopes"] = QJsonArray({"conversations:read"});

    auto resp = post("/api/tokens", body);
    EXPECT_EQ(resp.statusCode, 201);

    auto obj = resp.jsonObj();
    EXPECT_TRUE(obj.contains("token")) << "Response should contain the raw token";
    EXPECT_TRUE(obj["token"].toString().startsWith("jm_sk_"));
    EXPECT_TRUE(obj.contains("info"));
    EXPECT_EQ(obj["info"].toObject()["accountId"].toString(), accountId);
    EXPECT_EQ(obj["info"].toObject()["name"].toString(), "test-bot");
}

TEST_F(ApiServerFixture, ListTokensReturnsCreatedTokens)
{
    const auto accountId = createSipAccount();

    QJsonObject body;
    body["name"] = "token-a";
    post("/api/tokens", body);
    body["name"] = "token-b";
    post("/api/tokens", body);

    auto resp = get("/api/tokens");
    EXPECT_EQ(resp.statusCode, 200);
    EXPECT_EQ(resp.jsonArr().size(), 2);
}

TEST_F(ApiServerFixture, RevokeTokenReturnsOk)
{
    const auto accountId = createSipAccount();

    QJsonObject body;
    body["name"] = "to-revoke";
    auto createResp = post("/api/tokens", body);
    auto tokenId = createResp.jsonObj()["info"].toObject()["id"].toString();

    auto resp = del("/api/tokens/" + tokenId);
    EXPECT_EQ(resp.statusCode, 204);

    // Verify it's gone from the list
    auto listResp = get("/api/tokens");
    EXPECT_EQ(listResp.jsonArr().size(), 0);
}

TEST_F(ApiServerFixture, RevokeNonExistentTokenReturns404)
{
    auto resp = del("/api/tokens/nonexistent-id");
    EXPECT_EQ(resp.statusCode, 404);
}

TEST_F(ApiServerFixture, JamiWebCompatibleTokenRoutesUseNameAndPrefix)
{
    const auto accountId = createSipAccount();

    QJsonObject body;
    body["name"] = "web-bot";
    body["scopes"] = QJsonArray({"conversations:read", "conversations:write"});
    body["expiresIn"] = 3600;

    auto createResp = post("/api/tokens", body);
    EXPECT_EQ(createResp.statusCode, 201);

    const auto createObj = createResp.jsonObj();
    EXPECT_TRUE(createObj["token"].toString().startsWith("jm_sk_"));
    EXPECT_EQ(createObj["info"].toObject()["accountId"].toString(), accountId);
    EXPECT_EQ(createObj["info"].toObject()["name"].toString(), "web-bot");
    EXPECT_TRUE(createObj["info"].toObject()["prefix"].toString().startsWith("jm_sk_"));
    EXPECT_TRUE(createObj["info"].toObject().contains("expiresAt"));

    auto listResp = get("/api/tokens");
    EXPECT_EQ(listResp.statusCode, 200);
    ASSERT_EQ(listResp.jsonArr().size(), 1);
    EXPECT_EQ(listResp.jsonArr().at(0).toObject()["name"].toString(), "web-bot");

    auto revokeResp = del("/api/tokens/" + createObj["info"].toObject()["id"].toString());
    EXPECT_EQ(revokeResp.statusCode, 204);

    auto listAfterDelete = get("/api/tokens");
    EXPECT_EQ(listAfterDelete.statusCode, 200);
    EXPECT_EQ(listAfterDelete.jsonArr().size(), 0);
}

// ── Token Revocation ────────────────────────────────────────────────

TEST_F(ApiServerFixture, RevokedTokenCanNoLongerAuthenticate)
{
    const auto accountId = createSipAccount();

    QJsonObject body;
    body["name"] = "temp-token";
    auto createResp = post("/api/tokens", body);
    auto rawToken = createResp.jsonObj()["token"].toString();
    auto tokenId = createResp.jsonObj()["info"].toObject()["id"].toString();

    // Verify token works
    auto resp1 = get("/api/account", rawToken);
    EXPECT_EQ(resp1.statusCode, 200);

    // Revoke it
    del("/api/tokens/" + tokenId);

    // Verify token no longer works
    auto resp2 = get("/api/account", rawToken);
    EXPECT_EQ(resp2.statusCode, 401);
}

// ── Nameserver Routes ──────────────────────────────────────────────

TEST_F(ApiServerFixture, NameserverNameLookupInvalidUsernameReturns400)
{
    auto resp = get("/api/ns/name/====");
    EXPECT_EQ(resp.statusCode, 400);

    const auto obj = resp.jsonObj();
    EXPECT_EQ(obj["error"].toString(), "Invalid username");
}

TEST_F(ApiServerFixture, NameserverNameLookupAllowsNoAuth)
{
    auto resp = getNoAuth("/api/ns/name/====");
    EXPECT_EQ(resp.statusCode, 400);

    const auto obj = resp.jsonObj();
    EXPECT_EQ(obj["error"].toString(), "Invalid username");
}

TEST_F(ApiServerFixture, NameserverNameLookupRejectsInvalidToken)
{
    auto resp = httpRequest(nam, "GET", QUrl(baseUrl + "/api/ns/name/===="), "jm_sk_bogus");
    EXPECT_EQ(resp.statusCode, 401);
}

TEST_F(ApiServerFixture, NameserverNameHeadInvalidUsernameReturns400)
{
    auto resp = headNoAuth("/api/ns/name/====");
    EXPECT_EQ(resp.statusCode, 400);
}

TEST_F(ApiServerFixture, NameserverAddressLookupInvalidAddressReturns400)
{
    auto resp = getNoAuth("/api/ns/address/====");
    EXPECT_EQ(resp.statusCode, 400);

    const auto obj = resp.jsonObj();
    EXPECT_EQ(obj["error"].toString(), "Invalid address");
}

// ── WebSocket ───────────────────────────────────────────────────────

TEST_F(ApiServerFixture, WebSocketRejectsInvalidToken)
{
    auto wsPort = server->port();
    QWebSocket ws;
    QSignalSpy disconnectedSpy(&ws, &QWebSocket::disconnected);

    ws.open(QUrl(QStringLiteral("ws://127.0.0.1:%1/api?accessToken=invalid").arg(wsPort)));

    // Should disconnect quickly
    disconnectedSpy.wait(3000);
    EXPECT_GE(disconnectedSpy.count(), 1)
        << "WebSocket with invalid token should be disconnected";
}

TEST_F(ApiServerFixture, WebSocketAcceptsMasterToken)
{
    auto wsPort = server->port();
    QWebSocket ws;
    QSignalSpy connectedSpy(&ws, &QWebSocket::connected);

    ws.open(QUrl(QStringLiteral("ws://127.0.0.1:%1/api?accessToken=%2").arg(wsPort).arg(masterToken)));

    connectedSpy.wait(3000);
    EXPECT_EQ(connectedSpy.count(), 1)
        << "WebSocket with valid master token should connect";

    ws.close();
}

TEST_F(ApiServerFixture, WebSocketRejectsLegacyTokenQueryParameter)
{
    auto wsPort = server->port();
    QWebSocket ws;
    QSignalSpy disconnectedSpy(&ws, &QWebSocket::disconnected);

    ws.open(QUrl(QStringLiteral("ws://127.0.0.1:%1/api?token=%2").arg(wsPort).arg(masterToken)));

    disconnectedSpy.wait(3000);
    EXPECT_GE(disconnectedSpy.count(), 1)
        << "WebSocket with legacy token query parameter should be disconnected";
}

// ── Multiple Servers ────────────────────────────────────────────────

TEST_F(ApiServerFixture, CanStartMultipleServersOnDifferentPorts)
{
    ApiServer server2(globalEnv.lrcInstance.data(), nullptr);
    ASSERT_TRUE(server2.start(0));
    EXPECT_NE(server->port(), server2.port());

    auto resp = httpRequest(nam, "GET", QUrl(QStringLiteral("http://127.0.0.1:%1/api/conversations").arg(server2.port())),
                            server2.apiToken());
    EXPECT_EQ(resp.statusCode, 200);

    // Master tokens are different
    EXPECT_NE(server->apiToken(), server2.apiToken());

    // Master token of server1 should NOT work on server2
    auto crossResp = httpRequest(nam, "GET",
                                 QUrl(QStringLiteral("http://127.0.0.1:%1/api/conversations").arg(server2.port())),
                                 server->apiToken());
    EXPECT_EQ(crossResp.statusCode, 401)
        << "Master token from one server should not authenticate on another";

    server2.stop();
}
