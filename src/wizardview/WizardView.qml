/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0
import net.jami.Enums 1.0

import "../"
import "../commoncomponents"
import "components"

Rectangle {
    id: root

    // signal to redirect the page to main view
    signal loaderSourceChangeRequested(int sourceToLoad)

    color: JamiTheme.backgroundColor

    Connections{
        target: AccountAdapter

        // reportFailure
        function onReportFailure() {
            var errorMessage = JamiStrings.errorCreateAccount

            switch(controlPanelStackView.currentIndex) {
            case importFromDevicePage.stackLayoutIndex:
                importFromDevicePage.errorOccured(errorMessage)
                break
            case importFromBackupPage.stackLayoutIndex:
                importFromBackupPage.errorOccured(errorMessage)
                break
            case connectToAccountManagerPage.stackLayoutIndex:
                connectToAccountManagerPage.errorOccured(errorMessage)
                break
            }
        }
    }

    Connections {
        target: WizardViewStepModel

        function onCloseWizardView() {
            loaderSourceChangeRequested(MainApplicationWindow.LoadedSource.MainView)
        }
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

            WelcomePage {
                id: welcomePage

                property int stackLayoutIndex: 0

                onShowThisPage: controlPanelStackView.currentIndex = stackLayoutIndex

                onScrollToBottom: {
                    if (welcomePage.preferredHeight > root.height)
                        wizardViewScrollView.vScrollBar.position = 1
                }
            }

            CreateAccountPage {
                id: createAccountPage

                property int stackLayoutIndex: 1

                onShowThisPage: controlPanelStackView.currentIndex = stackLayoutIndex
            }

            ProfilePage {
                id: profilePage

                property int stackLayoutIndex: 2

                onShowThisPage: controlPanelStackView.currentIndex = stackLayoutIndex
            }

            BackupKeyPage {
                id: backupKeysPage

                property int stackLayoutIndex: 3

                onShowThisPage: controlPanelStackView.currentIndex = stackLayoutIndex
            }

            ImportFromDevicePage {
                id: importFromDevicePage

                property int stackLayoutIndex: 4

                onShowThisPage: controlPanelStackView.currentIndex = stackLayoutIndex
            }

            ImportFromBackupPage {
                id: importFromBackupPage

                property int stackLayoutIndex: 5

                onShowThisPage: controlPanelStackView.currentIndex = stackLayoutIndex
            }

            ConnectToAccountManagerPage {
                id: connectToAccountManagerPage

                property int stackLayoutIndex: 6

                onShowThisPage: controlPanelStackView.currentIndex = stackLayoutIndex
            }

            CreateSIPAccountPage {
                id: createSIPAccountPage

                property int stackLayoutIndex: 7

                onShowThisPage: controlPanelStackView.currentIndex = stackLayoutIndex
            }

            Component.onCompleted: {
                // avoid binding loop
                height = Qt.binding(function (){
                    var index = currentIndex
                            === WizardViewStepModel.MainSteps.CreateRendezVous ?
                                WizardViewStepModel.MainSteps.CreateJamiAccount : currentIndex
                    return Math.max(
                                controlPanelStackView.itemAt(index).preferredHeight,
                                wizardViewScrollView.height)
                })
            }
        }
    }
}
