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

#include "apitokenlistmodel.h"
#include "apitokenmanager.h"

ApiTokenListModel::ApiTokenListModel(ApiTokenManager* manager, QObject* parent)
    : QAbstractListModel(parent)
    , manager_(manager)
{
    connect(manager_, &ApiTokenManager::tokenCreated, this, &ApiTokenListModel::refresh);
    connect(manager_, &ApiTokenManager::tokenRevoked, this, &ApiTokenListModel::refresh);
}

int
ApiTokenListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent)
    return tokens_.size();
}

QVariant
ApiTokenListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= tokens_.size())
        return {};

    const auto& t = tokens_.at(index.row());
    switch (role) {
    case TokenId:
        return t.id;
    case AccountId:
        return t.accountId;
    case Label:
        return t.label;
    case Scopes:
        return t.scopes.join(", ");
    case CreatedAt:
        return t.createdAt;
    case ExpiresAt:
        return t.expiresAt;
    }
    return {};
}

QHash<int, QByteArray>
ApiTokenListModel::roleNames() const
{
    return {
        {TokenId, "tokenId"},
        {AccountId, "tokenAccountId"},
        {Label, "tokenLabel"},
        {Scopes, "tokenScopes"},
        {CreatedAt, "tokenCreatedAt"},
        {ExpiresAt, "tokenExpiresAt"},
    };
}

QString
ApiTokenListModel::accountId() const
{
    return accountId_;
}

void
ApiTokenListModel::setAccountId(const QString& accountId)
{
    if (accountId_ == accountId)
        return;
    accountId_ = accountId;
    Q_EMIT accountIdChanged();
    refresh();
}

QString
ApiTokenListModel::createToken(const QString& label, int lifetimeDays)
{
    if (accountId_.isEmpty())
        return {};
    auto result = manager_->createToken(accountId_, label, {}, lifetimeDays);
    return result.rawToken;
}

bool
ApiTokenListModel::revokeToken(const QString& tokenId)
{
    return manager_->revokeToken(tokenId);
}

void
ApiTokenListModel::refresh()
{
    beginResetModel();
    tokens_.clear();
    auto infos = manager_->listTokens(accountId_);
    for (const auto& info : infos) {
        tokens_.append({info.id,
                        info.accountId,
                        info.label,
                        info.scopes,
                        info.createdAt.toLocalTime().toString("yyyy-MM-dd hh:mm"),
                        info.expiresAt.isValid()
                            ? info.expiresAt.toLocalTime().toString("yyyy-MM-dd hh:mm")
                            : QString()});
    }
    endResetModel();
}
