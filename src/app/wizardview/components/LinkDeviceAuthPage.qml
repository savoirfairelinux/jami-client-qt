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

    signal showThisPage

    function initializeOnShowUp() {
        clearAllTextFields();
    }

    function clearAllTextFields() {
        // TODO clear password box
    }

    function errorOccurred(errorMessage) {
        // errorText = errorMessage;
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ImportFromDevice) {
                clearAllTextFields()
                root.showThisPage()
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

        property var pwd: ""

        // title
        Text {
            text: JamiStrings.ldAuthPageTitle
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
            text: JamiStrings.ldAuthorizeXferInfo
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

        RowLayout {
            id: authenticateUserContentColumnLayout

            spacing: 16

            // Label {
            //     id: labelDeletion
            //
            //     Layout.alignment: Qt.AlignHCenter
            //     Layout.maximumWidth: root.parent.width - JamiTheme.preferredMarginSize * 4
            //
            //     text: JamiStrings.confirmRemoval
            //     color: JamiTheme.textColor
            //     font.pointSize: JamiTheme.textFontSize
            //     font.kerning: true
            //     wrapMode: Text.Wrap
            //
            //     horizontalAlignment: Text.AlignHCenter
            //     verticalAlignment: Text.AlignVCenter
            // }

            RowLayout {

                Layout.alignment: Qt.AlignCenter
                spacing: JamiTheme.wizardViewPageLayoutSpacing

                PasswordTextEdit {
                    id: passwordEdit

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth
                    Layout.preferredHeight: visible ? 48 : 0

                    placeholderText: JamiStrings.enterCurrentPassword

                    onDynamicTextChanged: {
                        importFromDevicePageColumnLayout.pwd = dynamicText
                    }

                    Keys.onReturnPressed: { // TODO debug
                        importFromDevicePageColumnLayout.pwd = dynamicText
                    }

                }

                MaterialButton {
                    id: pwdAcceptBtn
                    preferredWidth: 100
                    text: JamiStrings.pwdAccept
                    enabled: true
                    onClicked: {
                        console.log("Ok clicked")
                        AccountAdapter.provideAccountAuthentication(CurrentAccount.id, importFromDevicePageColumnLayout.pwd)
                        // password will be validated on the other device (old) and the archive will be sent if successful
                        // account added signal will pull user to convo list
                        WizardViewStepModel.nextStep() // will go to the waiting page for linkdevice to show account xfer loading or error
                    }
                }

            }


        }

        // debug
        // MaterialButton {
        //     id: debugWizardBtn
        //
        //     preferredWidth: 150
        //
        //     primary: true
        //     Layout.alignment: Qt.AlignCenter
        //
        //     text: "debug wz"
        //     enabled: true
        //     onClicked: {
        //         console.warn("[LinkDevice] LinkDeviceQrPage: debug WizardViewStepModel")
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

        visible: true//!uriQrImage.visible //!connectBtn.spinnerTriggered

        // KeyNavigation.tab: pinFromDevice
        // KeyNavigation.up: connectBtn.enabled ? connectBtn : passwordFromDevice
        // KeyNavigation.down: pinFromDevice

        onClicked: WizardViewStepModel.previousStep()
    }
}
