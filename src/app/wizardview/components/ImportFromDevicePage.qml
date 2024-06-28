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
    property string authQrImage: ""

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
        linkDeviceQrPage.authQrImage = "image://authQr/" + newUri
        linkDeviceQrPage.authUri = newUri
        // uriQrImage.visible = true
        // copyCodeBox.visible = true
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

        function onLinkStateChanged(linkOption) {
            print("[LinkDevice] ImportFromDevicePage page: onLinkStateChanged")
            switch (linkOption) {
            // case WizardViewStepModel.LinkDeviceStep.OutOfBand:
            //     print("[LinkDevice] ImportFromDevicePage page: onLinkStateChanged OOB")
                // root.showThisPage()
            //     break
            default:
                break
            }
        }
    }

    Connections {
        target: AccountAdapter

        function onDeviceAuthStateChanged(accountId, state, detail) {
            console.warn("[LinkDevice] qml update: ", state, ", ", detail)

            switch (state) {
            case 0: {// show qr
                console.warn("[LinkDevice] code ready: ", detail)
                // set the uri
                root.updateUri(detail)
                // show the qr page
                WizardViewStepModel.jumpToScannableState()
                // root.showThisPage()
                break
            }
            case 1: {// token avail
                // set the uri
                root.updateUri(detail)
                // show the qr page
                WizardViewStepModel.jumpToScannableState()
                // TODO KESS verify this state
                console.warn("[LinkDevice] STATE 1 NOT COVERED: ", detail)
                break
            }
            case 2: {// connecting
                WizardViewStepModel.jumpToConnectingLinkDevice()
                break
            }
            case 3: {// auth state
                switch (detail) {
                case "success":
                    break
                case "archive_with_auth":
                    WizardViewStepModel.jumpToAuthLinkDevice()
                    break
                case "invalid_credentials":
                    WizardViewStepModel.jumpToAuthLinkDevice()
                    break
                }
                break
            }
            default:
                // log state and detail
                break
            }
        }
    }

    color: JamiTheme.secondaryBackgroundColor

    // welcome to link device wizard page
    ColumnLayout {
        id: importFromDevicePageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter


        width: Math.max(508, root.width - 100)

        // title
        Text {
            text: JamiStrings.ldStartPageTitle
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            wrapMode: Text.WordWrap
        }

        // desc
        Text {
            text: JamiStrings.ldGetStartedInfo
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

            toolTipText: JamiStrings.ldAccessOnNewDevices
            text: JamiStrings.getStarted

            enabled: true
            onClicked: {
                enabled = false
                WizardViewStepModel.jumpToConnectingLinkDevice() // will go to the waiting page for linkdevice
                AccountAdapter.startLinkDevice() // start the backend for connecting
            }

            KeyNavigation.tab: backButton
            KeyNavigation.backtab: backButton
            KeyNavigation.up: backButton
            KeyNavigation.down: backButton

            opacity: enabled ? 1.0 : 0.5
            scale: enabled ? 1.0 : 0.8  // Scale based on opacity

            Behavior on opacity {
                NumberAnimation {
                    from: 0.5
                    duration: 150
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                }
            }

        }

        // TODO enable dynamically when using jami testing gui interface
        // // debug for showing loading screen
        // MaterialButton {
        //     id: debugWizardBtn
        //
        //     preferredWidth: 250
        //
        //     primary: true
        //     Layout.alignment: Qt.AlignCenter
        //
        //     text: "debug wz"
        //     enabled: true
        //     onClicked: {
        //         console.warn("[LinkDevice] debug WizardViewStepModel")
        //         WizardViewStepModel.nextStep() // will go to the waiting page for linkdevice
        //     }
        // }

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


        // KeyNavigation.tab: pinFromDevice
        // KeyNavigation.up: connectBtn.enabled ? connectBtn : passwordFromDevice
        // KeyNavigation.down: pinFromDevice

        onClicked: WizardViewStepModel.previousStep()
    }
}
