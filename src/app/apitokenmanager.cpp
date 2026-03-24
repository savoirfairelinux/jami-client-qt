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

#include "apitokenmanager.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QLoggingCategory>
#include <QRandomGenerator>
#include <QStandardPaths>
#include <QUuid>

Q_LOGGING_CATEGORY(tokenLog, "api.tokens")

// ── TokenInfo serialization ─────────────────────────────────────────

QJsonObject
ApiTokenManager::TokenInfo::toJson() const
{
    QJsonObject obj;
    obj["id"] = id;
    obj["accountId"] = accountId;
    obj["label"] = label;
    obj["scopes"] = QJsonArray::fromStringList(scopes);
    obj["createdAt"] = createdAt.toString(Qt::ISODateWithMs);
    if (expiresAt.isValid())
        obj["expiresAt"] = expiresAt.toString(Qt::ISODateWithMs);
    return obj;
}

ApiTokenManager::TokenInfo
ApiTokenManager::TokenInfo::fromJson(const QJsonObject& obj)
{
    TokenInfo info;
    info.id = obj["id"].toString();
    info.accountId = obj["accountId"].toString();
    info.label = obj["label"].toString();
    for (const auto& s : obj["scopes"].toArray())
        info.scopes.append(s.toString());
    info.createdAt = QDateTime::fromString(obj["createdAt"].toString(), Qt::ISODateWithMs);
    if (obj.contains("expiresAt"))
        info.expiresAt = QDateTime::fromString(obj["expiresAt"].toString(), Qt::ISODateWithMs);
    return info;
}

// ── ApiTokenManager ─────────────────────────────────────────────────

ApiTokenManager::ApiTokenManager(QObject* parent)
    : QObject(parent)
{
    load();
}

QString
ApiTokenManager::storagePath() const
{
    auto dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(dataDir);
    return dataDir + QStringLiteral("/api-tokens.json");
}

void
ApiTokenManager::load()
{
    QFile file(storagePath());
    if (!file.open(QIODevice::ReadOnly)) {
        qCDebug(tokenLog) << "No existing token store at" << storagePath();
        return;
    }

    auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) {
        qCWarning(tokenLog) << "Invalid token store format";
        return;
    }

    tokens_.clear();
    auto root = doc.object();
    auto entries = root["tokens"].toObject();
    for (auto it = entries.begin(); it != entries.end(); ++it) {
        tokens_[it.key()] = TokenInfo::fromJson(it.value().toObject());
    }
    qCInfo(tokenLog) << "Loaded" << tokens_.size() << "API tokens";
}

void
ApiTokenManager::save() const
{
    QJsonObject entries;
    for (auto it = tokens_.constBegin(); it != tokens_.constEnd(); ++it) {
        entries[it.key()] = it.value().toJson();
    }

    QJsonObject root;
    root["tokens"] = entries;

    QFile file(storagePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qCWarning(tokenLog) << "Failed to save token store:" << file.errorString();
        return;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
}

QString
ApiTokenManager::hashToken(const QString& rawToken)
{
    return QString::fromLatin1(
        QCryptographicHash::hash(rawToken.toUtf8(), QCryptographicHash::Sha256).toHex());
}

QString
ApiTokenManager::generateRawToken()
{
    QByteArray bytes(32, 0);
    QRandomGenerator::securelySeeded().fillRange(
        reinterpret_cast<quint32*>(bytes.data()),
        bytes.size() / static_cast<int>(sizeof(quint32)));
    return QStringLiteral("jm_sk_") + QString::fromLatin1(bytes.toHex());
}

ApiTokenManager::CreateResult
ApiTokenManager::createToken(const QString& accountId,
                             const QString& label,
                             const QStringList& scopes,
                             int lifetimeDays)
{
    auto rawToken = generateRawToken();
    auto hash = hashToken(rawToken);

    TokenInfo info;
    info.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    info.accountId = accountId;
    info.label = label;
    info.scopes = scopes;
    info.createdAt = QDateTime::currentDateTimeUtc();
    if (lifetimeDays > 0)
        info.expiresAt = info.createdAt.addDays(lifetimeDays);

    tokens_[hash] = info;
    save();

    qCInfo(tokenLog) << "Created token" << info.id << "for account" << accountId;
    Q_EMIT tokenCreated(info.id, accountId);

    return {rawToken, info};
}

const ApiTokenManager::TokenInfo*
ApiTokenManager::validateToken(const QString& rawToken) const
{
    auto hash = hashToken(rawToken);
    auto it = tokens_.constFind(hash);
    if (it == tokens_.constEnd())
        return nullptr;

    // Check expiration
    if (it->expiresAt.isValid() && QDateTime::currentDateTimeUtc() > it->expiresAt) {
        qCDebug(tokenLog) << "Token" << it->id << "has expired";
        return nullptr;
    }

    return &(*it);
}

bool
ApiTokenManager::revokeToken(const QString& tokenId)
{
    for (auto it = tokens_.begin(); it != tokens_.end(); ++it) {
        if (it->id == tokenId) {
            auto accountId = it->accountId;
            tokens_.erase(it);
            save();
            qCInfo(tokenLog) << "Revoked token" << tokenId;
            Q_EMIT tokenRevoked(tokenId, accountId);
            return true;
        }
    }
    return false;
}

QList<ApiTokenManager::TokenInfo>
ApiTokenManager::listTokens(const QString& accountId) const
{
    QList<TokenInfo> result;
    for (const auto& info : tokens_) {
        if (accountId.isEmpty() || info.accountId == accountId)
            result.append(info);
    }
    return result;
}

void
ApiTokenManager::revokeAllTokens(const QString& accountId)
{
    auto it = tokens_.begin();
    while (it != tokens_.end()) {
        if (it->accountId == accountId) {
            auto id = it->id;
            it = tokens_.erase(it);
            Q_EMIT tokenRevoked(id, accountId);
        } else {
            ++it;
        }
    }
    save();
}
