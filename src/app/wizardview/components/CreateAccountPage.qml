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
import Qt5Compat.GraphicalEffects

import "../"
import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root

    property bool isRendezVous: false
    property bool helpOpened: false

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
                createAccountStack.currentIndex = advancedAccountSettingsPage.stackIndex
            }
        }
    }

    //    MouseArea {

    //        anchors.fill: parent

    //        onClicked: {

    //            helpOpened  = false
    //            goodToKnow.visible = false
    //            console.warn(root.width)

    //        }
    //    }

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

            color: JamiTheme.backgroundColor

            ColumnLayout {
                id: usernameColumnLayout

                spacing: JamiTheme.wizardViewPageLayoutSpacing

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: JamiTheme.wizardViewLayoutTopMargin

                width: Math.max(508, root.width - 100)

                Text {
                    id: joinJami

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 50
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
                    Layout.topMargin: 16
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)

                    wrapMode:Text.WordWrap
                    text: isRendezVous ? JamiStrings.chooseUsernameForRV :
                                         JamiStrings.chooseUsernameForAccount
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize + 3
                }

                UsernameLineEdit {
                    id: usernameEdit

                    objectName: "usernameEdit"

                    Layout.topMargin: 15
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                    focus: visible
                    fontSize: 18

                    KeyNavigation.tab: chooseUsernameButton

                    KeyNavigation.up: backButton
                    KeyNavigation.down: KeyNavigation.tab

                    onAccepted: {
                        if (chooseUsernameButton.enabled)
                            chooseUsernameButton.clicked()
                        else
                            skipButton.clicked()
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter

                    visible: text.length !==0 || usernameEdit.selected

                    text: {
                        switch(usernameEdit.nameRegistrationState){
                        case UsernameLineEdit.NameRegistrationState.BLANK:
                            return " "
                        case UsernameLineEdit.NameRegistrationState.SEARCHING:
                            return " "
                        case UsernameLineEdit.NameRegistrationState.FREE:
                            return " "
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

                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

                    font.capitalization: Font.AllUppercase
                    text: isRendezVous ? JamiStrings.chooseName : JamiStrings.joinJami
                    enabled: usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.FREE || usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.BLANK


                    //KeyNavigation.tab:
                    KeyNavigation.up: usernameEdit
                    KeyNavigation.down: KeyNavigation.tab

                    onClicked: {

                        if(usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.FREE)
                            WizardViewStepModel.nextStep()

                        if(usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.BLANK)
                            popup.visible = true

                    }
                }

                MaterialButton {
                    id: showAdvancedButton

                    objectName: "showAdvancedButton"
                    tertiary: true

                    Layout.alignment: Qt.AlignCenter
                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

                    text: JamiStrings.advancedAccountSettings
                    toolTipText: JamiStrings.showAdvancedFeatures

                    onClicked: {
                        WizardViewStepModel.nextStep()
                    }
                }

                NoUsernamePopup {

                    id: popup
                    visible: false

                }
            }
        }

        AdvancedAccountSettings {

            id: advancedAccountSettingsPage
            objectName: "advancedAccountSettingsPage"
            property int stackIndex: 1

        }

        Rectangle {
            id: passwordSetupPage

            objectName: "passwordSetupPage"

            property int stackIndex: 2

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
                    text: isRendezVous ? JamiStrings.createNewRV : JamiStrings.createAccount
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
            }
        }
    }

    BackButton {
        id: backButton

        objectName: "createAccountPageBackButton"

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        KeyNavigation.tab: {
            if (createAccountStack.currentIndex === nameRegistrationPage.stackIndex)
                return usernameEdit
            else
                return passwordSwitch
        }
        KeyNavigation.up: createAccountButton.enabled ? createAccountButton : passwordConfirmEdit

        KeyNavigation.down: KeyNavigation.tab

        onClicked: {
            WizardViewStepModel.previousStep()
            goodToKnow.visible = false
            helpOpened = false
        }
    }

    PushButton {

        id: infoBox
        z:1

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        normalColor: JamiTheme.backgroundColor
        imageColor: JamiTheme.primaryForegroundColor

        source: JamiResources.outline_info_24dp_svg

        onHoveredChanged: {

            goodToKnow.visible = !goodToKnow.visible
            helpOpened = !helpOpened

            advancedAccountSettingsPage.openedPassword = false
            advancedAccountSettingsPage.openedNickname = false

        }
    }

    Item {
        id: goodToKnow
        anchors.top: parent.top
        anchors.right: parent.right

        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins + infoBox.preferredSize*2/5

        height: helpOpened ? 270 : 0
        width: helpOpened ? 452 : 0

        visible: false

        Behavior on width {
            NumberAnimation { duration: JamiTheme.shortFadeDuration }
        }

        Behavior on height {
            NumberAnimation { duration: JamiTheme.shortFadeDuration}
        }

        DropShadow {
            z: -1
            anchors.fill: boxInfo
            horizontalOffset: 3.0
            verticalOffset: 3.0
            radius: boxInfo.radius * 4
            color: JamiTheme.shadowColor
            source: boxInfo
            transparentBorder: true
        }

        Rectangle {

            id: boxInfo

            z: 0
            anchors.fill: parent
            radius: 30

            ColumnLayout {

                id: infoContainer

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.top: parent.top
                visible: helpOpened ? 1 : 0

                Behavior on visible {
                    NumberAnimation {
                        from: 0
                        duration: JamiTheme.overlayFadeDuration
                    }
                }


                Text {

                    text: JamiStrings.goodToKnow
                    color: JamiTheme.textColor

                    Layout.topMargin: 15
                    Layout.alignment: Qt.AlignCenter | Qt.AlignTop

                    font.pixelSize: 15
                    font.kerning: true
                }

                Grid {
                    columns: 2
                    spacing: 25
                    Layout.alignment: Qt.AlignTop

                    InfoBox {
                        icoSource: JamiResources.laptop_black_24dp_svg
                        title: JamiStrings.local
                        description: JamiStrings.localAccount
                    }

                    InfoBox {
                        icoSource: JamiResources.person_24dp_svg
                        title: JamiStrings.username
                        description: JamiStrings.usernameRecommened
                    }

                    InfoBox {
                        icoSource: JamiResources.lock_svg
                        title: JamiStrings.encrypt
                        description: JamiStrings.passwordOptional
                    }

                    InfoBox {
                        icoSource: JamiResources.noun_paint_svg
                        title: JamiStrings.customize
                        description: JamiStrings.customizeOptional
                    }
                }
            }
        }
    }
}
