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

    property string errorText: ""
    property int preferredHeight: importFromDevicePageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    signal showThisPage

    function initializeOnShowUp() {
        clearAllTextFields();
    }

    function clearAllTextFields() {
        passwordFromDevice.text = ""
        errorText = ""
    }

    function errorOccurred(errorMessage) {
        errorText = errorMessage
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.DeviceLinking) {
                clearAllTextFields();
                root.showThisPage();
            }
        }

        function onDeviceLinkStateChanged() {
            // Handle state changes
            switch(WizardViewStepModel.deviceLinkState) {
                case WizardViewStepModel.DeviceLinkState.TokenAvailable:
                    pinDisplay.text = WizardViewStepModel.deviceLinkDetails["token"]
                    break
                case WizardViewStepModel.DeviceLinkState.Authenticating:
                    if (WizardViewStepModel.deviceLinkDetails["auth_error"] === "bad_password") {
                        errorOccurred(JamiStrings.invalidPassword)
                    }
                    break
                case WizardViewStepModel.DeviceLinkState.Done:
                    if (WizardViewStepModel.deviceLinkDetails["error"]) {
                        errorOccurred(JamiStrings.errorCreateAccount)
                    }
                    break
            }
        }
    }

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: importFromDevicePageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        width: Math.max(508, root.width - 100)

        Text {

            text: JamiStrings.importAccountFromAnotherDevice
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

            text: JamiStrings.importFromDeviceDescription
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            font.weight: Font.Medium
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        // Show PIN/token when available
        Rectangle {
            id: pinDisplay
            visible: WizardViewStepModel.deviceLinkState === WizardViewStepModel.DeviceLinkState.TokenAvailable

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(410, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

            height: 40
            color: JamiTheme.backgroundColor
            border.color: JamiTheme.greyBorderColor
            radius: 5

            Text {
                anchors.centerIn: parent
                text: ""  // Will be set when token is available
                font.pixelSize: JamiTheme.textFontSize
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Password input - only show during authentication
        PasswordTextEdit {
            id: passwordFromDevice
            visible: WizardViewStepModel.deviceLinkState === WizardViewStepModel.DeviceLinkState.Authenticating

            objectName: "passwordFromDevice"
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(410, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewMarginSize

            placeholderText: JamiStrings.enterPassword

            onAccepted: {
                if (text.length > 0) {
                    AccountAdapter.provideDevicePassword(text)
                }
            }
        }

        // Progress indicator
        BusyIndicator {
            visible: WizardViewStepModel.deviceLinkState === WizardViewStepModel.DeviceLinkState.Connecting ||
                    WizardViewStepModel.deviceLinkState === WizardViewStepModel.DeviceLinkState.InProgress

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

            running: visible
        }

        // Status text
        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewMarginSize

            text: {
                switch(WizardViewStepModel.deviceLinkState) {
                    case WizardViewStepModel.DeviceLinkState.Connecting:
                        return JamiStrings.connecting
                    case WizardViewStepModel.DeviceLinkState.InProgress:
                        return JamiStrings.transferringAccount
                    default:
                        return ""
                }
            }
            visible: text !== ""
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.textFontSize
        }

        // Error label
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

    // Back button
    BackButton {
        id: backButton
        objectName: "importFromDevicePageBackButton"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        visible: WizardViewStepModel.deviceLinkState !== WizardViewStepModel.DeviceLinkState.InProgress

        onClicked: {
            if (WizardViewStepModel.deviceLinkState !== WizardViewStepModel.DeviceLinkState.Init) {
                AccountAdapter.cancelDeviceLinking()
            }
            WizardViewStepModel.previousStep()
        }
    }
}
