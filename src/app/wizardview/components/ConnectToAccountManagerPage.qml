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
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int preferredHeight: connectToAccountManagerPageColumnLayout.implicitHeight
    property string errorText: ""

    signal showThisPage

    function clearAllTextFields() {
        connectBtn.spinnerTriggered = false
        usernameManagerEdit.clear()
        passwordManagerEdit.clear()
        accountManagerEdit.clear()
        errorText = ""
    }

    function errorOccured(errorMessage) {
        connectBtn.spinnerTriggered = false
        errorText = errorMessage
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation &&
                    WizardViewStepModel.accountCreationOption ===
                    WizardViewStepModel.AccountCreationOption.ConnectToAccountManager) {
                clearAllTextFields()
                root.showThisPage()
            }
        }
    }

    color: JamiTheme.backgroundColor

    ColumnLayout {
        id: connectToAccountManagerPageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: parent.top
        anchors.topMargin: 38

        Text {

            text: JamiStrings.connectJAMSServer
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            font.pixelSize: 26

        }

        Text {

            text: JamiStrings.jamsDecription
            font.weight: Font.Medium
            Layout.preferredWidth: 360
            Layout.topMargin: 15
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            font.pixelSize: 15
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MaterialLineEdit {
            id: accountManagerEdit

            objectName: "accountManagerEdit"

            Layout.preferredHeight: fieldLayoutHeight
            Layout.preferredWidth: connectBtn.width
            Layout.alignment: Qt.AlignCenter

            focus: visible

            selectByMouse: true
            placeholderText: JamiStrings.jamiManagementServerURL
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            KeyNavigation.tab: usernameManagerEdit
            KeyNavigation.up: {
                if (backButton.visible)
                    return backButton
                else if (connectBtn.enabled)
                    return connectBtn
                return passwordManagerEdit
            }
            KeyNavigation.down: KeyNavigation.tab

            onTextChanged: errorText = ""
            onAccepted: usernameManagerEdit.forceActiveFocus()
        }

        Label {
            id: referencesLabel

            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: connectBtn.width
            Layout.topMargin: 10
            font.weight: Font.Medium

            text: JamiStrings.jamsReferences
            color: JamiTheme.textColor
            wrapMode: Text.Wrap

            onTextChanged: Layout.preferredHeight =
                           JamiQmlUtils.getTextBoundingRect(
                               referencesLabel.font, referencesLabel.text).height
        }

        UsernameLineEdit {

            id: usernameManagerEdit

            objectName: "usernameManagerEdit"

            Layout.preferredHeight: fieldLayoutHeight
            Layout.preferredWidth: connectBtn.width
            Layout.alignment: Qt.AlignCenter

            selectByMouse: true
            placeholderText: JamiStrings.username
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            KeyNavigation.tab: passwordManagerEdit
            KeyNavigation.up: accountManagerEdit
            KeyNavigation.down: KeyNavigation.tab

            onTextChanged: errorText = ""
            //onAccepted: passwordManagerEdit.forceActiveFocus()


        }

        //        MaterialLineEdit {
        //            id: usernameManagerEdit

        //            objectName: "usernameManagerEdit"

        //            Layout.preferredHeight: fieldLayoutHeight
        //            Layout.preferredWidth: connectBtn.width
        //            Layout.alignment: Qt.AlignCenter

        //            selectByMouse: true
        //            placeholderText: JamiStrings.username
        //            font.pointSize: JamiTheme.textFontSize
        //            font.kerning: true

        //            KeyNavigation.tab: passwordManagerEdit
        //            KeyNavigation.up: accountManagerEdit
        //            KeyNavigation.down: KeyNavigation.tab

        //            onTextChanged: errorText = ""
        //            onAccepted: passwordManagerEdit.forceActiveFocus()
        //        }

        PasswordLineEdit {

            id: passwordManagerEdit

            objectName: "passwordManagerEdit"

            Layout.preferredHeight: fieldLayoutHeight
            Layout.preferredWidth: connectBtn.width
            Layout.alignment: Qt.AlignCenter

            selectByMouse: true
            placeholderText: JamiStrings.password
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            echoMode: TextInput.Password

            KeyNavigation.tab: {
                if (connectBtn.enabled)
                    return connectBtn
                else if (backButton.visible)
                    return backButton
                return accountManagerEdit
            }
            KeyNavigation.up: usernameManagerEdit
            KeyNavigation.down: KeyNavigation.tab

            onTextChanged: errorText = ""
            //            onAccepted: {
            //                if (connectBtn.enabled)
            //                    connectBtn.clicked()
            //            }
        }

        //        MaterialLineEdit {
        //            id: passwordManagerEdit

        //            objectName: "passwordManagerEdit"

        //            Layout.preferredHeight: fieldLayoutHeight
        //            Layout.preferredWidth: connectBtn.width
        //            Layout.alignment: Qt.AlignCenter

        //            selectByMouse: true
        //            placeholderText: JamiStrings.password
        //            font.pointSize: JamiTheme.textFontSize
        //            font.kerning: true

        //            echoMode: TextInput.Password

        //            KeyNavigation.tab: {
        //                if (connectBtn.enabled)
        //                    return connectBtn
        //                else if (backButton.visible)
        //                    return backButton
        //                return accountManagerEdit
        //            }
        //            KeyNavigation.up: usernameManagerEdit
        //            KeyNavigation.down: KeyNavigation.tab

        //            onTextChanged: errorText = ""
        //            onAccepted: {
        //                if (connectBtn.enabled)
        //                    connectBtn.clicked()
        //            }
        //        }




        SpinnerButton {
            id: connectBtn

            objectName: "connectToAccountManagerPageConnectBtn"

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins

            preferredWidth: JamiTheme.wizardButtonWidth

            spinnerTriggeredtext: JamiStrings.creatingAccount
            normalText: JamiStrings.connect

            enabled: accountManagerEdit.text.length !== 0
                     && usernameManagerEdit.text.length !== 0
                     && passwordManagerEdit.text.length !== 0
                     && !spinnerTriggered

            color: JamiTheme.tintedBlue

            KeyNavigation.tab: {
                if (backButton.visible)
                    return backButton
                return accountManagerEdit
            }
            KeyNavigation.up: passwordManagerEdit
            KeyNavigation.down: KeyNavigation.tab

            onClicked: {
                if (connectBtn.focus)
                    accountManagerEdit.forceActiveFocus()
                spinnerTriggered = true

                WizardViewStepModel.accountCreationInfo =
                        JamiQmlUtils.setUpAccountCreationInputPara(
                            {username : usernameManagerEdit.text,
                                password : passwordManagerEdit.text,
                                manager : accountManagerEdit.text})
                WizardViewStepModel.nextStep()
            }
        }

        Label {
            id: errorLabel

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

            visible: errorText.length !== 0
            text: errorText

            font.pointSize: JamiTheme.textFontSize
            color: JamiTheme.redColor
        }
    }

    BackButton {
        id: backButton

        objectName: "connectToAccountManagerPageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20

        visible: !connectBtn.spinnerTriggered

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        KeyNavigation.tab: accountManagerEdit
        KeyNavigation.up: {
            if (connectBtn.enabled)
                return connectBtn
            return passwordManagerEdit
        }
        KeyNavigation.down: KeyNavigation.tab

        onClicked: WizardViewStepModel.previousStep()
    }
}
