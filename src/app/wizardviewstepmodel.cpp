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
}

void
WizardViewStepModel::startAccountCreationFlow(AccountCreationOption accountCreationOption)
{
    set_accountCreationOption(accountCreationOption);
    if (accountCreationOption == AccountCreationOption::CreateJamiAccount
        || accountCreationOption == AccountCreationOption::CreateRendezVous)
        set_mainStep(MainSteps::NameRegistration);
    else
        set_mainStep(MainSteps::AccountCreation);
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
    }
}

void
WizardViewStepModel::reset()
{
    set_accountCreationOption(AccountCreationOption::None);
    set_mainStep(MainSteps::Initial);
}
