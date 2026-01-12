/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
    connect(&lrcInstance_->accountModel(), &AccountModel::accountAdded, this, [this](const QString& accountId) {
        auto accountCreationOption = get_accountCreationOption();
        if (accountCreationOption == AccountCreationOption::ConnectToAccountManager
            || accountCreationOption == AccountCreationOption::CreateSipAccount) {
            reset();
        } else if ((accountCreationOption != AccountCreationOption::None)
                   && mainStep_ != MainSteps::ProfileCustomization) {
            Q_EMIT closeWizardView();
            reset();
        }

        Q_EMIT accountIsReady(accountId);
    });

    // Connect to account model signals to track import progress
    connect(&lrcInstance_->accountModel(),
            &AccountModel::deviceAuthStateChanged,
            this,
            [this](const QString& accountID, int state, const MapStringString& details) {
                set_deviceLinkDetails(Utils::mapStringStringToVariantMap(details));
                set_deviceAuthState(static_cast<lrc::api::account::DeviceAuthState>(state));
            });
}

void
WizardViewStepModel::startAccountCreationFlow(AccountCreationOption accountCreationOption)
{
    using namespace lrc::api::account;
    set_accountCreationOption(accountCreationOption);
    if (accountCreationOption == AccountCreationOption::ImportFromDevice) {
        set_mainStep(MainSteps::DeviceAuthorization);
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
    switch (mainStep_) {
    case MainSteps::Initial:
        break;
    case MainSteps::ProfileCustomization:
        Q_EMIT closeWizardView();
        break;
    case MainSteps::NameRegistration:
        Q_EMIT createAccountRequested(accountCreationOption_);
        set_mainStep(MainSteps::ProfileCustomization);
        break;
    default:
        Q_EMIT createAccountRequested(accountCreationOption_);
        Q_EMIT closeWizardView();
        break;
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
    case MainSteps::ProfileCustomization: {
        set_mainStep(MainSteps::NameRegistration);
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
    set_deviceAuthState(lrc::api::account::DeviceAuthState::INIT);
    set_deviceLinkDetails({});
}
