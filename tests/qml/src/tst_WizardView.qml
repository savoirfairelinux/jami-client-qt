/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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

import "../../../src/app/"
import "../../../src/app/wizardview"
import "../../../src/app/commoncomponents"

WizardView {
    id: uut

    property ViewManager viewManager: ViewManager {}
    property ViewCoordinator viewCoordinator: ViewCoordinator {
        viewManager: uut.viewManager
    }

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
        name: "Create Jami account ui flow (no registered name)"
        when: windowShown

        function test_createEmptyJamiAccountUiFlow() {
            uut.clearSignalSpy()

            var controlPanelStackView = findChild(uut, "controlPanelStackView")

            var welcomePage = findChild(uut, "welcomePage")
            var createAccountPage = findChild(uut, "createAccountPage")

            var usernameEdit = findChild(createAccountPage, "usernameEdit")
            var popup = findChild(createAccountPage, "popup")
            var joinButton = findChild(popup, "joinButton")
            var createAccountStack = findChild(createAccountPage, "createAccountStack")
            var chooseUsernameButton = findChild(createAccountPage, "chooseUsernameButton")

            // WelcomePage initially
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    welcomePage)

            // Go to createAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
            compare(createAccountStack.currentIndex, 0)

            compare(usernameEdit.visible, true)

            // This will show the popup because no username
            compare(popup.visible, false)
            chooseUsernameButton.clicked()
            compare(popup.visible, true)
            compare(joinButton.visible, true)

            // Create jami account
            joinButton.clicked()

            // Wait until the account creation is finished
            spyAccountIsReady.wait()
            compare(spyAccountIsReady.count, 1)

            spyAccountConfigFinalized.wait()
            compare(spyAccountConfigFinalized.count, 1)

            AccountAdapter.deleteCurrentAccount()

            // Wait until the account removal is finished
            spyAccountIsRemoved.wait()
            compare(spyAccountIsRemoved.count, 1)
        }
    }

    TestCase {
        name: "Create SIP account ui flow"
        when: windowShown

        function test_createEmptyJamiAccountUiFlow() {
            uut.clearSignalSpy()

            var controlPanelStackView = findChild(uut, "controlPanelStackView")

            var welcomePage = findChild(uut, "welcomePage")
            var createSIPAccountPage = findChild(uut, "createSIPAccountPage")

            var sipServernameEdit = findChild(createSIPAccountPage, "sipServernameEdit")
            var createAccountStack = findChild(createSIPAccountPage, "createAccountStack")
            var createSIPAccountButton = findChild(createSIPAccountPage, "createSIPAccountButton")

            // WelcomePage initially
            compare(controlPanelStackView.children[controlPanelStackView.currentIndex],
                    welcomePage)

            // Go to createAccount page
            WizardViewStepModel.startAccountCreationFlow(
                        WizardViewStepModel.AccountCreationOption.CreateSipAccount)
            compare(createAccountStack.currentIndex, 0)

            compare(sipServernameEdit.visible, true)

            // Create SIP Account
            createSIPAccountButton.clicked()

            // Wait until the account creation is finished
            spyAccountIsReady.wait()
            compare(spyAccountIsReady.count, 1)

            spyAccountConfigFinalized.wait()
            compare(spyAccountConfigFinalized.count, 1)

            AccountAdapter.deleteCurrentAccount()

            // Wait until the account removal is finished
            spyAccountIsRemoved.wait()
            compare(spyAccountIsRemoved.count, 1)
        }
    }
}
