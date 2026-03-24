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
#include <QJsonObject>
#include <QJsonArray>
#include <QString>
#include <QMap>
#include <QDateTime>
#include <QStringList>

/*!
 * \brief Manages per-account API tokens with persistent storage.
 *
 * Tokens are stored hashed (SHA-256) on disk. The raw token is only
 * returned once at creation time. Each token is scoped to a specific
 * account and carries an optional set of permissions.
 */
class ApiTokenManager : public QObject
{
    Q_OBJECT

public:
    /// Metadata for a stored token (never contains the raw token).
    struct TokenInfo
    {
        QString id;           // unique token id (UUID)
        QString accountId;    // scoped to this Jami account (empty = all accounts)
        QString label;        // human-readable label
        QStringList scopes;   // e.g. ["conversations", "contacts", "calls"] (empty = all)
        QDateTime createdAt;
        QDateTime expiresAt;  // null = never expires

        QJsonObject toJson() const;
        static TokenInfo fromJson(const QJsonObject& obj);
    };

    /// Result of createToken — the raw token is only available here.
    struct CreateResult
    {
        QString rawToken;   // "jm_sk_<hex>" — returned once, never stored
        TokenInfo info;
    };

    explicit ApiTokenManager(QObject* parent = nullptr);
    ~ApiTokenManager() = default;

    /// Create a new API token scoped to \a accountId.
    CreateResult createToken(const QString& accountId,
                             const QString& label,
                             const QStringList& scopes = {},
                             int lifetimeDays = 0);

    /// Validate a raw token. Returns a pointer to token info if valid, nullptr otherwise.
    const TokenInfo* validateToken(const QString& rawToken) const;

    /// Revoke (delete) a token by its id.
    bool revokeToken(const QString& tokenId);

    /// List all tokens for a given account (or all if accountId is empty).
    QList<TokenInfo> listTokens(const QString& accountId = {}) const;

    /// Remove all tokens for a given account.
    void revokeAllTokens(const QString& accountId);

Q_SIGNALS:
    void tokenCreated(const QString& tokenId, const QString& accountId);
    void tokenRevoked(const QString& tokenId, const QString& accountId);

private:
    void load();
    void save() const;
    QString storagePath() const;
    static QString hashToken(const QString& rawToken);
    static QString generateRawToken();

    // Map: SHA-256 hash -> TokenInfo
    QMap<QString, TokenInfo> tokens_;
};
