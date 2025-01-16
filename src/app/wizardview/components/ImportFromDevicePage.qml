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

Rectangle {
    id: root

    property string errorText: ""
    property int preferredHeight: importFromDevicePageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    // The token is used to generate the QR code and is also provided to the user as a backup if the QR
    // code cannot be scanned. It is a URI using the scheme "jami-auth".
    readonly property string tokenUri: WizardViewStepModel.deviceLinkDetails["token"] || ""

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
                // Check for authentication errors
                const authError = WizardViewStepModel.deviceLinkDetails["auth_error"];
                if (authError === "invalid_credentials") {
                    errorOccurred(JamiStrings.invalidPassword);
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
            text: {
                switch (WizardViewStepModel.deviceAuthState) {
                case WizardViewStepModel.DeviceAuthState.Init:
                    return JamiStrings.waitingForDevice;
                case WizardViewStepModel.DeviceAuthState.TokenAvailable:
                    return JamiStrings.scanToImportAccount;
                case WizardViewStepModel.DeviceAuthState.Connecting:
                    return JamiStrings.connectingToDevice;
                case WizardViewStepModel.DeviceAuthState.Authenticating:
                    return JamiStrings.authenticatingDevice;
                case WizardViewStepModel.DeviceAuthState.InProgress:
                    return JamiStrings.transferringAccount;
                default:
                    return "";
                }
            }
            wrapMode: Text.Wrap
            color: JamiTheme.textColor
        }

        // Show busy indicator when waiting for token
        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            visible: WizardViewStepModel.deviceAuthState === WizardViewStepModel.DeviceAuthState.Init
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
                text: JamiStrings.cantScanQRCode
                color: JamiTheme.textColor
            }

            TextArea {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.parent.width - 40
                text: tokenUri
                horizontalAlignment: Text.AlignHCenter
                readOnly: true
                wrapMode: Text.Wrap
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
            color: JamiTheme.redColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    // Back button
    BackButton {
        id: backButton
        objectName: "importFromDevicePageBackButton"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        visible: WizardViewStepModel.deviceAuthState !== WizardViewStepModel.DeviceAuthState.InProgress

        onClicked: {
            if (WizardViewStepModel.deviceAuthState !== WizardViewStepModel.DeviceAuthState.Init) {
                AccountAdapter.cancelImportAccount();
            }
            WizardViewStepModel.previousStep();
        }
    }
}
