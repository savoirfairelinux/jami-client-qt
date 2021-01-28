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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../"
import "../commoncomponents"
import "components"

Rectangle {
    id: root

//    enum WizardViewPageIndex {
//        WELCOMEPAGE = 0,
//        CREATEACCOUNTPAGE,
//        CREATESIPACCOUNTPAGE,
//        IMPORTFROMBACKUPPAGE,
//        BACKUPKEYSPAGE,
//        IMPORTFROMDEVICEPAGE,
//        CONNECTTOACCOUNTMANAGERPAGE,
//        PROFILEPAGE,
//        CREATERENDEZVOUS
//    }

    readonly property int layoutSpacing: 12
    readonly property int backButtonMargins: 20

    property int textFontSize: 9
    property int addedAccountIndex: -1
    property bool isRdv: false
    property bool showBackUp: false
    property bool showProfile: false
    property bool showBottom: false
    property string fileToImport: ""
    property string registeredName: ""

    property var inputParaObject: ({})

    // signal to redirect the page to main view
    signal loaderSourceChangeRequested(int sourceToLoad)
    signal wizardViewIsClosed

    visible: true
    color: JamiTheme.backgroundColor

    Component.onCompleted: {
        changePageQML(0)
    }

    Connections {
        target: AccountAdapter

        enabled: controlPanelStackView.currentIndex !== 0

        onAccountAdded: {
            addedAccountIndex = index
            AccountAdapter.accountChanged(index)
            if (showProfile) {
                changePageQML(7)
                profilePage.readyToSaveDetails()
                profilePage.isRdv = isRdv
                profilePage.createdAccountId = accountId
            } else if (controlPanelStackView.currentIndex === 7) {
                profilePage.readyToSaveDetails()
                profilePage.isRdv = isRdv
                profilePage.createdAccountId = accountId
            } else if (showBackUp) {
                changePageQML(4)
            } else {
                changePageQML(0)
                loaderSourceChangeRequested(1)
            }
        }

        // reportFailure
        onReportFailure: {
            var errorMessage = JamiStrings.errorCreateAccount

            switch(controlPanelStackView.currentIndex) {
            case 5:
                importFromDevicePage.errorOccured(errorMessage)
                break
            case 3:
                importFromBackupPage.errorOccured(errorMessage)
                break
            case 6:
                connectToAccountManagerPage.errorOccured(errorMessage)
                break
            }
        }
    }

    function changePageQML(pageIndex) {
        controlPanelStackView.currentIndex = pageIndex
        if (pageIndex === 0) {
            fileToImport = ""
            isRdv = false
            createAccountPage.nameRegistrationUIState = 0
        } else if (pageIndex === 1) {
            createAccountPage.initializeOnShowUp(false)
        } else if (pageIndex === 2) {
            createSIPAccountPage.initializeOnShowUp()
        } else if (pageIndex === 5) {
            importFromDevicePage.initializeOnShowUp()
        } else if (pageIndex === 6) {
            connectToAccountManagerPage.initializeOnShowUp()
        } else if (pageIndex === 3) {
            importFromBackupPage.clearAllTextFields()
            fileToImport = ""
        } else if (pageIndex === 7) {
            profilePage.initializeOnShowUp()
            profilePage.showBottom = showBottom
        } else if (pageIndex === 8) {
            isRdv = true
            controlPanelStackView.currentIndex = 1
            createAccountPage.initializeOnShowUp(true)
        }
    }

    PasswordDialog {
        id: passwordDialog

        visible: false
        purpose: 1

        onDoneSignal: {
            if (currentPurpose === passwordDialog.ExportAccount) {
                var title = success ? qsTr("Success") : qsTr("Error")
                var info = success ? JamiStrings.backupSuccessful : JamiStrings.backupFailed

                AccountAdapter.passwordSetStatusMessageBox(success,
                                                         title, info)
                if (success) {
                    console.log("Account Export Succeed")
                    loaderSourceChangeRequested(1)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus()
    }

    ScrollView {
        id: wizardViewScrollView

        property ScrollBar vScrollBar: ScrollBar.vertical

        anchors.fill: parent

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        clip: true
        contentHeight: controlPanelStackView.height

        StackLayout {
            id: controlPanelStackView

            anchors.centerIn: parent

            width: wizardViewScrollView.width

            currentIndex: 0

            Component.onCompleted: {
                // avoid binding loop
                height = Qt.binding(function (){
                    var index = currentIndex
                            === 8 ?
                                1 : currentIndex
                    return Math.max(
                                controlPanelStackView.itemAt(index).preferredHeight,
                                wizardViewScrollView.height)
                })
            }

            WelcomePage {
                id: welcomePage

                Layout.alignment: Qt.AlignCenter

                onWelcomePageRedirectPage: {
                    changePageQML(toPageIndex)
                }

                onLeavePage: {
                    wizardViewIsClosed()
                }

                onScrollToBottom: {
                    if (welcomePage.preferredHeight > root.height)
                        wizardViewScrollView.vScrollBar.position = 1
                }
            }

            CreateAccountPage {
                id: createAccountPage

                Layout.alignment: Qt.AlignCenter

                onCreateAccount: {
                    inputParaObject = {}
                    inputParaObject["isRendezVous"] = isRdv
                    inputParaObject["password"] = text_passwordEditAlias
                    AccountAdapter.createJamiAccount(
                        createAccountPage.text_usernameEditAlias,
                        inputParaObject,
                        true)
                    showBackUp = !isRdv
                    showBottom = true
                    changePageQML(7)
                }

                onLeavePage: {
                    changePageQML(0)
                }
            }

            CreateSIPAccountPage {
                id: createSIPAccountPage

                Layout.alignment: Qt.AlignCenter

                onLeavePage: {
                    changePageQML(0)
                }

                onCreateAccount: {
                    inputParaObject = {}
                    inputParaObject["hostname"] = createSIPAccountPage.text_sipServernameEditAlias
                    inputParaObject["username"] = createSIPAccountPage.text_sipUsernameEditAlias
                    inputParaObject["password"] = createSIPAccountPage.text_sipPasswordEditAlias
                    inputParaObject["proxy"] = createSIPAccountPage.text_sipProxyEditAlias
                    createSIPAccountPage.clearAllTextFields()

                    AccountAdapter.createSIPAccount(inputParaObject, "")
                    showBackUp = false
                    showBottom = false
                    changePageQML(7)
                    controlPanelStackView.profilePage.readyToSaveDetails()
                }
            }

            ImportFromBackupPage {
                id: importFromBackupPage

                Layout.alignment: Qt.AlignCenter

                onLeavePage: {
                    changePageQML(0)
                }

                onImportAccount: {
                    inputParaObject = {}
                    inputParaObject["archivePath"] = UtilsAdapter.getAbsPath(importFromBackupPage.filePath)
                    inputParaObject["password"] = importFromBackupPage.text_passwordFromBackupEditAlias
                    showBackUp = false
                    showBottom = false
                    showProfile = true
                    AccountAdapter.createJamiAccount(
                        "", inputParaObject, "", false)
                }
            }

            BackupKeyPage {
                id: backupKeysPage

                Layout.alignment: Qt.AlignCenter

                onNeverShowAgainBoxClicked: {
                    SettingsAdapter.setValue(7, isChecked)
                }

                onExport_Btn_FileDialogAccepted: {
                    if (accepted) {
                        // is there password? If so, go to password dialog, else, go to following directly
                        if (AccountAdapter.hasPassword()) {
                            passwordDialog.path = UtilsAdapter.getAbsPath(folderDir)
                            passwordDialog.open()
                            return
                        } else {
                            if (folderDir.length > 0) {
                                AccountAdapter.exportToFile(
                                            AccountAdapter.currentAccountId,
                                            UtilsAdapter.getAbsPath(folderDir))
                            }
                        }
                    }

                    changePageQML(0)
                    loaderSourceChangeRequested(1)
                }

                onLeavePage: {
                    changePageQML(0)
                    loaderSourceChangeRequested(1)
                }
            }

            ImportFromDevicePage {
                id: importFromDevicePage

                Layout.alignment: Qt.AlignCenter

                onLeavePage: {
                    changePageQML(0)
                }

                onImportAccount: {
                    inputParaObject = {}
                    inputParaObject["archivePin"] = importFromDevicePage.text_pinFromDeviceAlias
                    inputParaObject["password"] = importFromDevicePage.text_passwordFromDeviceAlias

                    showProfile = true
                    showBackUp = false
                    showBottom = false
                    AccountAdapter.createJamiAccount(
                        "", inputParaObject, "", false)
                }
            }

            ConnectToAccountManagerPage {
                id: connectToAccountManagerPage

                Layout.alignment: Qt.AlignCenter

                onCreateAccount: {
                    inputParaObject = {}
                    inputParaObject["username"]
                            = connectToAccountManagerPage.text_usernameManagerEditAlias
                    inputParaObject["password"]
                            = connectToAccountManagerPage.text_passwordManagerEditAlias
                    inputParaObject["manager"]
                            = connectToAccountManagerPage.text_accountManagerEditAlias
                    AccountAdapter.createJAMSAccount(inputParaObject)
                }

                onLeavePage: {
                    changePageQML(0)
                }
            }

            ProfilePage {
                id: profilePage

                Layout.alignment: Qt.AlignCenter

                function leave() {
                    if (showBackUp)
                        changePageQML(4)
                    else {
                        changePageQML(0)
                        loaderSourceChangeRequested(1)
                    }

                    profilePage.initializeOnShowUp()
                }

                onSaveProfile: {
                    avatarBooth.manualSaveToConfig()
                    AccountAdapter.setCurrAccDisplayName(profilePage.displayName)
                    leave()
                }

                onLeavePage: leave()
            }
        }
    }
}
