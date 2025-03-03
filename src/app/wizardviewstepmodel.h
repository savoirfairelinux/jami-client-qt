/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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
#include "api/account.h"  // Include for DeviceAuthState

#include <QObject>
#include <QVariant>
#include <QMap>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class AccountAdapter;
class LRCInstance;
class AppSettingsManager;

class DeviceAuthStateEnum : public QObject {
    Q_OBJECT
public:
    enum State {
        INIT = static_cast<int>(lrc::api::account::DeviceAuthState::INIT),
        TOKEN_AVAILABLE = static_cast<int>(lrc::api::account::DeviceAuthState::TOKEN_AVAILABLE),
        CONNECTING = static_cast<int>(lrc::api::account::DeviceAuthState::CONNECTING),
        AUTHENTICATING = static_cast<int>(lrc::api::account::DeviceAuthState::AUTHENTICATING),
        IN_PROGRESS = static_cast<int>(lrc::api::account::DeviceAuthState::IN_PROGRESS),
        DONE = static_cast<int>(lrc::api::account::DeviceAuthState::DONE)
    };
    Q_ENUM(State)
};

class WizardViewStepModel : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")

public:
    enum class MainSteps {
        Initial,            // Initial welcome step.
        AccountCreation,    // General account creation step.
        NameRegistration,   // Name registration step : CreateJamiAccount, CreateRendezVous
        DeviceAuthorization // Add new step for device authorization.
    };
    Q_ENUM(MainSteps)

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

    QML_PROPERTY(MainSteps, mainStep)
    QML_PROPERTY(AccountCreationOption, accountCreationOption)
    QML_PROPERTY(QVariantMap, accountCreationInfo)
    QML_PROPERTY(lrc::api::account::DeviceAuthState, deviceAuthState)
    QML_PROPERTY(QVariantMap, deviceLinkDetails)

public:
    static WizardViewStepModel* create(QQmlEngine*, QJSEngine*)
    {
        return new WizardViewStepModel(qApp->property("LRCInstance").value<LRCInstance*>(),
                                       qApp->property("AppSettingsManager")
                                           .value<AppSettingsManager*>());
    }

    explicit WizardViewStepModel(LRCInstance* lrcInstance,
                                 AppSettingsManager* appSettingsManager,
                                 QObject* parent = nullptr);

    Q_INVOKABLE void startAccountCreationFlow(AccountCreationOption accountCreationOption);
    Q_INVOKABLE void nextStep();
    Q_INVOKABLE void previousStep();

Q_SIGNALS:
    void accountIsReady(QString accountId);
    void closeWizardView();
    void createAccountRequested(AccountCreationOption);

private:
    void reset();

    LRCInstance* lrcInstance_;
    AppSettingsManager* appSettingsManager_;
};
