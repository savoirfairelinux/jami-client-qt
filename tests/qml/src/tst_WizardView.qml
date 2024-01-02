/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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

import QtQuick
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/wizardview"
import "../../../src/app/commoncomponents"

WizardView {
    id: uut

    width: 400
    height: 600

    function clearSignalSpy() {
        spyAccountIsReady.clear()
        spyAccountIsRemoved.clear()
        spyAccountConfigFinalized.clear()
        spyReportFailure.clear()
        spyCloseWizardView.clear()

        spyBackButtonVisible.target = undefined
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

    SignalSpy {
        id: spyAccountConfigFinalized

        target: AccountAdapter
        signalName: "accountConfigFinalized"
    }

    SignalSpy {
        id: spyReportFailure

        target: AccountAdapter
        signalName: "reportFailure"
    }

    SignalSpy {
        id: spyCloseWizardView

        target: WizardViewStepModel
        signalName: "closeWizardView"
    }

    SignalSpy {
        id: spyBackButtonVisible

        signalName: "visibleChanged"
    }

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

            // Go to createAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    createAccountPage)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    welcomePage)

            // Go to CreateRendezVous page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateRendezVous)
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    createAccountPage)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    welcomePage)

            // Go to CreateRendezVous page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.ImportFromDevice)
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    importFromDevicePage)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    welcomePage)

            // Go to ImportFromBackup page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.ImportFromBackup)
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    importFromBackupPage)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    welcomePage)

            // Go to ConnectToAccountManager page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.ConnectToAccountManager)
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    connectToAccountManagerPage)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    welcomePage)

            // Go to CreateSipAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateSipAccount)
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    createSIPAccountPage)
            WizardViewStepModel.previousStep()
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    welcomePage)
        }
    }

    TestCase {
        name: "Create Sip account ui flow"
        when: windowShown

        function test_createSipAccountUiFlow() {
            uut.clearSignalSpy()

            var controlPanelStackView = findChild(uut, "controlPanelStackView")

            var welcomePage = findChild(uut, "welcomePage")
            var createSIPAccountPage = findChild(uut, "createSIPAccountPage")

            var sipUsernameEdit = findChild(createSIPAccountPage, "sipUsernameEdit")
            var sipPasswordEdit = findChild(createSIPAccountPage, "sipPasswordEdit")
            var sipServernameEdit = findChild(createSIPAccountPage, "sipServernameEdit")
            var createAccountButton = findChild(createSIPAccountPage, "createSIPAccountButton")

            // Go to createSipAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateSipAccount)

            // Set up paras
            var userName = "testUserName"
            var serverName = "testServerName"
            var password = "testPassword"
            var proxy = "testProxy"

            sipUsernameEdit.dynamicText = userName
            sipPasswordEdit.dynamicText = password
            sipServernameEdit.dynamicText = serverName

            createAccountButton.clicked()

            // Wait until the account creation is finished
            spyAccountIsReady.wait()
            compare(spyAccountIsReady.count, 1)

            // Check if paras match with setup
            compare(CurrentAccount.username, userName)
            compare(CurrentAccount.hostname, serverName)
            compare(CurrentAccount.password, password)

            WizardViewStepModel.nextStep()

            spyCloseWizardView.wait()
            compare(spyCloseWizardView.count, 1)

            AccountAdapter.deleteCurrentAccount()

            // Wait until the account removal is finished
            spyAccountIsRemoved.wait()
            compare(spyAccountIsRemoved.count, 1)
        }
    }
}
