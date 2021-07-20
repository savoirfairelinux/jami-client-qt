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

#pragma once

#include "qtutils.h"

#include <QStateMachine>
#include <QSignalTransition>
#include <QScopedPointer>
#include <QFinalState>
#include <QEvent>

class AccountAdapter;
class LRCInstance;
class GuardedTransition;

class WizardStateMachine : public QStateMachine
{
    Q_OBJECT
    // Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")

public:
    enum class WizardViewPages {
        Initial,          // Initial welcome page.
        AccountCreation,  // Account creation pages.
        NameRegistration, // Name registration page: CreateJamiAccount, CreateRendezVous
        SetPassword,      // Password set up page: CreateJamiAccount, CreateRendezVous
        Profile,          // Profile set up page.
        BackupKeys        // Backup set up page.
    };
    Q_ENUM(WizardViewPages)

    enum class AccountCreationOption {
        None,
        CreateJamiAccount,       // Jami account creation.
        CreateRendezVous,        // Jami rendezvous account creation.
        ImportFromDevice,        // Jami account creation from device.
        ImportFromBackup,        // Jami account creation from backup.
        ConnectToAccountManager, // Account manager creation.
        CreateSipAccount         // SIP account creation.
    };
    Q_ENUM(AccountCreationOption)

    QML_PROPERTY(WizardViewPages, currentPage)
    QML_PROPERTY(AccountCreationOption, accountCreationOption)

    QML_PROPERTY(QVariantMap, accountCreationInfo)

Q_SIGNALS:
    void nextPageRequest(int accountCreationOption, bool isForward);

public:
    WizardStateMachine(LRCInstance* lrcInstance,
                       AccountAdapter* accountAdapter,
                       QObject* parent = nullptr);

    Q_INVOKABLE void nextStep(
        AccountCreationOption accountCreationOption = AccountCreationOption::None);
    Q_INVOKABLE void previousStep();

private:
    LRCInstance* lrcInstance_;
    AccountAdapter* accountAdapter_;

    QScopedPointer<QState> initialState_;

    // Account creation transitions
    QScopedPointer<GuardedTransition> createJamiAccountTransition_;
    QScopedPointer<GuardedTransition> createRendezVousTransition_;
    QScopedPointer<GuardedTransition> importFromDeviceTransition_;
    QScopedPointer<GuardedTransition> importFromBackupTransition_;
    QScopedPointer<GuardedTransition> connectToAccountManagerTransition_;
    QScopedPointer<GuardedTransition> createSipAccountTransition_;

    // Account creation states
    QScopedPointer<QState> createJamiAccountState_;
    QScopedPointer<QState> createRendezVousState_;
    QScopedPointer<QState> importFromDeviceState_;
    QScopedPointer<QState> importFromBackupState_;
    QScopedPointer<QState> connectToAccountManagerState_;
    QScopedPointer<QState> createSipAccountState_;

    QScopedPointer<QState> nameRegistrationState_;
    QScopedPointer<QState> setPasswordState_;
    QScopedPointer<QState> profileState_;
    QScopedPointer<QState> backupKeysState_;

    //
    QScopedPointer<GuardedTransition> backToInitialTransition_;
};

class GuardedTransition : public QSignalTransition
{
public:
    GuardedTransition(WizardStateMachine* stateMachine,
                      WizardStateMachine::WizardViewPages guardedPage,
                      bool isForward = true,
                      WizardStateMachine::AccountCreationOption guardedAccountCreationOption
                      = WizardStateMachine::AccountCreationOption::None);

protected:
    virtual bool eventTest(QEvent* e) override;

private:
    WizardStateMachine* currentStateMachine_;
    WizardStateMachine::WizardViewPages guardedPage_;
    WizardStateMachine::AccountCreationOption guardedAccountCreationOption_;

    bool isForward_;
};