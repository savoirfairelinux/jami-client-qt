/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "currentaccounttomigrate.h"

#include "lrcinstance.h"

#include "api/account.h"
#include "api/contact.h"
#include "api/conversation.h"
#include "api/devicemodel.h"

CurrentAccountToMigrate::CurrentAccountToMigrate(LRCInstance* instance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(instance)
{
    auto accountList = lrcInstance_->accountModel().getAccountList();

    for (const QString& i : accountList) {
        auto accountStatus = lrcInstance_->accountModel().getAccountInfo(i).status;
        if (accountStatus == lrc::api::account::Status::ERROR_NEED_MIGRATION) {
            accountToMigrateList_.append(i);
        }
    }

    if (accountToMigrateList_.size()) {
        connectMigrationEnded();
        updateData();
    }

    connect(&lrcInstance_->accountModel(),
            &AccountModel::accountStatusChanged,
            this,
            &CurrentAccountToMigrate::slotAccountStatusChanged);
    connect(&lrcInstance_->accountModel(),
            &AccountModel::accountAdded,
            this,
            &CurrentAccountToMigrate::slotAccountStatusChanged);
    connect(&lrcInstance_->accountModel(),
            &AccountModel::accountRemoved,
            this,
            &CurrentAccountToMigrate::slotAccountRemoved);
}

CurrentAccountToMigrate::~CurrentAccountToMigrate() {}

void
CurrentAccountToMigrate::removeCurrentAccountToMigrate()
{
    lrcInstance_->accountModel().removeAccount(get_accountId());
}

void
CurrentAccountToMigrate::updateData()
{
    set_accountToMigrateListSize(accountToMigrateList_.size());
    if (get_accountToMigrateListSize() == 0)
        return;

    QString accountId = accountToMigrateList_.at(0);

    auto& avatarInfo = lrcInstance_->accountModel().getAccountInfo(accountId);

    set_accountId(accountId);
    set_managerUsername(avatarInfo.confProperties.managerUsername);
    set_managerUri(avatarInfo.confProperties.managerUri);
    set_username(avatarInfo.confProperties.username);
    set_alias(lrcInstance_->accountModel().getAccountInfo(accountId).profileInfo.alias);
}

void
CurrentAccountToMigrate::connectMigrationEnded()
{
    migrationEndedConnection_ = connect(
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::migrationEnded,
        this,
        [this](const QString& accountId, bool ok) {
            if (ok && accountToMigrateList_.removeOne(accountId)) {
                updateData();
            }

            if (accountToMigrateList_.isEmpty()) {
                disconnect(migrationEndedConnection_);
                Q_EMIT allMigrationsFinished();
                return;
            }

            Q_EMIT migrationEnded(ok);
        },
        Qt::ConnectionType::QueuedConnection);
}

void
CurrentAccountToMigrate::slotAccountStatusChanged(const QString& accountId)
{
    try {
        auto& accountInfo = lrcInstance_->getAccountInfo(accountId);
        if (accountInfo.status == lrc::api::account::Status::ERROR_NEED_MIGRATION) {
            accountToMigrateList_.append(accountId);
            updateData();
            connectMigrationEnded();
            Q_EMIT accountNeedsMigration(accountId);
        }
    } catch (...) {
    }
}

void
CurrentAccountToMigrate::slotAccountRemoved(const QString& accountId)
{
    if (accountToMigrateList_.isEmpty() || accountToMigrateList_.indexOf(accountId) < 0)
        return;
    if (accountToMigrateList_.removeOne(accountId))
        updateData();
    if (accountToMigrateList_.isEmpty())
        Q_EMIT allMigrationsFinished();
    else
        Q_EMIT currentAccountToMigrateRemoved();
}