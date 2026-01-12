/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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

#include "accountsettingsmanager.h"
#include "lrcinstance.h"

#include <QApplication>

// X macro to future proof if other keys are needed
#define PROPERTY_KEYS \
    /* key            defaultValue */ \
    X(backgroundUri, "")

AccountSettingsManager::AccountSettingsManager(QObject* parent)
    : QObject {parent}
    , accountSettings_ {new QSettings("jami.net", "Account", this)}
    , accountSettingsPropertyMap_ {this}
{}

void
AccountSettingsManager::initalizeAccountSettings()
{
    auto lrcInstance = qApp->property("LRCInstance").value<LRCInstance*>();

    // The LRC instance has to exists for us to get the currentAccountID
    if (!lrcInstance) {
        qWarning() << "LRCInstance not available!";
        return;
    }

    currentAccountID_ = lrcInstance->get_currentAccountId();

    // Connect the property map's valueChanged signal
    // to the account settings manager's setValue function
    connect(&accountSettingsPropertyMap_,
            &AccountSettingsPropertyMap::valueChanged,
            this,
            &AccountSettingsManager::setValue);

    // Connect the LRC's currentAccountIdChanged signal
    // to the account settings manager's updateCurrentAccount function
    connect(lrcInstance, &LRCInstance::currentAccountIdChanged, this, [this, lrcInstance]() {
        updateCurrentAccount(lrcInstance->get_currentAccountId());
    });

    // Check for an existing config for this account
    if (accountSettings_->allKeys().size() == 0) {
        // No existing file
        qWarning() << "Creating config file for account:" << currentAccountID_;
        accountSettings_->beginGroup(currentAccountID_);
#define X(key, defaultValue) accountSettings_->setValue(#key, defaultValue);
        PROPERTY_KEYS
#undef X
        accountSettings_->endGroup();
        // Force writing to the configuration file for immediate access
        accountSettings_->sync();

        // Populate the property map
#define X(key, defaultValue) \
    accountSettingsPropertyMap_ \
        .setAccountSettingProperty(#key, accountSettings_->value(currentAccountID_ + "/" + #key).toString());
        PROPERTY_KEYS
#undef X
    } else {
        // Populate the map with the current value found in the QSettings config
        // Get the current background URL of the account
#define X(key, defaultValue) \
    accountSettingsPropertyMap_ \
        .setAccountSettingProperty(#key, accountSettings_->value(currentAccountID_ + "/" + #key).toString());
        PROPERTY_KEYS
#undef X
        qWarning() << "Loaded existing settings for account:" << currentAccountID_;
    }
}

void
AccountSettingsManager::updateCurrentAccount(const QString& newCurrentAccountID)
{
    // Accounts didn't change, no need to update anything
    if (currentAccountID_ == newCurrentAccountID) {
        return;
    }

    qWarning() << "Account changed from" << currentAccountID_ << "to" << newCurrentAccountID;
    currentAccountID_ = newCurrentAccountID;

// Load existing settings for this account
#define X(key, defaultValue) \
    accountSettingsPropertyMap_ \
        .setAccountSettingProperty(#key, accountSettings_->value(currentAccountID_ + "/" + #key).toString());
    PROPERTY_KEYS
#undef X
}

void
AccountSettingsManager::setValue(const QString& key, const QVariant& value)
{
    accountSettings_->beginGroup(currentAccountID_);
    accountSettings_->setValue(key, value);
    accountSettings_->endGroup();
}

QVariant
AccountSettingsManager::getValue(const QString& key)
{
    return accountSettingsPropertyMap_.value(key);
}
