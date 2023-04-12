/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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

    color: JamiTheme.secondaryBackgroundColor

    function clearAllTextFields() {
        connectBtn.spinnerTriggered = false;
    }
    function errorOccured(errorMessage) {
        errorText = errorMessage;
        connectBtn.spinnerTriggered = false;
    }
    function initializeOnShowUp() {
        clearAllTextFields();
    }
    signal showThisPage

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ImportFromDevice) {
                clearAllTextFields();
                root.showThisPage();
            }
        }
    }
    ColumnLayout {
        id: importFromDevicePageColumnLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: JamiTheme.wizardViewPageLayoutSpacing
        width: Math.max(508, root.width - 100)

        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.preferredMarginSize
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.importAccountFromAnotherDevice
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            lineHeight: JamiTheme.wizardViewTextLineHeight
            text: JamiStrings.importFromDeviceDescription
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        Flow {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(step1.width * 2 + spacing, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            spacing: 30

            InfoBox {
                id: step1
                description: JamiStrings.importStep1Desc
                icoColor: JamiTheme.buttonTintedBlue
                icoSource: JamiResources.settings_24dp_svg
                title: JamiStrings.importStep1
            }
            InfoBox {
                id: step2
                description: JamiStrings.importStep2Desc
                icoColor: JamiTheme.buttonTintedBlue
                icoSource: JamiResources.person_24dp_svg
                title: JamiStrings.importStep2
            }
            InfoBox {
                id: step3
                description: JamiStrings.importStep3Desc
                icoColor: JamiTheme.buttonTintedBlue
                icoSource: JamiResources.finger_select_svg
                title: JamiStrings.importStep3
            }
            InfoBox {
                id: step4
                description: JamiStrings.importStep4Desc
                icoColor: JamiTheme.buttonTintedBlue
                icoSource: JamiResources.time_clock_svg
                title: JamiStrings.importStep4
            }
        }
        ModalTextEdit {
            id: pinFromDevice
            KeyNavigation.down: passwordFromDevice
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: backButton
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(410, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            focus: visible
            objectName: "pinFromDevice"
            placeholderText: JamiStrings.pin
            staticText: ""

            onAccepted: passwordFromDevice.forceActiveFocus()
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            font.weight: Font.Medium
            text: JamiStrings.importPasswordDesc
            wrapMode: Text.WordWrap
        }
        PasswordTextEdit {
            id: passwordFromDevice
            KeyNavigation.down: {
                if (connectBtn.enabled)
                    return connectBtn;
                else if (connectBtn.spinnerTriggered)
                    return passwordFromDevice;
                return backButton;
            }
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: pinFromDevice
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(410, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewMarginSize
            objectName: "passwordFromDevice"
            placeholderText: JamiStrings.enterPassword

            onAccepted: pinFromDevice.forceActiveFocus()
        }
        SpinnerButton {
            id: connectBtn
            KeyNavigation.down: backButton
            KeyNavigation.tab: backButton
            KeyNavigation.up: passwordFromDevice
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            enabled: pinFromDevice.dynamicText.length !== 0 && !spinnerTriggered
            normalText: JamiStrings.importButton
            objectName: "importFromDevicePageConnectBtn"
            preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding + 1
            primary: true
            spinnerTriggeredtext: JamiStrings.generatingAccount

            onClicked: {
                spinnerTriggered = true;
                WizardViewStepModel.accountCreationInfo = JamiQmlUtils.setUpAccountCreationInputPara({
                        "archivePin": pinFromDevice.dynamicText,
                        "password": passwordFromDevice.dynamicText
                    });
                WizardViewStepModel.nextStep();
            }

            TextMetrics {
                id: textSize
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.weight: Font.Bold
                text: connectBtn.normalText
            }
        }
        Label {
            id: errorLabel
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
            color: JamiTheme.redColor
            font.pixelSize: JamiTheme.textEditError
            text: errorText
            visible: errorText.length !== 0
        }
    }
    BackButton {
        id: backButton
        KeyNavigation.down: pinFromDevice
        KeyNavigation.tab: pinFromDevice
        KeyNavigation.up: connectBtn.enabled ? connectBtn : passwordFromDevice
        anchors.left: parent.left
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins
        anchors.top: parent.top
        objectName: "importFromDevicePageBackButton"
        visible: !connectBtn.spinnerTriggered

        onClicked: WizardViewStepModel.previousStep()
    }
}
