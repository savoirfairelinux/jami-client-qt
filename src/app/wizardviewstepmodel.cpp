/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang   <mingrui.zhang@savoirfairelinux.com>
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

#include "wizardviewstepmodel.h"

#include "appsettingsmanager.h"
#include "lrcinstance.h"
#include "global.h"

#include "api/accountmodel.h"

WizardViewStepModel::WizardViewStepModel(LRCInstance* lrcInstance,
                                         AppSettingsManager* appSettingsManager,
                                         QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
    , appSettingsManager_(appSettingsManager)
{
    reset();
    connect(&lrcInstance_->accountModel(),
            &AccountModel::accountAdded,
            this,
            [this](const QString& accountId) {
                auto accountCreationOption = get_accountCreationOption();
                if (accountCreationOption == AccountCreationOption::ConnectToAccountManager
                    || accountCreationOption == AccountCreationOption::CreateSipAccount) {
                    Q_EMIT closeWizardView();
                    reset();
                } else if (accountCreationOption != AccountCreationOption::None) {
                    Q_EMIT closeWizardView();
                    reset();
                }

                Q_EMIT accountIsReady(accountId);
            });

    // DEBUG: log changes to the mainStep
    connect(this, &WizardViewStepModel::mainStepChanged, this, [this]() {
        C_INFO << "mainStep changed to" << get_mainStep();
    });

    // Connect to account model signals to track import progress
    connect(&lrcInstance_->accountModel(),
            &AccountModel::deviceAuthStateChanged,
            this,
            [this](const QString& accountID, int state, const MapStringString& details) {
                C_INFO << "Device auth state changed: " << accountID << " " << state << " "
                       << details;
                // Update device auth state based on status
                switch (state) {
                case 0: // TokenAvailable
                    set_deviceAuthState(WizardViewStepModel::DeviceAuthState::TokenAvailable);
                    set_deviceLinkDetails({{"token", details["token"]}});
                    break;
                case 1: // Authenticating
                    set_deviceAuthState(WizardViewStepModel::DeviceAuthState::Authenticating);
                    break;
                case 2: // InProgress
                    set_deviceAuthState(WizardViewStepModel::DeviceAuthState::InProgress);
                    break;
                case 3: // Done
                    set_deviceAuthState(WizardViewStepModel::DeviceAuthState::Done);
                    set_deviceLinkDetails({{"error", details["error"]}});
                    break;
                case 4: // Error
                    set_deviceAuthState(WizardViewStepModel::DeviceAuthState::Error);
                    set_deviceLinkDetails({{"error", details["error"]}});
                    break;
                }
            });
}

void
WizardViewStepModel::startAccountCreationFlow(AccountCreationOption accountCreationOption)
{
    using namespace lrc::api::account;
    set_accountCreationOption(accountCreationOption);
    if (accountCreationOption == AccountCreationOption::ImportFromDevice) {
        set_mainStep(MainSteps::DeviceAuthorization);
        set_deviceAuthState(DeviceAuthState::Init);
        // Start the import process via AccountAdapter
        Q_EMIT createAccountRequested(accountCreationOption);
    } else if (accountCreationOption == AccountCreationOption::CreateJamiAccount
               || accountCreationOption == AccountCreationOption::CreateRendezVous) {
        set_mainStep(MainSteps::NameRegistration);
    } else {
        set_mainStep(MainSteps::AccountCreation);
    }
}

void
WizardViewStepModel::nextStep()
{
    if (mainStep_ != MainSteps::Initial) {
        Q_EMIT createAccountRequested(accountCreationOption_);
    }
}

void
WizardViewStepModel::previousStep()
{
    switch (get_mainStep()) {
    case MainSteps::Initial: {
        Q_EMIT closeWizardView();
        break;
    }
    case MainSteps::AccountCreation:
    case MainSteps::NameRegistration: {
        reset();
        break;
    }
    case MainSteps::DeviceAuthorization: {
        reset();
        break;
    }
    }
}

void
WizardViewStepModel::reset()
{
    set_accountCreationOption(AccountCreationOption::None);
    set_mainStep(MainSteps::Initial);
    set_deviceAuthState(DeviceAuthState::Init);
    set_deviceLinkDetails({});
}
