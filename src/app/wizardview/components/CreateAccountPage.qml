/*
* Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../"
import "../../commoncomponents"
import "../../settingsview/components"
import "../../mainview/components"
import "../../commoncomponents/contextmenu"

Rectangle {
    id: root

    property bool isRendezVous: false
    property bool helpOpened: false
    property int preferredHeight: createAccountStack.implicitHeight
    property string chosenDisplayName: ""

    signal showThisPage

    function initializeOnShowUp(isRdv) {
        root.isRendezVous = isRdv;
        createAccountStack.currentIndex = 0;
        clearAllTextFields();
        usernameEdit.forceActiveFocus();
    }

    function clearAllTextFields() {
        joinJamiButton.enabled = true;
        encryptButton.enabled = true;
        usernameEdit.modifiedTextFieldContent = "";
    }

    color: JamiTheme.secondaryBackgroundColor

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            var currentMainStep = WizardViewStepModel.mainStep;
            if (currentMainStep === WizardViewStepModel.MainSteps.NameRegistration) {
                createAccountStack.currentIndex = nameRegistrationPage.stackIndex;
                initializeOnShowUp(WizardViewStepModel.accountCreationOption
                                   === WizardViewStepModel.AccountCreationOption.CreateRendezVous);
                root.showThisPage();
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            adviceBox.checked = false;
        }
    }

    StackLayout {
        id: createAccountStack

        objectName: "createAccountStack"
        anchors.fill: parent

        Rectangle {
            id: nameRegistrationPage

            objectName: "nameRegistrationPage"

            Layout.fillHeight: true
            Layout.fillWidth: true

            property int stackIndex: 0

            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                id: usernameColumnLayout

                spacing: JamiTheme.wizardViewPageLayoutSpacing

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(508, root.width - 100)

                Text {
                    id: joinJami

                    text: root.isRendezVous ? JamiStrings.createNewRV : JamiStrings.joinJami
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize
                                                    * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
                    wrapMode: Text.WordWrap
                }

                Text {

                    text: root.isRendezVous ? JamiStrings.chooseUsernameForRV :
                                              JamiStrings.chooseUsernameForAccount
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize
                                                    * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor

                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                    wrapMode: Text.WordWrap
                    lineHeight: JamiTheme.wizardViewTextLineHeight
                }

                UsernameTextEdit {
                    id: usernameEdit
                    objectName: "usernameEdit"

                    accountId: ""

                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                    textFieldContent: ""

                    KeyNavigation.tab: infoPopup
                    KeyNavigation.up: backButton
                    KeyNavigation.down: infoPopup

                    Accessible.role: Accessible.EditableText
                    Accessible.name: usernameEdit.supportingText
                }

                NewMaterialButton {
                    id: joinJamiButton

                    objectName: "joinJamiButton"

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

                    implicitHeight: JamiTheme.newMaterialButtonSetupHeight

                    z: -1

                    filledButton: true

                    font.capitalization: Font.AllUppercase
                    text: !enabled ? JamiStrings.creatingAccount : root.isRendezVous
                                     ? JamiStrings.chooseName : JamiStrings.joinJami
                    enabled: usernameEdit.nameRegistrationState
                             === UsernameTextEdit.NameRegistrationState.FREE
                             || usernameEdit.nameRegistrationState
                             === UsernameTextEdit.NameRegistrationState.BLANK

                    KeyNavigation.tab: encryptButton
                    KeyNavigation.up: usernameEdit
                    KeyNavigation.down: encryptButton

                    onClicked: {
                        WizardViewStepModel.accountCreationInfo = JamiQmlUtils.setUpAccountCreationInputPara({
                                                                                                                 "registeredName": usernameEdit.modifiedTextFieldContent,
                                                                                                                 "alias": root.chosenDisplayName,
                                                                                                                 "password": advancedButtons.chosenPassword,
                                                                                                                 "avatar": UtilsAdapter.tempCreationImage(),
                                                                                                                 "isRendezVous": root.isRendezVous
                                                                                                             });
                        if (usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.FREE) {
                            enabled = false;
                            encryptButton.enabled = false;
                            WizardViewStepModel.nextStep();
                        }
                        if (usernameEdit.nameRegistrationState
                                === UsernameTextEdit.NameRegistrationState.BLANK)
                            popup.visible = true;
                        UtilsAdapter.setTempCreationImageFromString("", "temp");
                    }
                    Accessible.description: invalidLabel.text
                }

                RowLayout {
                    id: advancedButtons

                    Layout.alignment: Qt.AlignCenter

                    property string chosenPassword: ""

                    spacing: 5

                    NewMaterialButton {
                        id: encryptButton

                        Layout.alignment: Qt.AlignCenter
                        Layout.topMargin: 2 * JamiTheme.wizardViewBlocMarginSize

                        textButton: true
                        text: JamiStrings.setPassword
                        toolTipText: JamiStrings.encryptWithPassword

                        KeyNavigation.tab: backButton
                        KeyNavigation.up: joinJamiButton
                        KeyNavigation.down: backButton
                        KeyNavigation.right: backButton

                        onClicked: {
                            var dlg = viewCoordinator.presentDialog(appWindow,
                                                                    "wizardview/components/EncryptAccountPopup.qml");
                            dlg.accepted.connect(function (password) {
                                advancedButtons.chosenPassword = password;
                            });
                        }
                    }
                }

                NoUsernamePopup {
                    id: popup

                    objectName: "popup"

                    visible: false

                    onJoinClicked: {
                        joinJamiButton.enabled = false;
                        encryptButton.enabled = false;
                    }
                }
            }
        }
    }

    JamiPushButton {
        id: backButton
        QWKSetParentHitTestVisible {}

        objectName: "createAccountPageBackButton"

        preferredSize: 36
        imageContainerWidth: 20
        source: JamiResources.ic_arrow_back_24dp_svg

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.backButton
        Accessible.description: JamiStrings.backButtonExplanation

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        KeyNavigation.tab: adviceBox
        KeyNavigation.down: KeyNavigation.tab

        onClicked: {
            adviceBox.checked = false;
            if (createAccountStack.currentIndex > 0) {
                createAccountStack.currentIndex--;
            } else {
                WizardViewStepModel.previousStep();
                helpOpened = false;
            }
        }
    }

    NewIconButton {
        id: adviceBox

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins
        anchors.topMargin: UtilsAdapter.getAppValue(Settings.Key.UseFramelessWindow) ? JamiTheme.qwkTitleBarHeight : JamiTheme.wizardViewPageBackButtonMargins

        z: 1

        iconSource: JamiResources._black_24dp_svg
        iconSize: JamiTheme.iconButtonMedium
        toolTipText: JamiStrings.adviceBoxExplanation

        checkable: true

        onClicked: {
            if (!helpOpened) {
                checked = true;
                helpOpened = true;
                var dlg = viewCoordinator.presentDialog(appWindow,
                                                        "wizardview/components/GoodToKnowPopup.qml");
                dlg.accepted.connect(function () {
                    checked = false;
                    helpOpened = false;
                });
            }
        }

        KeyNavigation.tab: !createAccountStack.currentIndex ? usernameEdit :
                                                              advancedAccountSettingsPage
        KeyNavigation.up: backButton
        KeyNavigation.down: KeyNavigation.tab

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.adviceBox
        Accessible.description: JamiStrings.adviceBoxExplanation
    }

    Component.onDestruction: UtilsAdapter.setTempCreationImageFromString("", "temp")
}
