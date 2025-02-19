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
import net.jami.Enums 1.1
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
    property string peerUserName: ""
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
            case DeviceAuthStateEnum.TOKEN_AVAILABLE:
                // Token is available and displayed as QR code
                clearAllTextFields();
                break;
            case DeviceAuthStateEnum.CONNECTING:
                // P2P connection being established
                clearAllTextFields();
                break;
            case DeviceAuthStateEnum.AUTHENTICATING:
                peerId = WizardViewStepModel.deviceLinkDetails["peer_id"] || "";
                // Try to get display name for the peer ID
                if (peerId) {
                    // Maybe start a lookup here
                    peerDisplayName = peerId;
                }
                break;
            case DeviceAuthStateEnum.IN_PROGRESS:
                // Account archive is being transferred
                clearAllTextFields();
                break;
            case DeviceAuthStateEnum.DONE:
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

            text: "Import from another account"
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
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            lineHeight: JamiTheme.wizardViewTextLineHeight
            text: {
                switch (WizardViewStepModel.deviceAuthState) {
                case DeviceAuthStateEnum.INIT:
                    return JamiStrings.waitingForToken;
                case DeviceAuthStateEnum.TOKEN_AVAILABLE:
                    return JamiStrings.scanToImportAccount;
                case DeviceAuthStateEnum.CONNECTING:
                    return JamiStrings.connectingToDevice;
                case DeviceAuthStateEnum.AUTHENTICATING:
                    return JamiStrings.confirmAccountImport;
                case DeviceAuthStateEnum.IN_PROGRESS:
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
            visible: WizardViewStepModel.deviceAuthState === DeviceAuthStateEnum.AUTHENTICATING
            spacing: JamiTheme.wizardViewPageLayoutSpacing

            Text {
                Layout.fillWidth: true
                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                lineHeight: JamiTheme.wizardViewTextLineHeight
                text: "Connect to account"
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
                color: JamiTheme.textColor
                font.bold: true
            }

            // Peer ID Widget (avatar + username + ID)
            Rectangle {
                id: peerContainer
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: peerLayout.implicitWidth + 40
                implicitHeight: peerLayout.implicitHeight + 40
                radius: 8
                color: JamiTheme.primaryBackgroundColor
                border.width: 1
                border.color: JamiTheme.tabbarBorderColor

                RowLayout {
                    id: peerLayout
                    anchors {
                        centerIn: parent
                    }
                    spacing: 20

                    Avatar {
                        id: userAvatar
                        showPresenceIndicator: false
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        mode: Avatar.Mode.Contact
                        imageId: userName.peerID
                        visible: userName.peerID !== ""
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Text {
                            id: userName
                            visible: text !== undefined && text !== ""
                            property int registrationState: UsernameTextEdit.NameRegistrationState.BLANK
                            property string peerID
                            Component.onCompleted: peerID = "6352c8525fe7eb49283fe4f0e17174cb89ce7c02"
                            onPeerIDChanged: NameDirectory.lookupAddress(CurrentAccount.id, peerID)
                            Connections {
                                id: registeredNameFoundConnection

                                target: NameDirectory
                                enabled: userName.peerID

                                function onRegisteredNameFound(status, address, registeredName, requestedName) {
                                    if (address === userName.peerID && status === NameDirectory.LookupStatus.SUCCESS) {
                                        userName.text = registeredName;
                                    }
                                }
                            }
                        }
                        Text {
                            id: userId
                            text: "6352c8525fe7eb49283fe4f0e17174cb89ce7c02"
                        }
                    }
                }
            }

            PasswordTextEdit {
                id: passwordField

                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 10
                visible: WizardViewStepModel.deviceLinkDetails["auth_scheme"] === "password"
                placeholderText: JamiStrings.enterPassword
                echoMode: TextInput.Password

                onAccepted: confirmButton.clicked()
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                Layout.margins: 10

                MaterialButton {
                    id: confirmButton
                    text: JamiStrings.optionConfirm
                    primary: true
                    enabled: !passwordField.visible || passwordField.text.length > 0
                    onClicked: {
                        AccountAdapter.provideAccountAuthentication(passwordField.visible ? passwordField.text : "");
                    }
                }
            }
        }

        // Show busy indicator when waiting for token
        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            visible: WizardViewStepModel.deviceAuthState === DeviceAuthStateEnum.INIT || WizardViewStepModel.deviceAuthState === DeviceAuthStateEnum.CONNECTING
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            running: visible
        }

        // QR Code container with frame
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: qrLoader.Layout.preferredWidth + 40
            Layout.preferredHeight: qrLoader.Layout.preferredHeight + 40
            visible: WizardViewStepModel.deviceAuthState === DeviceAuthStateEnum.TOKEN_AVAILABLE
            color: JamiTheme.primaryBackgroundColor
            radius: 8
            border.width: 1
            border.color: JamiTheme.tabbarBorderColor

            Loader {
                id: qrLoader
                anchors.centerIn: parent
                active: WizardViewStepModel.deviceAuthState === DeviceAuthStateEnum.TOKEN_AVAILABLE
                Layout.preferredWidth: Math.min(parent.parent.width - 60, 250)
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
                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                lineHeight: JamiTheme.wizardViewTextLineHeight
                color: JamiTheme.textColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            TextArea {
                id: tokenUriTextArea
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.parent.width - 40
                text: tokenUri
                font.pointSize: JamiTheme.wizardViewDescriptionFontPixelSize
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

        visible: WizardViewStepModel.deviceAuthState !== DeviceAuthStateEnum.IN_PROGRESS

        onClicked: {
            if (WizardViewStepModel.deviceAuthState !== DeviceAuthStateEnum.INIT) {
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
                    WizardViewStepModel.deviceAuthState = DeviceAuthStateEnum[currentText.toUpperCase()];

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
                id: peerIdField
                Layout.fillWidth: true
                placeholderText: "Peer Display Name"
                onTextChanged: {
                    if (stateCombo.currentText === "Authenticating") {
                        peerId = text;
                    }
                }
            }
        }
    }
}
