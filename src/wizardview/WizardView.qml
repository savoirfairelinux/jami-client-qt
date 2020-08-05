/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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
import QtQuick.Controls 1.4 as CT
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.14
import net.jami.Models 1.0

import "../commoncomponents"
import "../constant"
import "components"

Rectangle {
    id: wizardViewWindow

    enum Mode {
        CREATE,
        IMPORT,
        MIGRATE,
        CREATESIP,
        CONNECTMANAGER
    }

    enum NameRegistrationState {
        BLANK,
        INVALID,
        TAKEN,
        FREE,
        SEARCHING
    }

    property int textFontSize: 9
    property int wizardMode: WizardView.CREATE
    property int addedAccountIndex: -1
    property bool registrationStateOk: false
    property string fileToImport: ""
    property string registeredName: ""

    property var inputParaObject: ({})

    /*
     * signal to redirect the page to main view
     */
    signal needToShowMainViewWindow(int accountIndex)
    signal wizardViewIsClosed

    visible: true
    anchors.fill: parent


    Component.onCompleted: {
        changePageQML(controlPanelStackView.welcomePageStackId)
    }

    Connections{
        target: ClientWrapper.accountAdaptor

        function onAccountAdded(showBackUp, index) {
            addedAccountIndex = index
            if (showBackUp) {
                changePageQML(controlPanelStackView.backupKeysPageId)
            } else {
                changePageQML(controlPanelStackView.welcomePageStackId)
                needToShowMainViewWindow(addedAccountIndex)
                ClientWrapper.lrcInstance.accountListChanged()
            }
        }

        // reportFailure
        function onReportFailure() {
            if (controlPanelStackView.currentIndex == controlPanelStackView.importFromDevicePageId) {
                importFromDevicePage.errorText = qsTr("Error when creating your account. Check your credentials")
            }
        }
    }

    Connections {
        id: registeredNameFoundConnection
        target: ClientWrapper.nameDirectory
        enabled: false

        function onRegisteredNameFound(status, address, name) {
            slotRegisteredNameFound(status, address, name)
        }
    }

    function createAccountQML() {
        switch (wizardMode) {
        case WizardView.CONNECTMANAGER:
            ClientWrapper.accountAdaptor.createJAMSAccount(inputParaObject)
            break
        case WizardView.CREATE:
        case WizardView.IMPORT:
            ClientWrapper.accountAdaptor.createJamiAccount(registeredName,
                                                           inputParaObject,
                                                           createAccountPage.boothImgBase64,
                                                           (wizardMode === WizardView.CREATE))
            break
        default:
            ClientWrapper.accountAdaptor.createSIPAccount(inputParaObject,createSIPAccountPage.boothImgBase64)
        }

        changePageQML(controlPanelStackView.spinnerPageId)
        update()
    }

    function slotRegisteredNameFound(status, address, name) {
        if (name.length < 3) {
            registrationStateOk = false
            createAccountPage.nameRegistrationUIState = WizardView.INVALID
        } else if (registeredName === name) {
            switch (status) {
            case NameDirectory.LookupStatus.NOT_FOUND:
            case NameDirectory.LookupStatus.ERROR:
                registrationStateOk = true
                createAccountPage.nameRegistrationUIState = WizardView.FREE
                break
            case NameDirectory.LookupStatus.INVALID_NAME:
            case NameDirectory.LookupStatus.INVALID:
                registrationStateOk = false
                createAccountPage.nameRegistrationUIState = WizardView.INVALID
                break
            case NameDirectory.LookupStatus.SUCCESS:
                registrationStateOk = false
                createAccountPage.nameRegistrationUIState = WizardView.TAKEN
                break
            }
        }
        validateWizardProgressionQML()
    }

    function processWizardInformationsQML() {
        inputParaObject = {}
        switch (wizardMode) {
        case WizardView.CREATE:
            spinnerPage.progressLabelEditText = qsTr(
                        "Generating your Jami account...")
            inputParaObject["alias"] = createAccountPage.text_fullNameEditAlias

            inputParaObject["password"] = createAccountPage.text_confirmPasswordEditAlias

            createAccountPage.clearAllTextFields()
            break
        case WizardView.IMPORT:
            registeredName = ""
            spinnerPage.progressLabelEditText = qsTr(
                        "Importing account archive...")
            // should only work in import from backup page or import from device page
            if (controlPanelStackView.currentIndex
                    == controlPanelStackView.importFromBackupPageId) {
                inputParaObject["password"]
                        = importFromBackupPage.text_passwordFromDeviceAlias
                importFromBackupPage.clearAllTextFields()
            } else if (controlPanelStackView.currentIndex
                       == controlPanelStackView.importFromDevicePageId) {
                inputParaObject["archivePin"] = importFromBackupPage.text_pinFromDeviceAlias
                inputParaObject["password"]
                        = importFromDevicePage.text_passwordFromDeviceAlias
                importFromDevicePage.clearAllTextFields()
            }
            break
        case WizardView.MIGRATE:
            spinnerPage.progressLabelEditText = qsTr(
                        "Migrating your Jami account...")
            break
        case WizardView.CREATESIP:
            spinnerPage.progressLabelEditText = qsTr(
                        "Generating your SIP account...")
            if (createSIPAccountPage.text_sipFullNameEditAlias.length == 0) {
                inputParaObject["alias"] = "SIP"
            } else {
                inputParaObject["alias"] = createSIPAccountPage.text_sipFullNameEditAlias
            }

            inputParaObject["hostname"] = createSIPAccountPage.text_sipServernameEditAlias
            inputParaObject["username"] = createSIPAccountPage.text_sipUsernameEditAlias
            inputParaObject["password"] = createSIPAccountPage.text_sipPasswordEditAlias
            inputParaObject["proxy"] = createSIPAccountPage.text_sipProxyEditAlias

            break
        case WizardView.CONNECTMANAGER:
            spinnerPage.progressLabelEditText = qsTr(
                        "Connecting to account manager...")
            inputParaObject["username"]
                    = connectToAccountManagerPage.text_usernameManagerEditAlias
            inputParaObject["password"]
                    = connectToAccountManagerPage.text_passwordManagerEditAlias
            inputParaObject["manager"]
                    = connectToAccountManagerPage.text_accountManagerEditAlias
            connectToAccountManagerPage.clearAllTextFields()
            break
        }

        inputParaObject["archivePath"] = fileToImport

        if (!("archivePin" in inputParaObject)) {
            inputParaObject["archivePath"] = ""
        }

        // change page to spinner page
        changePageQML(controlPanelStackView.spinnerPageId)
        //create account
        createAccountQML()
        ClientWrapper.utilsAdaptor.createStartupLink()
    }

    function changePageQML(pageIndex) {
        controlPanelStackView.currentIndex = pageIndex
        if (pageIndex == controlPanelStackView.welcomePageStackId) {
            fileToImport = ""
            registeredNameFoundConnection.enabled = true
            createAccountPage.nameRegistrationUIState = WizardView.BLANK
        } else if (pageIndex == controlPanelStackView.createAccountPageId) {
            createAccountPage.initializeOnShowUp()
            // connection between register name found and its slot
            registeredNameFoundConnection.enabled = true
            // validate wizard progression
            validateWizardProgressionQML()
            // start photobooth
            createAccountPage.startBooth()
        } else if (pageIndex == controlPanelStackView.createSIPAccountPageId) {
            createSIPAccountPage.initializeOnShowUp()
            btnNext.enabled = true
            // start photo booth
            createSIPAccountPage.startBooth()
        } else if (pageIndex == controlPanelStackView.importFromDevicePageId) {
            importFromDevicePage.initializeOnShowUp()
        } else if (pageIndex == controlPanelStackView.spinnerPageId) {
            createAccountPage.nameRegistrationUIState = WizardView.BLANK
            createAccountPage.isToSetPassword_checkState_choosePasswordCheckBox = false
        } else if (pageIndex == controlPanelStackView.connectToAccountManagerPageId) {
            connectToAccountManagerPage.initializeOnShowUp()
            btnNext.enabled = false
        } else if (pageIndex == controlPanelStackView.importFromBackupPageId) {
            importFromBackupPage.clearAllTextFields()
            fileToImport = ""
            btnNext.enabled = false
        }
    }

    function validateWizardProgressionQML() {
        if (controlPanelStackView.currentIndex
                == controlPanelStackView.importFromDevicePageId) {
            var validPin = !(importFromDevicePage.text_pinFromDeviceAlias.length == 0)
            btnNext.enabled = validPin
            return
        } else if (controlPanelStackView.currentIndex
                   == controlPanelStackView.connectToAccountManagerPageId) {
            var validUsername = !(connectToAccountManagerPage.text_usernameManagerEditAlias.length == 0)
            var validPassword = !(connectToAccountManagerPage.text_passwordManagerEditAlias.length == 0)
            var validManager = !(connectToAccountManagerPage.text_accountManagerEditAlias.length == 0)
            btnNext.enabled = validUsername && validPassword
                    && validManager
            return
        } else if (controlPanelStackView.currentIndex
                   == controlPanelStackView.importFromBackupPageId) {
            var validImport = !(fileToImport.length == 0)
            btnNext.enabled = validImport
            return
        }

        var usernameOk = !createAccountPage.checkState_signUpCheckboxAlias
                || (createAccountPage.checkState_signUpCheckboxAlias
                    && !(registeredName.length == 0)
                    && (registeredName == createAccountPage.text_usernameEditAlias)
                    && (registrationStateOk == true))
        var passwordOk = (createAccountPage.text_passwordEditAlias
                          == createAccountPage.text_confirmPasswordEditAlias)

        // set password status label
/*        if (passwordOk
                && !(createAccountPage.text_passwordEditAlias.length == 0)) {
            createAccountPage.displayState_passwordStatusLabelAlias = "Success"
        } else if (!passwordOk) {
            createAccountPage.displayState_passwordStatusLabelAlias = "Fail"
        } else {
            createAccountPage.displayState_passwordStatusLabelAlias = "Hide"
        }*/
        //set enable state of next button
        //btnNext.enabled = (usernameOk && passwordOk)
    }

    PasswordDialog {
        id: passwordDialog

        anchors.centerIn: parent.Center
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        visible: false
        purpose: PasswordDialog.ExportAccount

        onDoneSignal: {
            if (currentPurpose === passwordDialog.ExportAccount) {
                var success = (code === successCode)

                var title = success ? qsTr("Success") : qsTr("Error")
                var info = success ? qsTr("Export Successful") : qsTr(
                                         "Export Failed")

                ClientWrapper.accountAdaptor.passwordSetStatusMessageBox(success,
                                                         title, info)
                if (success) {
                    console.log("Account Export Succeed")
                    needToShowMainViewWindow(addedAccountIndex)
                    ClientWrapper.lrcInstance.accountListChanged()
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus()
    }

    // TODO scrollview

    ColumnLayout {
        anchors.fill: parent

        StackLayout {
            id: controlPanelStackView
            currentIndex: welcomePageStackId
            anchors.fill: parent

            property int welcomePageStackId: 0
            property int createAccountPageId: 1
            property int createSIPAccountPageId: 2
            property int importFromBackupPageId: 3
            property int backupKeysPageId: 4
            property int importFromDevicePageId: 5
            property int connectToAccountManagerPageId: 6
            property int spinnerPageId: 7

            WelcomePageLayout {
                // welcome page, index 0
                id: welcomePage

                onWelcomePageRedirectPage: {
                    changePageQML(toPageIndex)
                }

                onLeavePage: {
                    wizardViewIsClosed()
                }
            }

            CreateAccountPage {
                // create account page, index 1
                id: createAccountPage

                onCreateAccount: {
                    wizardMode = WizardView.CREATE
                    ClientWrapper.accountAdaptor.createJamiAccount(
                        text_usernameEditAlias.text,
                        {/* TODO */},
                        createAccountPage.boothImgBase64,
                        true)
                }

                onText_usernameEditAliasChanged: {
                    registrationStateOk = false
                    lookupTimer.restart()
                }

                onValidateWizardProgressionCreateAccountPage: {
                    validateWizardProgressionQML()
                }

                onLeavePage: {
                    changePageQML(controlPanelStackView.welcomePageStackId)
                }

                onText_passwordEditAliasChanged: {
                    validateWizardProgressionQML()
                }

                onText_confirmPasswordEditAliasChanged: {
                    validateWizardProgressionQML()
                }

                Timer {
                    id: lookupTimer

                    repeat: false
                    triggeredOnStart: false
                    interval: 200

                    onTriggered: {
                        registeredName = createAccountPage.text_usernameEditAlias
                        if (registeredName.length !== 0) {
                            createAccountPage.nameRegistrationUIState = WizardView.SEARCHING
                            ClientWrapper.nameDirectory.lookupName("", registeredName)
                        } else {
                            createAccountPage.nameRegistrationUIState = WizardView.BLANK
                        }
                    }
                }
            }

            CreateSIPAccountPage {
                // create SIP account page, index 2
                id: createSIPAccountPage
            }

            ImportFromBackupPage {
                // import from backup page, index 3
                id: importFromBackupPage

                onLeavePage: {
                    changePageQML(controlPanelStackView.welcomePageStackId)
                }

                onImportAccount: {
                    inputParaObject["archivePath"] = importFromBackupPage.filePath
                    console.log("@@@" + importFromBackupPage.filePath)
                    inputParaObject["password"] = importFromBackupPage.text_passwordFromBackupEditAlias
                    importFromBackupPage.clearAllTextFields()

                    ClientWrapper.accountAdaptor.createJamiAccount(
                        "", inputParaObject, "", false)
                    changePageQML(controlPanelStackView.spinnerPageId)
                }
            }

            BackupKeyPage {
                    // backup keys page, index 4
                    id: backupKeysPage

                    onNeverShowAgainBoxClicked: {
                        ClientWrapper.accountAdaptor.settingsNeverShowAgain(isChecked)
                    }

                    onExport_Btn_FileDialogAccepted: {
                        if (accepted) {
                            // is there password? If so, go to password dialog, else, go to following directly
                            if (ClientWrapper.accountAdaptor.hasPassword()) {
                                passwordDialog.path = ClientWrapper.utilsAdaptor.getAbsPath(folderDir)
                                passwordDialog.open()
                                return
                            } else {
                                if (folderDir.length > 0) {
                                    ClientWrapper.accountAdaptor.exportToFile(
                                                ClientWrapper.utilsAdaptor.getCurrAccId(),
                                                ClientWrapper.utilsAdaptor.getAbsPath(folderDir))
                                }
                            }
                        }

                        changePageQML(controlPanelStackView.welcomePageStackId)
                        needToShowMainViewWindow(addedAccountIndex)
                        ClientWrapper.lrcInstance.accountListChanged()
                    }

                    onLeavePage: {
                        changePageQML(controlPanelStackView.welcomePageStackId)
                        needToShowMainViewWindow(addedAccountIndex)
                        ClientWrapper.lrcInstance.accountListChanged()
                    }
            }

            ImportFromDevicePage {
                // import from device page, index 5
                id: importFromDevicePage

                onLeavePage: {
                    changePageQML(controlPanelStackView.welcomePageStackId)
                }

                onImportAccount: {
                    inputParaObject["archivePin"] = importFromDevicePage.text_pinFromDeviceAlias
                    inputParaObject["password"] = importFromDevicePage.text_passwordFromDeviceAlias

                    ClientWrapper.accountAdaptor.createJamiAccount(
                        "", inputParaObject, "", false)

                }
            }

            ConnectToAccountManagerPage {
                // connect to account manager Page, index 6
                id: connectToAccountManagerPage

                onCreateAccount: {
                    inputParaObject = {}
                    inputParaObject["username"]
                            = connectToAccountManagerPage.text_usernameManagerEditAlias
                    inputParaObject["password"]
                            = connectToAccountManagerPage.text_passwordManagerEditAlias
                    inputParaObject["manager"]
                            = connectToAccountManagerPage.text_accountManagerEditAlias
                    ClientWrapper.accountAdaptor.createJAMSAccount(inputParaObject)
                }

                onLeavePage: {
                    changePageQML(controlPanelStackView.welcomePageStackId)
                }
            }

            SpinnerPage {
                // spinner Page, index 7
                id: spinnerPage
            }
        }

    }
}
