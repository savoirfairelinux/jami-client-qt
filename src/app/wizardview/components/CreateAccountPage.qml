/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../"
import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root

    property bool isRendezVous: false
    property int preferredHeight: {
        if (createAccountStack.currentIndex === 0)
            return usernameColumnLayout.implicitHeight
        return passwordColumnLayout.implicitHeight
    }

    signal showThisPage

    function initializeOnShowUp(isRdv) {
        isRendezVous = isRdv
        createAccountStack.currentIndex = 0
        clearAllTextFields()
        passwordSwitch.checked = false
    }

    function clearAllTextFields() {
        usernameEdit.clear()
        passwordEdit.clear()
        passwordConfirmEdit.clear()
    }

    color: JamiTheme.backgroundColor

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            var currentMainStep = WizardViewStepModel.mainStep
            if (currentMainStep === WizardViewStepModel.MainSteps.NameRegistration) {
                createAccountStack.currentIndex = nameRegistrationPage.stackIndex
                initializeOnShowUp(WizardViewStepModel.accountCreationOption ===
                                   WizardViewStepModel.AccountCreationOption.CreateRendezVous)
                root.showThisPage()
            } else if (currentMainStep === WizardViewStepModel.MainSteps.SetPassword) {
                createAccountStack.currentIndex = passwordSetupPage.stackIndex
            }
        }
    }

    StackLayout {
        id: createAccountStack

        objectName: "createAccountStack"

        anchors.fill: parent

        Rectangle {
            id: nameRegistrationPage

            objectName: "nameRegistrationPage"

            property int stackIndex: 0

            color: JamiTheme.backgroundColor



            ColumnLayout {
                id: usernameColumnLayout

                spacing: JamiTheme.wizardViewPageLayoutSpacing

                anchors.fill: parent
                //                width: root.width
                //                height: root.height

                RowLayout {

                    Layout.preferredWidth: parent.width
                    Layout.alignment: Qt.AlignTop

                    BackButton {
                        id: backButton

                        objectName: "createAccountPageBackButton"
                        Layout.alignment: Qt.AlignLeft
                        Layout.leftMargin: 20
                        Layout.topMargin: 20

                        preferredSize: JamiTheme.wizardViewPageBackButtonSize

                        KeyNavigation.tab: {
                            if (createAccountStack.currentIndex === nameRegistrationPage.stackIndex)
                                return usernameEdit
                            else
                                return passwordSwitch
                        }
                        KeyNavigation.up: {
                            if (createAccountStack.currentIndex === nameRegistrationPage.stackIndex)
                                return skipButton
                            else
                                return createAccountButton.enabled ? createAccountButton : passwordConfirmEdit
                        }
                        KeyNavigation.down: KeyNavigation.tab

                        onClicked: WizardViewStepModel.previousStep()
                    }

                    PushButton {

                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 20
                        Layout.rightMargin: 10
                        normalColor: JamiTheme.backgroundColor
                        imageColor: JamiTheme.primaryForegroundColor
                        circled: false
                        source: JamiResources.hand_black_24dp_svg


                    }

                }

                Text {
                    id: joinJami

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                    Layout.preferredHeight: contentHeight

                    text: JamiStrings.joinJami
                    color: JamiTheme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    font.pixelSize: 26
                    font.kerning: true
                }

                Label {
                    Layout.alignment: Qt.AlignCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: isRendezVous ? JamiStrings.chooseUsernameForRV :
                                         JamiStrings.chooseUsernameForAccount
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize + 3
                }

                UsernameLineEdit {
                    id: usernameEdit

                    objectName: "usernameEdit"

                    Layout.topMargin: 15
                    Layout.preferredHeight: fieldLayoutHeight
                    Layout.preferredWidth:  chooseUsernameButton.width
                    Layout.alignment: Qt.AlignHCenter


                    focus: visible

                    KeyNavigation.tab: chooseUsernameButton.enabled ? chooseUsernameButton :
                                                                      skipButton
                    KeyNavigation.up: backButton
                    KeyNavigation.down: KeyNavigation.tab

                    placeholderText: isRendezVous ? JamiStrings.chooseAName :
                                                    JamiStrings.chooseYourUserName

                    onAccepted: {
                        if (chooseUsernameButton.enabled)
                            chooseUsernameButton.clicked()
                        else
                            skipButton.clicked()
                    }
                }

                IdentifierLineEdit {
                    id: identifierEdit
                    editable: true

                    Layout.alignment: Qt.AlignHCenter

                    font.pointSize: JamiTheme.menuFontSize

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    text: CurrentConversation.description
                    placeholderText: isRendezVous ? JamiStrings.chooseAName :
                                                    JamiStrings.chooseYourUserName
                    placeholderTextColor: {
                        if (editable) {
                            if (UtilsAdapter.luma(root.color)) {
                                return JamiTheme.placeholderTextColorWhite
                            } else {
                                return JamiTheme.placeholderTextColor
                            }
                        } else {
                            if (UtilsAdapter.luma(root.color)) {
                                return JamiTheme.chatviewTextColorLight
                            } else {
                                return JamiTheme.chatviewTextColorDark
                            }
                        }
                    }
                    tooltipText: JamiStrings.addADescription
                    backgroundColor: root.color
                    color: UtilsAdapter.luma(backgroundColor) ?
                               JamiTheme.chatviewTextColorLight :
                               JamiTheme.chatviewTextColorDark

                    //                    onAccepted: {
                    //                        if (chooseUsernameButton.enabled)
                    //                            chooseUsernameButton.clicked()
                    //                        else
                    //                            skipButton.clicked()
                    //                    }
                }


                Label {
                    Layout.alignment: Qt.AlignHCenter

                    visible: text.length !==0

                    text: {
                        switch(usernameEdit.nameRegistrationState){
                        case UsernameLineEdit.NameRegistrationState.BLANK:
                        case UsernameLineEdit.NameRegistrationState.SEARCHING:
                        case UsernameLineEdit.NameRegistrationState.FREE:
                            return ""
                        case UsernameLineEdit.NameRegistrationState.INVALID:
                            return isRendezVous ? JamiStrings.invalidName :
                                                  JamiStrings.invalidUsername
                        case UsernameLineEdit.NameRegistrationState.TAKEN:
                            return isRendezVous ? JamiStrings.nameAlreadyTaken :
                                                  JamiStrings.usernameAlreadyTaken
                        }
                    }
                    font.pointSize: JamiTheme.textFontSize
                    color: JamiTheme.redColor
                }

                MaterialButton {
                    id: chooseUsernameButton

                    objectName: "chooseUsernameButton"

                    Layout.alignment: Qt.AlignCenter
                    primary: true

                    preferredWidth: JamiTheme.wizardButtonWidth

                    font.capitalization: Font.AllUppercase
                    text: isRendezVous ? JamiStrings.chooseName : JamiStrings.joinJami
                    enabled: usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.FREE

                    KeyNavigation.tab: skipButton
                    KeyNavigation.up: usernameEdit
                    KeyNavigation.down: KeyNavigation.tab

                    onClicked: WizardViewStepModel.nextStep()
                }

                MaterialButton {
                    id: skipButton

                    objectName: "nameRegistrationPageSkipButton"

                    Layout.alignment: Qt.AlignCenter

                    preferredWidth: JamiTheme.wizardButtonWidth

                    text: JamiStrings.skip
                    color: JamiTheme.buttonTintedGrey
                    hoveredColor: JamiTheme.buttonTintedGreyHovered
                    pressedColor: JamiTheme.buttonTintedGreyPressed
                    outlined: true

                    KeyNavigation.tab: backButton
                    KeyNavigation.up: chooseUsernameButton.enabled ? chooseUsernameButton :
                                                                     usernameEdit
                    KeyNavigation.down: KeyNavigation.tab

                    onClicked: {
                        usernameEdit.clear()
                        WizardViewStepModel.nextStep()
                    }
                }



                MaterialButton {
                    id: showAdvancedButton

                    objectName: "showAdvancedButton"
                    tertiary: true

                    Layout.alignment: Qt.AlignCenter

                    preferredWidth: JamiTheme.wizardButtonWidth
                    text: JamiStrings.advancedFeatures
                    toolTipText: JamiStrings.showAdvancedFeatures

                }

                AccountCreationStepIndicator {
                    Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                    Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
                    Layout.alignment: Qt.AlignHCenter

                    spacing: JamiTheme.wizardViewPageLayoutSpacing
                    steps: 2
                    currentStep: 1
                }
            }
        }

        Rectangle {
            id: passwordSetupPage

            objectName: "passwordSetupPage"

            property int stackIndex: 1

            focus: visible

            color: JamiTheme.backgroundColor

            KeyNavigation.tab: passwordSwitch
            KeyNavigation.up: passwordSwitch
            KeyNavigation.down: passwordSwitch

            ColumnLayout {
                id: passwordColumnLayout

                spacing: JamiTheme.wizardViewPageLayoutSpacing

                anchors.centerIn: parent
                width: root.width

                RowLayout {
                    spacing: JamiTheme.wizardViewPageLayoutSpacing

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                    Layout.preferredWidth: usernameEdit.width

                    Label {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        text: JamiStrings.createPassword
                        color: JamiTheme.textColor
                        font.pointSize: JamiTheme.textFontSize + 3
                    }

                    JamiSwitch {
                        id: passwordSwitch

                        objectName: "passwordSwitch"

                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.leftMargin: -JamiTheme.wizardViewPageLayoutSpacing
                        Layout.topMargin: 5

                        KeyNavigation.tab: checked ? passwordEdit : createAccountButton
                        KeyNavigation.up: backButton
                        KeyNavigation.down: KeyNavigation.tab
                    }

                    BubbleLabel {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        text: JamiStrings.optional
                        bubbleColor: JamiTheme.wizardBlueButtons
                    }
                }

                MaterialLineEdit {
                    id: passwordEdit

                    objectName: "passwordEdit"

                    Layout.preferredHeight: fieldLayoutHeight
                    Layout.preferredWidth: createAccountButton.width
                    Layout.alignment: Qt.AlignHCenter

                    focus: visible
                    visible: passwordSwitch.checked

                    selectByMouse: true
                    echoMode: TextInput.Password
                    placeholderText: JamiStrings.password
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true

                    KeyNavigation.tab: passwordConfirmEdit
                    KeyNavigation.up: passwordSwitch
                    KeyNavigation.down: KeyNavigation.tab

                    onAccepted: passwordConfirmEdit.forceActiveFocus()
                }

                MaterialLineEdit {
                    id: passwordConfirmEdit

                    objectName: "passwordConfirmEdit"

                    Layout.preferredHeight: fieldLayoutHeight
                    Layout.preferredWidth: createAccountButton.width
                    Layout.alignment: Qt.AlignHCenter

                    visible: passwordSwitch.checked

                    selectByMouse: true
                    echoMode: TextInput.Password
                    placeholderText: JamiStrings.confirmPassword
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true

                    KeyNavigation.tab: createAccountButton.enabled ? createAccountButton :
                                                                     backButton
                    KeyNavigation.up: passwordEdit
                    KeyNavigation.down: KeyNavigation.tab

                    onAccepted: {
                        if (createAccountButton.enabled)
                            createAccountButton.clicked()
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: createAccountButton.width - 10
                    Layout.leftMargin: (root.width - createAccountButton.width) / 2

                    text: JamiStrings.notePasswordRecovery
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                    font.pointSize: JamiTheme.textFontSize
                }

                MaterialButton {
                    id: createAccountButton

                    objectName: "createAccountButton"

                    Layout.alignment: Qt.AlignCenter

                    preferredWidth: JamiTheme.wizardButtonWidth

                    function checkEnable() {
                        return !passwordSwitch.checked ||
                                (passwordEdit.text === passwordConfirmEdit.text
                                 && passwordEdit.text.length !== 0)
                    }

                    font.capitalization: Font.AllUppercase
                    text: isRendezVous ? JamiStrings.createRV : JamiStrings.createAccount
                    enabled: checkEnable()
                    color: checkEnable() ? JamiTheme.wizardBlueButtons :
                                           JamiTheme.buttonTintedGreyInactive
                    hoveredColor: JamiTheme.buttonTintedBlueHovered
                    pressedColor: JamiTheme.buttonTintedBluePressed

                    KeyNavigation.tab: backButton
                    KeyNavigation.up: passwordSwitch.checked ? passwordConfirmEdit : passwordSwitch
                    KeyNavigation.down: KeyNavigation.tab

                    onClicked: {
                        WizardViewStepModel.accountCreationInfo =
                                JamiQmlUtils.setUpAccountCreationInputPara(
                                    {isRendezVous : WizardViewStepModel.accountCreationOption ===
                                                    WizardViewStepModel.AccountCreationOption.CreateRendezVous,
                                        password : passwordEdit.text,
                                        registeredName : usernameEdit.text})
                        WizardViewStepModel.nextStep()
                    }
                }

                AccountCreationStepIndicator {
                    Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                    Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
                    Layout.alignment: Qt.AlignHCenter

                    spacing: JamiTheme.wizardViewPageLayoutSpacing
                    steps: 2
                    currentStep: 2
                }
            }
        }
    }

}
