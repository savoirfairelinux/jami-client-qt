/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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

    property int preferredHeight: connectToAccountManagerPageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize
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

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: connectToAccountManagerPageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: JamiTheme.wizardViewLayoutTopMargin

        width: Math.max(508, root.width - 100)

        Text {

            text: JamiStrings.connectJAMSServer
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 15
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            wrapMode : Text.WordWrap

        }

        Text {

            text: JamiStrings.enterJAMSURL
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 30
            font.weight: Font.Medium

            Layout.preferredWidth: Math.min(400, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            wrapMode : Text.WordWrap
        }

        EditableLineEdit {
            id: accountManagerEdit

            objectName: "accountManagerEdit"

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            fontSize: 15
            Layout.topMargin: 5

            secondIco: JamiResources.outline_info_24dp_svg

            selectByMouse: true
            placeholderText: JamiStrings.jamiManagementServerURL
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            KeyNavigation.tab: usernameManagerEdit
            KeyNavigation.up: backButton
            KeyNavigation.down: usernameManagerEdit

            onTextChanged: errorText = ""
            onAccepted: usernameManagerEdit.forceActiveFocus()
        }

        Label {
            id: credentialsLabel

            text: JamiStrings.jamsCredentials

            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: 35
            font.weight: Font.Medium
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize

            color: JamiTheme.textColor
            wrapMode: Text.Wrap

            onTextChanged: Layout.preferredHeight =
                           JamiQmlUtils.getTextBoundingRect(
                               credentialsLabel.font, credentialsLabel.text).height
        }

        EditableLineEdit {

            id: usernameManagerEdit

            objectName: "usernameManagerEdit"

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            fontSize: 15

            secondIco: JamiResources.outline_info_24dp_svg

            selectByMouse: true
            placeholderText: JamiStrings.username
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            KeyNavigation.tab: passwordManagerEdit
            KeyNavigation.up: accountManagerEdit
            KeyNavigation.down: passwordManagerEdit

            onTextChanged: errorText = ""
            onAccepted: passwordManagerEdit.forceActiveFocus()


        }

        EditableLineEdit {

            id: passwordManagerEdit

            objectName: "passwordManagerEdit"

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            selectByMouse: true
            placeholderText: JamiStrings.password
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true
            Layout.topMargin: 10

            secondIco: JamiResources.eye_cross_svg
            thirdIco: JamiResources.outline_info_24dp_svg

            fontSize: 15

            echoMode: TextInput.Password

            KeyNavigation.tab: connectBtn.enabled ? connectBtn : backButton
            KeyNavigation.up: usernameManagerEdit
            KeyNavigation.down: connectBtn.enabled ? connectBtn : backButton

            onTextChanged: errorText = ""
            onAccepted: connectBtn.forceActiveFocus()

            onSecondIcoClicked: { toggleEchoMode() }

        }

        SpinnerButton {
            id: connectBtn

            objectName: "connectToAccountManagerPageConnectBtn"

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 40
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins

            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

            spinnerTriggeredtext: JamiStrings.creatingAccount
            normalText: JamiStrings.connect

            enabled: accountManagerEdit.text.length !== 0
                     && usernameManagerEdit.text.length !== 0
                     && passwordManagerEdit.text.length !== 0
                     && !spinnerTriggered

            color: JamiTheme.tintedBlue

            KeyNavigation.tab: backButton
            KeyNavigation.up: passwordManagerEdit
            KeyNavigation.down: backButton

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
