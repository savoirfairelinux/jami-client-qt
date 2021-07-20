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

#include "wizardstatemachine.h"

#include "accountadapter.h"
#include "lrcinstance.h"

WizardStateMachine::WizardStateMachine(LRCInstance* lrcInstance,
                                       AccountAdapter* accountAdapter,
                                       QObject* parent)
    : QStateMachine(parent)
    , accountAdapter_(accountAdapter)
    , lrcInstance_(lrcInstance)
{
    initialState_.reset(new QState());

    createJamiAccountState_.reset(new QState());
    createRendezVousState_.reset(new QState());
    importFromDeviceState_.reset(new QState());
    importFromBackupState_.reset(new QState());
    connectToAccountManagerState_.reset(new QState());
    createSipAccountState_.reset(new QState());

    createJamiAccountTransition_.reset(
        new GuardedTransition(this,
                              WizardViewPages::Initial,
                              true,
                              AccountCreationOption::CreateJamiAccount));
    createRendezVousTransition_.reset(
        new GuardedTransition(this,
                              WizardViewPages::Initial,
                              true,
                              AccountCreationOption::CreateRendezVous));
    importFromDeviceTransition_.reset(
        new GuardedTransition(this,
                              WizardViewPages::Initial,
                              true,
                              AccountCreationOption::ImportFromDevice));
    importFromBackupTransition_.reset(
        new GuardedTransition(this,
                              WizardViewPages::Initial,
                              true,
                              AccountCreationOption::ImportFromBackup));
    connectToAccountManagerTransition_.reset(
        new GuardedTransition(this,
                              WizardViewPages::Initial,
                              true,
                              AccountCreationOption::ConnectToAccountManager));
    createSipAccountTransition_.reset(
        new GuardedTransition(this,
                              WizardViewPages::Initial,
                              true,
                              AccountCreationOption::CreateSipAccount));

    backToInitialTransition_.reset(
        new GuardedTransition(this, WizardViewPages::AccountCreation, false));

    createJamiAccountTransition_->setTargetState(createJamiAccountState_.get());
    createRendezVousTransition_->setTargetState(createRendezVousState_.get());
    importFromDeviceTransition_->setTargetState(importFromDeviceState_.get());
    importFromBackupTransition_->setTargetState(importFromBackupState_.get());
    connectToAccountManagerTransition_->setTargetState(connectToAccountManagerState_.get());
    createSipAccountTransition_->setTargetState(createSipAccountState_.get());

    backToInitialTransition_->setTargetState(initialState_.get());

    initialState_->addTransition(createJamiAccountTransition_.get());
    initialState_->addTransition(createRendezVousTransition_.get());
    initialState_->addTransition(importFromDeviceTransition_.get());
    initialState_->addTransition(importFromBackupTransition_.get());
    initialState_->addTransition(connectToAccountManagerTransition_.get());
    initialState_->addTransition(createSipAccountTransition_.get());

    createJamiAccountState_->addTransition(backToInitialTransition_.get());
    //createRendezVousState_->addTransition(backToInitialTransition_.get());
    //importFromDeviceState_->addTransition(backToInitialTransition_.get());
    //importFromBackupState_->addTransition(backToInitialTransition_.get());
    //connectToAccountManagerState_->addTransition(backToInitialTransition_.get());
    //createSipAccountState_->addTransition(backToInitialTransition_.get());

    connect(initialState_.get(), &QState::entered, [this]() {
        set_accountCreationOption(AccountCreationOption::None);
        set_currentPage(WizardViewPages::Initial);
    });

    connect(createJamiAccountState_.get(), &QState::entered, [this]() {
        set_accountCreationOption(AccountCreationOption::CreateJamiAccount);
        set_currentPage(WizardViewPages::AccountCreation);
    });
    connect(createRendezVousState_.get(), &QState::entered, [this]() {
        set_accountCreationOption(AccountCreationOption::CreateRendezVous);
        set_currentPage(WizardViewPages::AccountCreation);
    });
    connect(importFromDeviceState_.get(), &QState::entered, [this]() {
        set_accountCreationOption(AccountCreationOption::ImportFromDevice);
        set_currentPage(WizardViewPages::AccountCreation);
    });
    connect(importFromBackupState_.get(), &QState::entered, [this]() {
        set_accountCreationOption(AccountCreationOption::ImportFromBackup);
        set_currentPage(WizardViewPages::AccountCreation);
    });
    connect(connectToAccountManagerState_.get(), &QState::entered, [this]() {
        set_accountCreationOption(AccountCreationOption::ConnectToAccountManager);
        set_currentPage(WizardViewPages::AccountCreation);
    });
    connect(createSipAccountState_.get(), &QState::entered, [this]() {
        set_accountCreationOption(AccountCreationOption::CreateSipAccount);
        set_currentPage(WizardViewPages::AccountCreation);
    });

    addState(initialState_.get());
    addState(createJamiAccountState_.get());
    addState(createRendezVousState_.get());
    addState(importFromDeviceState_.get());
    addState(importFromBackupState_.get());
    addState(connectToAccountManagerState_.get());
    addState(createSipAccountState_.get());

    setInitialState(initialState_.get());

    start();
}

void
WizardStateMachine::nextStep(AccountCreationOption accountCreationOption)
{
    Q_EMIT nextPageRequest(static_cast<int>(accountCreationOption), true);
}

void
WizardStateMachine::previousStep()
{
    Q_EMIT nextPageRequest(static_cast<int>(AccountCreationOption::None), false);
}

GuardedTransition::GuardedTransition(
    WizardStateMachine* stateMachine,
    WizardStateMachine::WizardViewPages guardedPage,
    bool isForward,
    WizardStateMachine::AccountCreationOption guardedAccountCreationOption)
    : QSignalTransition(stateMachine, &WizardStateMachine::nextPageRequest)
    , currentStateMachine_(stateMachine)
    , isForward_(isForward)
    , guardedAccountCreationOption_(guardedAccountCreationOption)
    , guardedPage_(guardedPage)

{}

bool
GuardedTransition::eventTest(QEvent* e)
{
    if (!QSignalTransition::eventTest(e))
        return false;
    QStateMachine::SignalEvent* se = static_cast<QStateMachine::SignalEvent*>(e);
    auto type = se->arguments().at(0).toInt();
    auto isForward = se->arguments().at(1).toBool();
    qDebug() << type;
    qDebug() << isForward;
    return isForward == isForward_ && currentStateMachine_->get_currentPage() == guardedPage_
           && type == static_cast<int>(guardedAccountCreationOption_);
}
