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

#pragma once

#include <QObject>
#include <QHttpServer>
#include <QWebSocket>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

#include <memory>

class LRCInstance;
class ApiTokenManager;

/*!
 * \brief Embedded HTTP+WebSocket API server for the Jami Qt client.
 *
 * Exposes a local REST API compatible with the \@jami/sdk, allowing
 * external tools (bots, scripts, web UIs) to interact with the running
 * Jami client over HTTP on localhost.
 */
class ApiServer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(quint16 port READ port NOTIFY runningChanged)

public:
    explicit ApiServer(LRCInstance* instance, QObject* parent = nullptr);
    ~ApiServer();

    /// Start listening on the given port (localhost only). Returns true on success.
    Q_INVOKABLE bool start(quint16 port = 8080);
    /// Stop the server.
    Q_INVOKABLE void stop();
    /// Returns true if the server is currently listening.
    bool running() const;
    /// Returns the port the server is currently listening on, or 0 if not running.
    quint16 port() const;
    /// Returns the token manager for external access (e.g. QML).
    ApiTokenManager* tokenManager() const;
    /// Set an external token manager (instead of creating one internally).
    void setTokenManager(ApiTokenManager* manager);

Q_SIGNALS:
    void runningChanged();
    void started(quint16 port);
    void stopped();

private:
    // Route registration
    void setupAccountRoutes();
    void setupConversationRoutes();
    void setupContactRoutes();
    void setupCallRoutes();
    void setupNameserverRoutes();
    void setupTokenRoutes();

    // WebSocket
    void setupWebSocket();
    void onNewWebSocketConnection();
    void broadcastEvent(const QString& type, const QJsonObject& data);

    // Auth — returns the account ID the token is scoped to (empty = all accounts).
    // Sets ok to true if authenticated, false otherwise.
    QString authenticate(const QHttpServerRequest& request, bool& ok) const;
    QString authenticateWs(const QString& token, bool& ok) const;

    // Helpers
    QString resolveCurrentAccountId(const QString& tokenScope) const;
    QJsonObject accountToCompatJson(const QString& accountId) const;
    QJsonObject conversationSummaryToCompatJson(const QString& accountId, const QString& convId) const;
    QJsonObject contactToCompatJson(const QString& accountId,
                                    const QString& uri,
                                    const QString& conversationId = {}) const;

    LRCInstance* lrcInstance_;
    std::unique_ptr<ApiTokenManager> tokenManager_;
    ApiTokenManager* externalTokenManager_ = nullptr;
    std::unique_ptr<QHttpServer> httpServer_;
    QTcpServer* tcpServer_ = nullptr; // owned by httpServer_ after bind()
    QList<QWebSocket*> wsClients_;
};
