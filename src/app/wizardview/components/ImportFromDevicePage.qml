/*
* Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import Qt.labs.platform
import "../../commoncomponents"
import "../../mainview/components"

Rectangle {
    id: root

    property string errorText: ""
    property int preferredHeight: importFromDevicePageColumnLayout.implicitHeight + 2
                                  * JamiTheme.preferredMarginSize

    // The token is used to generate the QR code and is also provided to the user as a backup if the QR
    // code cannot be scanned. It is a URI using the scheme "jami-auth".
    readonly property string tokenUri: WizardViewStepModel.deviceLinkDetails["token"] || ""

    property string jamiId: ""

    function isPasswordWrong() {
        return WizardViewStepModel.deviceLinkDetails["auth_error"] !== undefined
                && WizardViewStepModel.deviceLinkDetails["auth_error"] !== ""
                && WizardViewStepModel.deviceLinkDetails["auth_error"] !== "none";
    }

    function requiresPassword() {
        return WizardViewStepModel.deviceLinkDetails["auth_scheme"] === "password";
    }

    function requiresConfirmationBeforeClosing() {
        const state = WizardViewStepModel.deviceAuthState;
        return state !== DeviceAuthStateEnum.INIT && state !== DeviceAuthStateEnum.DONE;
    }

    function isLoadingState() {
        const state = WizardViewStepModel.deviceAuthState;
        return state === DeviceAuthStateEnum.INIT || state === DeviceAuthStateEnum.CONNECTING
                || state === DeviceAuthStateEnum.IN_PROGRESS;
    }

    signal showThisPage

    function clearAllTextFields() {
        errorText = "";
    }

    function errorOccurred(errorMessage) {
        errorText = errorMessage;
    }

    MessageDialog {
        id: confirmCloseDialog

        text: JamiStrings.linkDeviceCloseWarningTitle
        informativeText: JamiStrings.linkDeviceCloseWarningMessage
        buttons: MessageDialog.Ok | MessageDialog.Cancel

        onOkClicked: function (button) {
            AccountAdapter.cancelImportAccount();
            WizardViewStepModel.previousStep();
        }
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep
                    === WizardViewStepModel.MainSteps.DeviceAuthorization) {
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
                jamiId = WizardViewStepModel.deviceLinkDetails["peer_id"] || "";
                if (jamiId.length > 0) {
                    NameDirectory.lookupAddress(CurrentAccount.id, jamiId);
                }
                break;
            case DeviceAuthStateEnum.IN_PROGRESS:
                // Account archive is being transferred
                clearAllTextFields();
                break;
            case DeviceAuthStateEnum.DONE:
                // Final state - check for specific errors
                const error = AccountAdapter.getImportErrorMessage(
                          WizardViewStepModel.deviceLinkDetails);
                if (error.length > 0) {
                    errorOccurred(error);
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
            text: JamiStrings.importFromAnotherAccount
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
                case DeviceAuthStateEnum.DONE:
                    return errorText.length > 0 ? JamiStrings.importFailed : "";
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
                text: JamiStrings.connectToAccount
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
                color: JamiTheme.textColor
                font.bold: true
            }

            // Account Widget (avatar + username + ID)
            Rectangle {
                id: accountContainer
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: accountLayout.implicitWidth + 40
                implicitHeight: accountLayout.implicitHeight + 40
                radius: 8
                color: JamiTheme.primaryBackgroundColor
                border.width: 1
                border.color: JamiTheme.textColorHovered

                RowLayout {
                    id: accountLayout
                    anchors {
                        centerIn: parent
                    }
                    spacing: 20

                    Avatar {
                        id: accountAvatar
                        showPresenceIndicator: false
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        mode: Avatar.Mode.TemporaryAccount
                        imageId: name.text || jamiId
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Text {
                            id: name
                            color: JamiTheme.textColor
                            visible: text !== undefined && text !== ""

                            Connections {
                                id: registeredNameFoundConnection
                                target: NameDirectory
                                enabled: jamiId.length > 0

                                function onRegisteredNameFound(status, address, registeredName,
                                                               requestedName) {
                                    if (address === jamiId && status
                                            === NameDirectory.LookupStatus.SUCCESS) {
                                        name.text = registeredName;
                                    }
                                }
                            }
                        }
                        Text {
                            id: userId
                            text: jamiId
                            color: JamiTheme.textColor
                        }
                    }
                }
            }

            // Password
            PasswordTextEdit {
                id: passwordField

                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                visible: requiresPassword()
                placeholderText: JamiStrings.enterPassword
                echoMode: TextInput.Password

                onAccepted: confirmButton.clicked()
            }

            Text {
                id: passwordErrorField
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width - 40
                visible: isPasswordWrong()
                text: JamiStrings.authenticationError
                font.pointSize: JamiTheme.tinyFontSize
                color: JamiTheme.redColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                Layout.margins: 10

                NewMaterialButton {
                    id: confirmButton

                    implicitHeight: JamiTheme.newMaterialButtonSetupHeight

                    filledButton: true
                    text: JamiStrings.optionConfirm
                    enabled: true

                    onClicked: {
                        AccountAdapter.provideAccountAuthentication(passwordField.visible
                                                                    ? passwordField.dynamicText :
                                                                      "");
                    }
                }
            }
        }

        // Show busy indicator when waiting for token
        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            visible: isLoadingState()
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
            color: JamiTheme.whiteColor
            radius: 8
            border.width: 1
            border.color: JamiTheme.whiteColor

            Loader {
                id: qrLoader
                anchors.centerIn: parent
                active: WizardViewStepModel.deviceAuthState === DeviceAuthStateEnum.TOKEN_AVAILABLE
                Layout.preferredWidth: Math.min(parent.parent.width - 60, 250)
                Layout.preferredHeight: Layout.preferredWidth

                sourceComponent: Image {
                    width: qrLoader.Layout.preferredWidth
                    height: qrLoader.Layout.preferredHeight
                    anchors.centerIn: parent
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

            // Container for TextArea and copy button
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: contentRow.implicitWidth + 40
                    Layout.preferredHeight: contentRow.implicitHeight + 20
                    color: JamiTheme.jamiIdBackgroundColor
                    radius: 5

                    RowLayout {
                        id: contentRow
                        anchors.centerIn: parent
                        spacing: 5

                        TextEdit {
                            id: tokenUriTextArea
                            text: tokenUri
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.wizardViewDescriptionFontPixelSize
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            selectByMouse: true
                            readOnly: true
                            cursorVisible: false
                        }

                        // Copy button
                        PushButton {
                            id: copyButton
                            Layout.alignment: Qt.AlignVCenter
                            preferredSize: 30
                            radius: 5
                            normalColor: JamiTheme.transparentColor
                            imageContainerWidth: JamiTheme.pushButtonSize
                            imageContainerHeight: JamiTheme.pushButtonSize
                            border.color: JamiTheme.transparentColor
                            imageColor: JamiTheme.tintedBlue
                            source: JamiResources.content_copy_24dp_svg
                            toolTipText: JamiStrings.copy

                            onClicked: {
                                UtilsAdapter.setClipboardText(tokenUri);
                            }
                        }
                    }
                }

                MouseArea {
                    parent: tokenUriTextArea
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    propagateComposedEvents: true

                    onClicked: function (mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true;
                            contextMenu.open();
                        }
                    }
                }

                Menu {
                    id: contextMenu
                    MenuItem {
                        text: JamiStrings.copy
                        enabled: tokenUriTextArea.selectedText.length > 0
                        onTriggered: {
                            UtilsAdapter.setClipboardText(tokenUri);
                        }
                    }
                }
            }
        }

        // Error view
        ColumnLayout {
            id: errorColumn
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width - 40
            visible: errorText !== ""
            spacing: 16

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
                text: errorText
                color: JamiTheme.textColor
                font.pointSize: JamiTheme.mediumFontSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            NewMaterialButton {
                Layout.alignment: Qt.AlignHCenter

                implicitHeight: JamiTheme.newMaterialButtonSetupHeight

                filledButton: true
                text: JamiStrings.optionTryAgain
                toolTipText: JamiStrings.optionTryAgain

                onClicked: {
                    AccountAdapter.cancelImportAccount();
                    WizardViewStepModel.previousStep();
                }
            }
        }
    }

    // Back button
    NewIconButton {
        id: backButton
        QWKSetParentHitTestVisible {}

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        objectName: "importFromDevicePageBackButton"

        iconSize: JamiTheme.iconButtonMedium
        iconSource: JamiResources.ic_arrow_back_24dp_svg
        toolTipText: JamiStrings.close

        visible: WizardViewStepModel.deviceAuthState !== DeviceAuthStateEnum.IN_PROGRESS

        onClicked: {
            if (requiresConfirmationBeforeClosing()) {
                confirmCloseDialog.open();
            } else {
                WizardViewStepModel.previousStep();
            }
        }

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.close
    }
}
