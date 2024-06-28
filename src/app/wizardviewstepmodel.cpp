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
        qWarning("[LinkDevice] is not MainStep::Initial");
        Q_EMIT createAccountRequested(accountCreationOption_);
    }

    advanceLinkDevice();
}

void
WizardViewStepModel::advanceLinkDevice() // may need to add the DeviceAuthState as an input here
{
    // linkdev
    if (get_accountCreationOption() == AccountCreationOption::ImportFromDevice) {
        qWarning("[LinkDevice] is AccountCreationOption::ImportFromDevice");
        if (get_linkDeviceStep() == LinkDeviceStep::OutOfBand) {
            // || get_linkDeviceStep() == LinkDeviceStep::Scannable) {
            set_linkDeviceStep(LinkDeviceStep::Waiting);
            Q_EMIT linkStateChanged(linkDeviceStep_);
            // - don't need this state because it can only be handled by
            // } else if (get_linkDeviceStep() == LinkDeviceStep::Waiting) {
            //     // set_linkDeviceStep(LinkDeviceStep::Scannable);
            //     Q_EMIT linkStateChanged(linkDeviceStep_);
            // - don't need this because it is better to use a signal
            // } else if (get_linkDeviceStep() == LinkDeviceStep::Scannable) {
            //     set_linkDeviceStep(LinkDeviceStep::Auth);
            //     Q_EMIT linkStateChanged(linkDeviceStep_);
        } else {
            // ::Auth
            Q_EMIT linkStateChanged(linkDeviceStep_);
            // TODO finish and do normal stuff
        }
    }
}

void
WizardViewStepModel::jumpToConnectingLinkDevice()
{
    set_linkDeviceStep(LinkDeviceStep::Waiting);
    Q_EMIT linkStateChanged(linkDeviceStep_);
}
void
WizardViewStepModel::jumpToAuthLinkDevice()
{
    set_linkDeviceStep(LinkDeviceStep::Auth);
    Q_EMIT linkStateChanged(linkDeviceStep_);
}
void
WizardViewStepModel::jumpToScannableState()
{
    set_linkDeviceStep(LinkDeviceStep::Scannable);
    Q_EMIT linkStateChanged(linkDeviceStep_);
}

void
WizardViewStepModel::goBackLinkDevice()
{
    // TODO simplify logic now that isolated
    // linkdev
    switch (get_linkDeviceStep()) {
    case LinkDeviceStep::OutOfBand:
        // TODO default passthrough to mainstep
        Q_EMIT linkStateChanged(linkDeviceStep_);
        break;
    case LinkDeviceStep::Waiting:
        set_linkDeviceStep(LinkDeviceStep::OutOfBand);
        // TODO abort bootstrapping tmp account
        Q_EMIT linkStateChanged(linkDeviceStep_);
        return;
    case LinkDeviceStep::Scannable:
        // TODO abort auth channnel
        // go back to out of band and ready to restart whole process
        set_linkDeviceStep(LinkDeviceStep::OutOfBand);
        Q_EMIT linkStateChanged(linkDeviceStep_);
        break; // for now trigger mainstep passthrough
    case LinkDeviceStep::Auth:
        set_linkDeviceStep(LinkDeviceStep::OutOfBand);
        set_mainStep(MainSteps::Initial);
        break; // potential unauthorized action from not owner of account & should be used to go
               // back to the mainstep
    default:
        break;
    }
}

void
WizardViewStepModel::previousStep()
{
    if (get_linkDeviceStep() != LinkDeviceStep::OutOfBand) {
        goBackLinkDevice();
        return;
    }

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
        // case MainSteps::SomethingWentWrong: {
        //     reset();
        //     break;
        // }
    }
}

void
WizardViewStepModel::reset()
{
    set_accountCreationOption(AccountCreationOption::None);
    set_mainStep(MainSteps::Initial);
}
