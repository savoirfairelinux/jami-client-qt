/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import "../"
import "../commoncomponents"
import "components"

BaseView {
    id: root
    objectName: "WizardView"

    inhibits: ["ConversationView"]

    color: JamiTheme.secondaryBackgroundColor

    Connections {
        target: AccountAdapter

        // reportFailure
        function onReportFailure() {
            var errorMessage = JamiStrings.errorCreateAccount;
            for (var i = 0; i < controlPanelStackView.children.length; i++) {
                if (i === controlPanelStackView.currentIndex) {
                    controlPanelStackView.children[i].errorOccurred(errorMessage);
                    return;
                }
            }
        }
    }

    // Handle the end of the wizard account creation process.
    Connections {
        target: WizardViewStepModel
        function onCreateAccountRequested(creationOption) {
            switch (creationOption) {
            case WizardViewStepModel.AccountCreationOption.CreateJamiAccount:
                AccountAdapter.createJamiAccount(WizardViewStepModel.accountCreationInfo);
                break;
            case WizardViewStepModel.AccountCreationOption.CreateRendezVous:
            case WizardViewStepModel.AccountCreationOption.ImportFromBackup:
            case WizardViewStepModel.AccountCreationOption.ImportFromDevice:
                // console.info("[LinkDevice] Requesting P2P account client-side.");
                // AccountAdapter.startLinkDevice();
                break;
            case WizardViewStepModel.AccountCreationOption.ConnectToAccountManager:
                AccountAdapter.createJAMSAccount(WizardViewStepModel.accountCreationInfo);
                break;
            case WizardViewStepModel.AccountCreationOption.CreateSipAccount:
                AccountAdapter.createSIPAccount(WizardViewStepModel.accountCreationInfo);
                break;
            default:
                print("Bad account creation option: " + creationOption);
                WizardViewStepModel.closeWizardView();
                break;
            }
        }

        function onLinkStateChanged(linkOption) {
            print("[LinkDevice] WizardView page: onLinkStateChanged")
            switch (linkOption) {
            // case WizardViewStepModel.LinkDeviceStep.OutOfBand:
            //     controlPanelStackView.setPage(
            //         importFromDevicePage
            //     )
            //     break;
            case WizardViewStepModel.LinkDeviceStep.Waiting:
                controlPanelStackView.setPage(
                    linkDeviceLoadingPage
                )
                break;
            case WizardViewStepModel.LinkDeviceStep.Scannable:
                controlPanelStackView.setPage(
                    linkDeviceQrPage
                )
                break;
                // TODO add another waiting phase
            case WizardViewStepModel.LinkDeviceStep.Auth:
                controlPanelStackView.setPage(
                    linkDeviceAuthPage
                )
                break;
            default:
                break;
            }
        }
    }

    Connections {
        target: WizardViewStepModel

        function onCloseWizardView() {
            root.dismiss();
            viewCoordinator.present("WelcomePage");
        }
    }

    JamiFlickable {
        id: wizardViewScrollView

        property ScrollBar vScrollBar: ScrollBar.vertical

        anchors.fill: parent
        anchors.topMargin: appWindow.useFrameless && Qt.platform.os.toString() === "osx" ? 16 : 0

        contentHeight: controlPanelStackView.height
        boundsBehavior: Flickable.StopAtBounds

        StackLayout {
            id: controlPanelStackView

            objectName: "controlPanelStackView"

            function setPage(obj) {
                wizardViewScrollView.vScrollBar.position = 0;
                for (var i in this.children) {
                    if (this.children[i] === obj) {
                        currentIndex = i;
                        return;
                    }
                }
            }

            anchors.centerIn: parent

            width: wizardViewScrollView.width

            WelcomePage {
                id: welcomePage

                objectName: "welcomePage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }

            CreateAccountPage {
                id: createAccountPage

                objectName: "createAccountPage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }

            ImportFromDevicePage {
                id: importFromDevicePage

                objectName: "importFromDevicePage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }
            // Link Device Pages
            ImportFromBackupPage {
                id: importFromBackupPage

                objectName: "importFromBackupPage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }

            LinkDeviceLoadingPage {
                id: linkDeviceLoadingPage

                objectName: "linkDeviceLoadingPage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }

            LinkDeviceQrPage {
                id: linkDeviceQrPage

                objectName: "linkDeviceQrPage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }

            LinkDeviceAuthPage {
                id: linkDeviceAuthPage

                objectName: "linkDeviceAuthPage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }

            ConnectToAccountManagerPage {
                id: connectToAccountManagerPage

                objectName: "connectToAccountManagerPage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }

            CreateSIPAccountPage {
                id: createSIPAccountPage

                objectName: "createSIPAccountPage"

                onShowThisPage: controlPanelStackView.setPage(this)
            }

            Component.onCompleted: {
                // avoid binding loop
                height = Qt.binding(function () {
                        var index = currentIndex === WizardViewStepModel.MainSteps.CreateRendezVous ? WizardViewStepModel.MainSteps.CreateJamiAccount : currentIndex;
                        return Math.max(controlPanelStackView.itemAt(index).preferredHeight, wizardViewScrollView.height);
                    });
            }
        }
    }
}
