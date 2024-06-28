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

    function dummyQr() {
        // var fakeCode = "jami-auth://fakejamiid/123456"
        var fakeCode = "hello there"
        updateUri(fakeCode)
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ImportFromDevice) {
                clearAllTextFields()
                root.showThisPage()
            }
        }

        // function onLinkStateChanged(linkOption) {
        //     print("[LinkDevice] LinkDeviceQrPage: onLinkStateChanged")
        //     switch (linkOption) {
        //     case WizardViewStepModel.LinkDeviceStep.Waiting:
        //         print("[LinkDevice] LinkDeviceQrPage page: onLinkStateChanged Waiting")
        //         root.showThisPage()
        //         break
        //     default:
        //         // print("[LinkDevice] ImportFromDevicePage page: onLinkStateChanged default")
        //         // print("Bad account creation option: " + creationOption);
        //         // WizardViewStepModel.closeWizardView()
        //         break
        //     }
        // }
    }

    Connections {
        target: AccountAdapter

        function onDeviceAuthStateChanged(accountId, state, detail) {
            console.warn("[LinkDevice] qml update: ", state, ", ", detail)
            if (state == 0) {
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

        // title
        Text {
            text: "LinkDeviceQrPage"//JamiStrings.importAccountFromAnotherDevice
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
        // Text {
        //     text: JamiStrings.importFromDeviceDescription
        //     Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
        //     Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
        //     Layout.alignment: Qt.AlignCenter
        //     font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
        //     font.weight: Font.Medium
        //     color: JamiTheme.textColor
        //     wrapMode: Text.WordWrap
        //     horizontalAlignment: Text.AlignHCenter
        //     verticalAlignment: Text.AlignVCenter
        //     lineHeight: JamiTheme.wizardViewTextLineHeight
        // }

        // MaterialButton {
        //     id: startDiscoveryBtn
        //
        //     // TextMetrics {
        //     //     id: startDiscoveryBtnTextSize
        //     //     font.weight: Font.Bold
        //     //     font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize //.wizardViewButtonFontPixelSize
        //     //     text: "ready link"//passwdPushButton.text
        //     // }
        //
        //     preferredWidth: 250//passwdPushButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
        //
        //     primary: true
        //     Layout.alignment: Qt.AlignCenter
        //
        //     // toolTipText: CurrentAccount.hasArchivePassword ? JamiStrings.changeCurrentPassword : JamiStrings.setAPassword
        //     text: "get started"//CurrentAccount.hasArchivePassword ? JamiStrings.changePassword : JamiStrings.setPassword
        //
        //     enabled: true
        //     onClicked: {
        //         enabled = false
        //         WizardViewStepModel.nextStep() // will go to the waiting page for linkdevice
        //         AccountAdapter.startLinkDevice() // start the backend for connecting
        //     }
        //
        //     opacity: enabled ? 1.0 : 0.5
        //     scale: enabled ? 1.0 : 0.8  // Scale based on opacity
        //
        //     Behavior on opacity {
        //         NumberAnimation {
        //             from: 0.5
        //             duration: 150  // Duration for the fade animation
        //         }
        //     }
        //
        //     Behavior on scale {
        //         NumberAnimation {
        //             duration: 150  // Duration for the scale animation
        //         }
        //     }
        //
        // }

        // MaterialButton {
        //     id: debugQrBtn
        //
        //     preferredWidth: 150
        //
        //     primary: true
        //     Layout.alignment: Qt.AlignCenter
        //
        //     text: "debug qr"
        //     enabled: true
        //     onClicked: {
        //         console.warn("[LinkDevice] debug qr image")
        //         root.dummyQr()
        //     }
        // }
        MaterialButton {
            id: debugWizardBtn

            preferredWidth: 250

            primary: true
            Layout.alignment: Qt.AlignCenter

            text: "debug wz -> wait"
            enabled: true // TODO KESS make visible only when in testing mode OR just remove them all when done
            onClicked: {
                console.warn("[LinkDevice] LinkDeviceQrPage: debug WizardViewStepModel")
                WizardViewStepModel.previousStep()
            }
        }

        // loads a scalable qr image
        JamiAuthQr {
            id: uriQrImage
            imagePath: root.authQrImage
            // visible: root.authUri != ""

            Layout.alignment: Qt.AlignHCenter

            opacity: root.authQrImage == "" ? 0.0 : 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }
        }

        InfoBox {
            id: copyCodeBox

            // visible: root.authUri != ""

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
