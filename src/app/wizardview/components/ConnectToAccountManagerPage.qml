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
    property string errorText: ""
    property int preferredHeight: connectToAccountManagerPageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    color: JamiTheme.secondaryBackgroundColor

    function clearAllTextFields() {
        connectBtn.spinnerTriggered = false;
        errorText = "";
    }
    function errorOccured(errorMessage) {
        connectBtn.spinnerTriggered = false;
        errorText = errorMessage;
    }
    signal showThisPage

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ConnectToAccountManager) {
                clearAllTextFields();
                root.showThisPage();
            }
        }
    }
    ColumnLayout {
        id: connectToAccountManagerPageColumnLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: JamiTheme.wizardViewPageLayoutSpacing
        width: Math.max(508, root.width - 100)

        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.preferredMarginSize
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.connectJAMSServer
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(400, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.enterJAMSURL
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        ModalTextEdit {
            id: accountManagerEdit
            KeyNavigation.down: usernameManagerEdit
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: backButton
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewMarginSize
            focus: visible
            objectName: "accountManagerEdit"
            placeholderText: JamiStrings.jamiManagementServerURL

            onAccepted: usernameManagerEdit.forceActiveFocus()
        }
        Label {
            id: credentialsLabel
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.jamsCredentials
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        ModalTextEdit {
            id: usernameManagerEdit
            KeyNavigation.down: passwordManagerEdit
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: accountManagerEdit
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewMarginSize
            objectName: "usernameManagerEdit"
            placeholderText: JamiStrings.username

            onAccepted: passwordManagerEdit.forceActiveFocus()
        }
        PasswordTextEdit {
            id: passwordManagerEdit
            KeyNavigation.down: connectBtn.enabled ? connectBtn : backButton
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: usernameManagerEdit
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewMarginSize
            objectName: "passwordManagerEdit"
            placeholderText: JamiStrings.password

            onAccepted: connectBtn.forceActiveFocus()
        }
        SpinnerButton {
            id: connectBtn
            KeyNavigation.down: backButton
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: passwordManagerEdit
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            enabled: accountManagerEdit.dynamicText.length !== 0 && usernameManagerEdit.dynamicText.length !== 0 && passwordManagerEdit.dynamicText.length !== 0 && !spinnerTriggered
            normalText: JamiStrings.connect
            objectName: "connectToAccountManagerPageConnectBtn"
            preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
            primary: true
            spinnerTriggeredtext: JamiStrings.creatingAccount

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

            TextMetrics {
                id: textSize
                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                font.weight: Font.Bold
                text: connectBtn.normalText
            }
        }
        Label {
            id: errorLabel
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
            color: JamiTheme.redColor
            font.pixelSize: JamiTheme.textEditError
            text: errorText
            visible: errorText.length !== 0
        }
    }
    BackButton {
        id: backButton
        KeyNavigation.down: accountManagerEdit
        KeyNavigation.tab: KeyNavigation.down
        KeyNavigation.up: {
            if (connectBtn.enabled)
                return connectBtn;
            return passwordManagerEdit;
        }
        anchors.left: parent.left
        anchors.margins: 20
        anchors.top: parent.top
        objectName: "connectToAccountManagerPageBackButton"
        preferredSize: JamiTheme.wizardViewPageBackButtonSize
        visible: !connectBtn.spinnerTriggered

        onClicked: WizardViewStepModel.previousStep()
    }
}
