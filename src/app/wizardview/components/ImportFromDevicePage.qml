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

    property string authUri: ""
    property string authQrImage: "image://authQr"

    signal showThisPage

    function initializeOnShowUp() {
        clearAllTextFields();
    }

    function clearAllTextFields() {
        // connectBtn.spinnerTriggered = false;
    }

    function errorOccurred(errorMessage) {
        errorText = errorMessage;
        // connectBtn.spinnerTriggered = false;
    }

    function updateUri(newUri) {
        root.authQrImage = "image://authQr/" + newUri;
        root.authUri = newUri;
        uriQrImage.visible = true;
        copyCodeBox.visible = true;
    }

    function dummyQr() {
        // var fakeCode = "jami-auth://fakejamiid/123456"
        var fakeCode = "hello there"
        updateUri(fakeCode)
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ImportFromDevice) {
                clearAllTextFields();
                root.showThisPage();
            }
        }
    }

    Connections {
        target: AccountAdapter

        function onDeviceAuthStateChanged(accountId, state, detail) {
            console.warn("[LinkDevice] qml update: ", state, ", ", detail)
            if (state == 0) {
                console.warn("[LinkDevice] code ready: ", detail)
                // request image
                root.authQrImage = "image://authQr/" + detail
                root.authUri = detail
                uriQrImage.visible = true
                copyCodeBox.visible = true
                // TODO timer to stop the page and show error
            }
        }
    }

    // Timer {
    //     id: retryBootstrapTimer
    //     interval: 5000  // 5 seconds
    //     running: false
    //     repeat: false
    //     onTriggered: startDiscoveryBtn.enabled = true
    // }

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

        Timer {
            id: spamTimer
            interval: 5000  // 5 seconds
            running: false
            repeat: false
            onTriggered: startDiscoveryBtn.enabled = true
        }

        MaterialButton {
            id: startDiscoveryBtn

            // TextMetrics {
            //     id: startDiscoveryBtnTextSize
            //     font.weight: Font.Bold
            //     font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize //.wizardViewButtonFontPixelSize
            //     text: "ready link"//passwdPushButton.text
            // }

            preferredWidth: 250//passwdPushButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding

            primary: true
            Layout.alignment: Qt.AlignCenter

            // toolTipText: CurrentAccount.hasArchivePassword ? JamiStrings.changeCurrentPassword : JamiStrings.setAPassword
            text: "get started"//CurrentAccount.hasArchivePassword ? JamiStrings.changePassword : JamiStrings.setPassword

            enabled: true
            onClicked: {
                // this will come later in the process once the archive is transferred
                // if (CurrentAccount.hasArchivePassword) {
                //     viewCoordinator.presentDialog(appWindow, "commoncomponents/RevokePasswordDialog.qml", {
                //     })
                // }
                // Example here:
                // onClicked: viewCoordinator.presentDialog(appWindow, "commoncomponents/PasswordDialog.qml", {
                //         "purpose": CurrentAccount.hasArchivePassword ? PasswordDialog.ChangePassword : PasswordDialog.SetPassword
                // })
                enabled = false
                spamTimer.start()
                // console.info("[LinkDevice] Requesting P2P account client-side.");
                AccountAdapter.startLinkDevice();
            }

            opacity: enabled ? 1.0 : 0.5
            scale: enabled ? 1.0 : 0.8  // Scale based on opacity

            Behavior on opacity {
                NumberAnimation {
                    from: 0.5
                    duration: 150  // Duration for the fade animation
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 150  // Duration for the scale animation
                }
            }

        }

        MaterialButton {
            id: debugQrBtn

            // TextMetrics {
            //     font.weight: Font.Bold
            //     font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            //     text: "test qr gen"
            // }

            preferredWidth: 150

            primary: true
            Layout.alignment: Qt.AlignCenter

            text: "debug"
            enabled: true
            onClicked: {
                console.warn("[LinkDevice] debug qr image")
                root.dummyQr()
            }
        }

        // Button {
        //     id: confirmPasswordBtn
        //
        //     // job is to confirm the transfer after the archive has been sent
        //
        //     onClicked: {
        //         // this will come later in the process once the archive is transferred
        //         if (CurrentAccount.hasArchivePassword) {
        //             viewCoordinator.presentDialog(appWindow, "commoncomponents/RevokePasswordDialog.qml", {
        //             })
        //         }
        //         // Example here:
        //         // onClicked: viewCoordinator.presentDialog(appWindow, "commoncomponents/PasswordDialog.qml", {
        //         //         "purpose": CurrentAccount.hasArchivePassword ? PasswordDialog.ChangePassword : PasswordDialog.SetPassword
        //         // })
        //     }
        //
        // }

        // loads a scalable qr image
        ZoomableRectangle {
            id: uriQrImage
            imagePath: root.authQrImage
            visible: false

            width: dimension * scaleFactor
            height: dimension * scaleFactor

            anchors.centerIn: parent
            Layout.alignment: Qt.AlignHCenter

            opacity: visible ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }
        }

        InfoBox {
            id: copyCodeBox

            visible: false

            spacing: 30
            Layout.alignment: Qt.AlignHCenter
            title: root.authUri

            opacity: visible ? 1.0 : 0.5
            scale: visible ? 1.0 : 0.8  // Scale based on opacity

            Behavior on opacity {
                NumberAnimation {
                    from: 0.5
                    duration: 150  // Duration for the fade animation
                }
                    }

            Behavior on scale {
                NumberAnimation {
                    duration: 150  // Duration for the scale animation
                }
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

        objectName: "importFromDevicePageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        visible: !uriQrImage.visible //!connectBtn.spinnerTriggered

        // KeyNavigation.tab: pinFromDevice
        // KeyNavigation.up: connectBtn.enabled ? connectBtn : passwordFromDevice
        // KeyNavigation.down: pinFromDevice

        onClicked: WizardViewStepModel.previousStep()
    }
}
