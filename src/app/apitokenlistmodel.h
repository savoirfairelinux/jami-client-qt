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

#include <QAbstractListModel>
#include <QObject>

class ApiTokenManager;

/*!
 * \brief QML-facing list model for API tokens.
 *
 * Wraps an ApiTokenManager to expose per-account tokens in a ListView.
 * Set the \c accountId property to filter tokens for a specific account.
 */
class ApiTokenListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString accountId READ accountId WRITE setAccountId NOTIFY accountIdChanged)

public:
    enum Role {
        TokenId = Qt::UserRole + 1,
        AccountId,
        Label,
        Scopes,
        CreatedAt,
        ExpiresAt
    };
    Q_ENUM(Role)

    explicit ApiTokenListModel(ApiTokenManager* manager, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString accountId() const;
    void setAccountId(const QString& accountId);

    /// Create a token and return the raw token string (shown once to the user).
    Q_INVOKABLE QString createToken(const QString& label, int lifetimeDays = 0);

    /// Revoke a token by its id. Returns true on success.
    Q_INVOKABLE bool revokeToken(const QString& tokenId);

Q_SIGNALS:
    void accountIdChanged();

private:
    void refresh();

    ApiTokenManager* manager_;
    QString accountId_;
    struct TokenEntry {
        QString id;
        QString accountId;
        QString label;
        QStringList scopes;
        QString createdAt;
        QString expiresAt;
    };
    QList<TokenEntry> tokens_;
};
