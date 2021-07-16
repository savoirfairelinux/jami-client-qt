/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
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

#include "accountadapter.h"

WizardViewStepModel::WizardViewStepModel(LRCInstance* lrcInstance,
                                         AccountAdapter* accountAdapter,
                                         QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
    , accountAdapter_(accountAdapter)
{
    set_mainStep(MainSteps::Initial);
    set_accountCreationOption(AccountCreationOption::None);
    set_subStep(SubSteps::NameRegistration);
}

void
WizardViewStepModel::nextStep(AccountCreationOption accountCreationOption)
{
    switch (get_mainStep()) {
    case MainSteps::Initial: {
        if (accountCreationOption != AccountCreationOption::None) {
            set_accountCreationOption(accountCreationOption);
            set_mainStep(MainSteps::AccountCreation);
        }
        break;
    }
    case MainSteps::AccountCreation: {
        switch (get_accountCreationOption()) {
        case AccountCreationOption::CreateJamiAccount:
        case AccountCreationOption::CreateRendezVous: {
            switch (get_subStep()) {
            case SubSteps::NameRegistration:
                set_subStep(SubSteps::SetPassword);
                break;
            case SubSteps::SetPassword:
                set_mainStep(MainSteps::Profile);
                set_subStep(SubSteps::NameRegistration);
                auto& accountCreationInfo = get_accountCreationInfo();
                accountAdapter_->createJamiAccount(accountCreationInfo["registeredName"].toString(),
                                                   accountCreationInfo,
                                                   true);
                break;
            }
            break;
        }
        default:
            break;
        }
        break;
    }
    default:
        break;
    }
}

void
WizardViewStepModel::previousStep()
{
    switch (get_mainStep()) {
    case MainSteps::Initial: {
        //
        break;
    }
    case MainSteps::AccountCreation: {
        switch (get_subStep()) {
        case SubSteps::NameRegistration:
            set_accountCreationOption(AccountCreationOption::None);
            set_mainStep(MainSteps::Initial);
            break;
        case SubSteps::SetPassword:
            set_subStep(SubSteps::NameRegistration);
            break;
        }
        break;
    }
    default:
        break;
    }
}