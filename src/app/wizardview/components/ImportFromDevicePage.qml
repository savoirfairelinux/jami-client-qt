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
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../mainview/components"

Rectangle {
    id: root

    property string errorText: ""
    property int preferredHeight: importFromDevicePageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    // The token is used to generate the QR code and is also provided to the user as a backup if the QR
    // code cannot be scanned. It is a URI using the scheme "jami-auth".
    readonly property string tokenUri: WizardViewStepModel.deviceLinkDetails["token"] || ""

    // Add after the error property
    property string peerDisplayName: ""
    property string peerId: ""

    signal showThisPage

    function clearAllTextFields() {
        errorText = "";
    }

    function errorOccurred(errorMessage) {
        errorText = errorMessage;
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.DeviceAuthorization) {
                clearAllTextFields();
                root.showThisPage();
            }
        }

        function onDeviceAuthStateChanged() {
            switch (WizardViewStepModel.deviceAuthState) {
            case WizardViewStepModel.DeviceAuthState.TokenAvailable:
                // Token is available and displayed as QR code
                clearAllTextFields();
                break;
            case WizardViewStepModel.DeviceAuthState.Connecting:
                // P2P connection being established
                clearAllTextFields();
                break;
            case WizardViewStepModel.DeviceAuthState.Authenticating:
                peerId = WizardViewStepModel.deviceLinkDetails["peer_id"] || "";
                // Try to get display name for the peer ID
                if (peerId) {
                    // Maybe start a lookup here
                    peerDisplayName = peerId;
                }
                break;
            case WizardViewStepModel.DeviceAuthState.InProgress:
                // Account archive is being transferred
                clearAllTextFields();
                break;
            case WizardViewStepModel.DeviceAuthState.Done:
                // Final state - check for specific errors
                const error = WizardViewStepModel.deviceLinkDetails["error"];
                if (error) {
                    switch (error) {
                    case "network":
                        errorOccurred(JamiStrings.linkDeviceNetWorkError);
                        break;
                    case "timeout":
                        errorOccurred(JamiStrings.timeoutError);
                        break;
                    case "auth_error":
                        errorOccurred(JamiStrings.invalidPassword);
                        break;
                    case "canceled":
                        errorOccurred(JamiStrings.operationCanceled);
                        break;
                    default:
                        errorOccurred(JamiStrings.errorCreateAccount);
                        break;
                    }
                } else {
                    // Success - account imported
                    WizardViewStepModel.nextStep();
                }
                break;
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
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: JamiTheme.headerFontSize
            text: {
                switch (WizardViewStepModel.deviceAuthState) {
                case WizardViewStepModel.DeviceAuthState.Init:
                    return JamiStrings.waitingForToken;
                case WizardViewStepModel.DeviceAuthState.TokenAvailable:
                    return JamiStrings.scanToImportAccount;
                case WizardViewStepModel.DeviceAuthState.Connecting:
                    return JamiStrings.connectingToDevice;
                case WizardViewStepModel.DeviceAuthState.Authenticating:
                    return JamiStrings.confirmAccountImport;
                case WizardViewStepModel.DeviceAuthState.InProgress:
                    return JamiStrings.transferringAccount;
                default:
                    return "";
                }
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            color: JamiTheme.textColor
        }

        // Confirmation form
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: Math.min(parent.width - 40, 400)
            visible: WizardViewStepModel.deviceAuthState === WizardViewStepModel.DeviceAuthState.Authenticating
            spacing: 16

            Text {
                Layout.fillWidth: true
                font.pointSize: JamiTheme.textFontSize
                text: peerDisplayName !== peerId ? qsTr("Do you want to import the account with name '%1' and ID:\n%2").arg(peerDisplayName).arg(peerId) : qsTr("Do you want to import the account with ID:\n%1").arg(peerId)
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
                color: JamiTheme.textColor
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                font.pointSize: JamiTheme.mediumFontSize
                visible: WizardViewStepModel.deviceLinkDetails["auth_scheme"] === "password"
                placeholderText: JamiStrings.enterPassword
                echoMode: TextInput.Password

                onAccepted: confirmButton.clicked()
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                MaterialButton {
                    id: confirmButton
                    text: JamiStrings.optionConfirm
                    primary: true
                    onClicked: {
                        if (passwordField.visible && !passwordField.text) {
                            errorOccurred(JamiStrings.passwordRequired);
                            return;
                        }
                        AccountAdapter.provideAccountAuthentication(passwordField.visible ? passwordField.text : "");
                    }
                }
            }
        }

        // Show busy indicator when waiting for token
        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            visible: WizardViewStepModel.deviceAuthState === WizardViewStepModel.DeviceAuthState.Init
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            running: visible
        }

        // QR Code container with frame
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: qrLoader.Layout.preferredWidth + 40
            Layout.preferredHeight: qrLoader.Layout.preferredHeight + 40
            visible: WizardViewStepModel.deviceAuthState === WizardViewStepModel.DeviceAuthState.TokenAvailable
            color: JamiTheme.primaryBackgroundColor
            radius: 8
            border.width: 1
            border.color: JamiTheme.tabbarBorderColor

            Loader {
                id: qrLoader
                anchors.centerIn: parent
                active: WizardViewStepModel.deviceAuthState === WizardViewStepModel.DeviceAuthState.TokenAvailable
                Layout.preferredWidth: Math.min(parent.parent.width - 60, 300)
                Layout.preferredHeight: Layout.preferredWidth

                sourceComponent: Image {
                    width: qrLoader.Layout.preferredWidth
                    height: qrLoader.Layout.preferredHeight
                    smooth: false
                    fillMode: Image.PreserveAspectFit
                    source: "image://qrImage/raw_" + tokenUri
                }
            }
        }

        // Token URI backup text
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: tokenUri !== ""
            spacing: 8

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                text: JamiStrings.cantScanQRCode
                font.pointSize: JamiTheme.mediumFontSize
                color: JamiTheme.textColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            TextArea {
                id: tokenUriTextArea
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.parent.width - 40
                text: tokenUri
                font.pointSize: JamiTheme.mediumFontSize
                horizontalAlignment: Text.AlignHCenter
                readOnly: true
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                selectByMouse: true
                background: Rectangle {
                    color: JamiTheme.primaryBackgroundColor
                    radius: 5
                    border.width: 1
                    border.color: JamiTheme.tabbarBorderColor
                }
            }
        }

        // Error text
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width - 40
            visible: errorText !== ""
            text: errorText
            font.pointSize: JamiTheme.mediumFontSize
            color: JamiTheme.redColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
    }

    // Back button
    JamiPushButton {
        id: backButton
        QWKSetParentHitTestVisible {
        }

        objectName: "importFromDevicePageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        preferredSize: 36
        imageContainerWidth: 20
        source: JamiResources.ic_arrow_back_24dp_svg

        visible: WizardViewStepModel.deviceAuthState !== WizardViewStepModel.DeviceAuthState.InProgress

        onClicked: {
            if (WizardViewStepModel.deviceAuthState !== WizardViewStepModel.DeviceAuthState.Init) {
                AccountAdapter.cancelImportAccount();
            }
            WizardViewStepModel.previousStep();
        }
    }

    // Debug controls - only visible in debug mode
    Rectangle {
        id: debugControls
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        width: debugColumn.implicitWidth + 32
        height: debugColumn.implicitHeight + 32
        color: JamiTheme.primaryBackgroundColor
        radius: 8
        border.width: 1
        border.color: JamiTheme.tabbarBorderColor

        ColumnLayout {
            id: debugColumn
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "Debug Controls"
                font.bold: true
                color: JamiTheme.textColor
            }

            ComboBox {
                id: stateCombo
                Layout.fillWidth: true
                model: ["Init", "TokenAvailable", "Connecting", "Authenticating", "InProgress", "Done"]
                onActivated: {
                    // Force the state
                    WizardViewStepModel.deviceAuthState = WizardViewStepModel.DeviceAuthState[currentText];

                    // Set appropriate device details for testing
                    var details = {};
                    switch (currentText) {
                    case "TokenAvailable":
                        details["token"] = "jami-auth://test-token-12345";
                        break;
                    case "Authenticating":
                        details["peer_id"] = "test-peer-id-12345";
                        details["auth_scheme"] = passwordCheck.checked ? "password" : "none";
                        break;
                    case "Done":
                        details["error"] = errorCombo.currentText === "Success" ? "" : errorCombo.currentText.toLowerCase();
                        break;
                    }
                    WizardViewStepModel.deviceLinkDetails = details;
                }
            }

            CheckBox {
                id: passwordCheck
                text: "Require Password"
                checked: false
                onCheckedChanged: {
                    if (stateCombo.currentText === "Authenticating") {
                        var details = WizardViewStepModel.deviceLinkDetails;
                        details["auth_scheme"] = checked ? "password" : "none";
                        WizardViewStepModel.deviceLinkDetails = details;
                    }
                }
            }

            ComboBox {
                id: errorCombo
                Layout.fillWidth: true
                model: ["Success", "Network", "Timeout", "Auth_Error", "Canceled"]
                enabled: stateCombo.currentText === "Done"
            }

            TextField {
                id: peerNameField
                Layout.fillWidth: true
                placeholderText: "Peer Display Name"
                onTextChanged: {
                    if (stateCombo.currentText === "Authenticating") {
                        peerDisplayName = text;
                    }
                }
            }
        }
    }
}
