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
        errorText = ""
    }

    function errorOccurred(errorMessage) {
        errorText = errorMessage
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
            switch(WizardViewStepModel.deviceAuthState) {
                case WizardViewStepModel.DeviceAuthState.TokenAvailable:
                    // Token is available and displayed as QR code
                    clearAllTextFields()
                    break
                case WizardViewStepModel.DeviceAuthState.Connecting:
                    // P2P connection being established
                    clearAllTextFields()
                    break
                case WizardViewStepModel.DeviceAuthState.Authenticating:
                    // Check for authentication errors
                    const authError = WizardViewStepModel.deviceLinkDetails["auth_error"]
                    if (authError === "invalid_credentials") {
                        errorOccurred(JamiStrings.invalidPassword)
                    }
                    break
                case WizardViewStepModel.DeviceAuthState.InProgress:
                    // Account archive is being transferred
                    clearAllTextFields()
                    break
                case WizardViewStepModel.DeviceAuthState.Done:
                    // Final state - check for specific errors
                    const error = WizardViewStepModel.deviceLinkDetails["error"]
                    if (error) {
                        switch(error) {
                            case "network":
                                errorOccurred(JamiStrings.networkError)
                                break
                            case "timeout":
                                errorOccurred(JamiStrings.timeoutError)
                                break
                            case "auth_error":
                                errorOccurred(JamiStrings.invalidPassword)
                                break
                            case "canceled":
                                errorOccurred(JamiStrings.operationCanceled)
                                break
                            default:
                                errorOccurred(JamiStrings.errorCreateAccount)
                                break
                        }
                    } else {
                        // Success - account imported
                        WizardViewStepModel.nextStep()
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

            Loader {
                id: qrLoader
                active: WizardViewStepModel.deviceAuthState === WizardViewStepModel.DeviceAuthState.TokenAvailable
            Layout.preferredWidth: Math.min(parent.width, 300)
                Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignHCenter

                sourceComponent: Image {
                    width: qrLoader.Layout.preferredWidth
                    height: qrLoader.Layout.preferredHeight
                    smooth: false
                    fillMode: Image.PreserveAspectFit
                    source: "image://qrImage/raw_" + tokenUri
                }
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
                AccountAdapter.cancelImportAccount()
            }
            WizardViewStepModel.previousStep()
        }
    }
}
