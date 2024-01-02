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
        connectBtn.spinnerTriggered = false;
        errorText = "";
    }

    function errorOccurred(errorMessage) {
        connectBtn.spinnerTriggered = false;
        errorText = errorMessage;
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ConnectToAccountManager) {
                clearAllTextFields();
                root.showThisPage();
            }
        }
    }

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: connectToAccountManagerPageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(508, root.width - 100)

        Text {

            text: JamiStrings.connectJAMSServer
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            wrapMode: Text.WordWrap
        }

        Text {

            text: JamiStrings.enterJAMSURL
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            font.weight: Font.Medium

            Layout.preferredWidth: Math.min(400, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            wrapMode: Text.WordWrap
        }

        ModalTextEdit {
            id: accountManagerEdit

            objectName: "accountManagerEdit"

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            Layout.topMargin: JamiTheme.wizardViewMarginSize
            focus: visible

            placeholderText: JamiStrings.jamiManagementServerURL

            KeyNavigation.up: backButton
            KeyNavigation.down: usernameManagerEdit
            KeyNavigation.tab: KeyNavigation.down

            onAccepted: usernameManagerEdit.forceActiveFocus()
        }

        Label {
            id: credentialsLabel

            text: JamiStrings.jamsCredentials

            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            font.weight: Font.Medium
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize

            color: JamiTheme.textColor
            wrapMode: Text.Wrap
        }

        ModalTextEdit {
            id: usernameManagerEdit

            objectName: "usernameManagerEdit"

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewMarginSize
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            placeholderText: JamiStrings.username

            KeyNavigation.up: accountManagerEdit
            KeyNavigation.down: passwordManagerEdit
            KeyNavigation.tab: KeyNavigation.down

            onAccepted: passwordManagerEdit.forceActiveFocus()
        }

        PasswordTextEdit {
            id: passwordManagerEdit

            objectName: "passwordManagerEdit"

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewMarginSize

            placeholderText: JamiStrings.password

            KeyNavigation.up: usernameManagerEdit
            KeyNavigation.down: connectBtn.enabled ? connectBtn : backButton
            KeyNavigation.tab: KeyNavigation.down

            onAccepted: connectBtn.forceActiveFocus()
        }

        SpinnerButton {
            id: connectBtn

            TextMetrics {
                id: textSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                text: connectBtn.normalText
            }

            objectName: "connectToAccountManagerPageConnectBtn"

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins

            preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding

            spinnerTriggeredtext: JamiStrings.creatingAccount
            normalText: JamiStrings.connect

            enabled: accountManagerEdit.dynamicText.length !== 0 && usernameManagerEdit.dynamicText.length !== 0 && passwordManagerEdit.dynamicText.length !== 0 && !spinnerTriggered

            primary: true

            KeyNavigation.up: passwordManagerEdit
            KeyNavigation.down: backButton
            KeyNavigation.tab: KeyNavigation.down

            onClicked: {
                if (connectBtn.focus)
                    accountManagerEdit.forceActiveFocus();
                spinnerTriggered = true;
                WizardViewStepModel.accountCreationInfo = JamiQmlUtils.setUpAccountCreationInputPara({
                        "username": usernameManagerEdit.dynamicText,
                        "password": passwordManagerEdit.dynamicText,
                        "manager": accountManagerEdit.dynamicText
                    });
                WizardViewStepModel.nextStep();
            }
        }

        Label {
            id: errorLabel

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

            visible: errorText.length !== 0
            text: errorText

            font.pixelSize: JamiTheme.textEditError
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

        KeyNavigation.up: {
            if (connectBtn.enabled)
                return connectBtn;
            return passwordManagerEdit;
        }
        KeyNavigation.down: accountManagerEdit
        KeyNavigation.tab: KeyNavigation.down

        onClicked: WizardViewStepModel.previousStep()
    }
}
