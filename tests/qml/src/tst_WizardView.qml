/*
 * Copyright (C) 2021 by Savoir-faire Linux
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick 2.14
import QtTest 1.2

import net.jami.Adapters 1.0
import net.jami.Models 1.0
import net.jami.Constants 1.0
import net.jami.Enums 1.0

import "qrc:/src/wizardview"

WizardView {
    id: uut

    TestCase {
        name: "WelcomePage to different account creation page and return back"
        when: windowShown

        function test_welcomePageStepInStepOut() {
            var controlPanelStackView = findChild(uut, "controlPanelStackView")

            var welcomePage = findChild(uut, "welcomePage")
            var createAccountPage = findChild(uut, "createAccountPage")
            var importFromDevicePage = findChild(uut, "importFromDevicePage")
            var importFromBackupPage = findChild(uut, "importFromBackupPage")
            var connectToAccountManagerPage = findChild(uut, "connectToAccountManagerPage")
            var createSIPAccountPage = findChild(uut, "createSIPAccountPage")

            // WelcomePage initially
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to createAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
            compare(controlPanelStackView.currentIndex, createAccountPage.stackLayoutIndex)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to CreateRendezVous page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateRendezVous)
            compare(controlPanelStackView.currentIndex, createAccountPage.stackLayoutIndex)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to CreateRendezVous page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.ImportFromDevice)
            compare(controlPanelStackView.currentIndex, importFromDevicePage.stackLayoutIndex)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to ImportFromBackup page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.ImportFromBackup)
            compare(controlPanelStackView.currentIndex, importFromBackupPage.stackLayoutIndex)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to ConnectToAccountManager page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.ConnectToAccountManager)
            compare(controlPanelStackView.currentIndex, connectToAccountManagerPage.stackLayoutIndex)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to CreateSipAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateSipAccount)
            compare(controlPanelStackView.currentIndex, createSIPAccountPage.stackLayoutIndex)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)
        }

        function test_createAccountPageStepInStepOut() {
            var controlPanelStackView = findChild(uut, "controlPanelStackView")
            var welcomePage = findChild(uut, "welcomePage")
            var createAccountPage = findChild(uut, "createAccountPage")

            var createAccountStack = findChild(createAccountPage, "createAccountStack")
            var passwordSetupPage = findChild(createAccountPage, "passwordSetupPage")
            var nameRegistrationPage = findChild(createAccountPage, "nameRegistrationPage")

            // WelcomePage initially
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to createAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
            compare(createAccountPage.isRendezVous, false)
            compare(controlPanelStackView.currentIndex, createAccountPage.stackLayoutIndex)
            compare(createAccountStack.currentIndex, nameRegistrationPage.stackIndex)

            // Go to passwordSetup page
            WizardViewStepModel.nextStep()
            compare(createAccountStack.currentIndex, passwordSetupPage.stackIndex)

            // Back
            WizardViewStepModel.previousStep()
            compare(createAccountStack.currentIndex, nameRegistrationPage.stackIndex)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to CreateRendezVous page (createAccount)
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateRendezVous)
            compare(createAccountPage.isRendezVous, true)
            compare(controlPanelStackView.currentIndex, createAccountPage.stackLayoutIndex)
            compare(createAccountStack.currentIndex, nameRegistrationPage.stackIndex)

            // Go to passwordSetup page
            WizardViewStepModel.nextStep()
            compare(createAccountStack.currentIndex, passwordSetupPage.stackIndex)

            // Back
            WizardViewStepModel.previousStep()
            compare(createAccountStack.currentIndex, nameRegistrationPage.stackIndex)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)
        }
    }

    SignalSpy {
        id: spyAccountIsReady

        target: WizardViewStepModel
        signalName: "accountIsReady"
    }

    SignalSpy {
        id: spyAccountIsRemoved

        target: AccountAdapter
        signalName: "accountRemoved"
    }

    SignalSpy {
        id: spyAccountStatusChanged

        target: AccountAdapter
        signalName: "accountStatusChanged"
    }

    TestCase {
        name: "Create Jami account ui flow (no registered name)"
        when: windowShown

        function test_createJamiAccountUiFlow() {
            spyAccountIsReady.clear()
            spyAccountIsRemoved.clear()
            spyAccountStatusChanged.clear()

            var controlPanelStackView = findChild(uut, "controlPanelStackView")

            var welcomePage = findChild(uut, "welcomePage")
            var createAccountPage = findChild(uut, "createAccountPage")
            var profilePage = findChild(uut, "profilePage")
            var backupKeysPage = findChild(uut, "backupKeysPage")

            var usernameEdit = findChild(createAccountPage, "usernameEdit")
            var createAccountStack = findChild(createAccountPage, "createAccountStack")
            var passwordSwitch = findChild(createAccountPage, "passwordSwitch")
            var passwordEdit = findChild(createAccountPage, "passwordEdit")
            var passwordConfirmEdit = findChild(createAccountPage, "passwordConfirmEdit")
            var createAccountButton = findChild(createAccountPage, "createAccountButton")

            var aliasEdit = findChild(profilePage, "aliasEdit")
            var saveProfileBtn = findChild(profilePage, "saveProfileBtn")

            var password  = "test110"
            var aliasText = "test101"

            // WelcomePage initially
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to createAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
            compare(createAccountStack.currentIndex, 0)
            compare(usernameEdit.focus, true)

            // Go to set up password page
            WizardViewStepModel.nextStep()
            compare(createAccountStack.currentIndex, 1)
            passwordSwitch.checked = true
            compare(passwordEdit.focus, true)
            passwordEdit.text = password
            passwordConfirmEdit.text = password
            createAccountButton.clicked()

            // Wait until the account creation is finished
            spyAccountIsReady.wait()
            compare(spyAccountIsReady.count, 1)

            // Now we are in profile page
            compare(controlPanelStackView.currentIndex, profilePage.stackLayoutIndex)
            compare(aliasEdit.focus, true)

            aliasEdit.text = aliasText
            saveProfileBtn.clicked()

            var showBackup = (WizardViewStepModel.accountCreationOption ===
                              WizardViewStepModel.AccountCreationOption.CreateJamiAccount
                              || WizardViewStepModel.accountCreationOption ===
                              WizardViewStepModel.AccountCreationOption.CreateRendezVous)
                              && !AppSettingsManager.getValue(Settings.NeverShowMeAgain)
            if (showBackup) {
                compare(controlPanelStackView.currentIndex, backupKeysPage.stackLayoutIndex)
                WizardViewStepModel.nextStep()
            }

            spyAccountStatusChanged.wait()
            verify(spyAccountStatusChanged.count >= 1)
            spyAccountStatusChanged.clear()

            compare(AccountAdapter.savePassword(LRCInstance.currentAccountId, password, "test"), true)
            compare(SettingsAdapter.getCurrentAccount_Profile_Info_Alias(), aliasText)

            // Wait until the account status change is finished
            spyAccountStatusChanged.wait()
            verify(spyAccountStatusChanged.count >= 1)

            AccountAdapter.deleteCurrentAccount()

            // Wait until the account removal is finished
            spyAccountIsRemoved.wait()
            compare(spyAccountIsRemoved.count, 1)
        }

        function test_createRendezVousAccountUiFlow() {
            spyAccountIsReady.clear()
            spyAccountIsRemoved.clear()
            spyAccountStatusChanged.clear()

            var controlPanelStackView = findChild(uut, "controlPanelStackView")

            var welcomePage = findChild(uut, "welcomePage")
            var createAccountPage = findChild(uut, "createAccountPage")
            var profilePage = findChild(uut, "profilePage")
            var backupKeysPage = findChild(uut, "backupKeysPage")

            var usernameEdit = findChild(createAccountPage, "usernameEdit")
            var createAccountStack = findChild(createAccountPage, "createAccountStack")
            var passwordSwitch = findChild(createAccountPage, "passwordSwitch")
            var passwordEdit = findChild(createAccountPage, "passwordEdit")
            var passwordConfirmEdit = findChild(createAccountPage, "passwordConfirmEdit")
            var createAccountButton = findChild(createAccountPage, "createAccountButton")

            var aliasEdit = findChild(profilePage, "aliasEdit")
            var saveProfileBtn = findChild(profilePage, "saveProfileBtn")

            var password  = "test110"
            var aliasText = "test101"

            // WelcomePage initially
            compare(controlPanelStackView.currentIndex, welcomePage.stackLayoutIndex)

            // Go to createRendezVous page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateRendezVous)
            compare(createAccountStack.currentIndex, 0)
            compare(usernameEdit.focus, true)

            // Go to set up password page
            WizardViewStepModel.nextStep()
            compare(createAccountStack.currentIndex, 1)
            passwordSwitch.checked = true
            compare(passwordEdit.focus, true)
            passwordEdit.text = password
            passwordConfirmEdit.text = password
            createAccountButton.clicked()

            // Wait until the account creation is finished
            spyAccountIsReady.wait()
            compare(spyAccountIsReady.count, 1)

            // Now we are in profile page
            compare(controlPanelStackView.currentIndex, profilePage.stackLayoutIndex)
            compare(aliasEdit.focus, true)

            aliasEdit.text = aliasText
            saveProfileBtn.clicked()

            var showBackup = (WizardViewStepModel.accountCreationOption ===
                              WizardViewStepModel.AccountCreationOption.CreateJamiAccount
                              || WizardViewStepModel.accountCreationOption ===
                              WizardViewStepModel.AccountCreationOption.CreateRendezVous)
                              && !AppSettingsManager.getValue(Settings.NeverShowMeAgain)
            if (showBackup) {
                compare(controlPanelStackView.currentIndex, backupKeysPage.stackLayoutIndex)
                WizardViewStepModel.nextStep()
            }

            spyAccountStatusChanged.wait()
            verify(spyAccountStatusChanged.count >= 1)
            spyAccountStatusChanged.clear()

            compare(AccountAdapter.savePassword(LRCInstance.currentAccountId, password, "test"), true)
            compare(SettingsAdapter.getCurrentAccount_Profile_Info_Alias(), aliasText)
            compare(SettingsAdapter.getAccountConfig_RendezVous(), true)

            // Wait until the account status change is finished
            spyAccountStatusChanged.wait()
            verify(spyAccountStatusChanged.count >= 1)

            AccountAdapter.deleteCurrentAccount()

            // Wait until the account removal is finished
            spyAccountIsRemoved.wait()
            compare(spyAccountIsRemoved.count, 1)
        }
    }
}
