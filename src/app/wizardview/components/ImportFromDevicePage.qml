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

    signal showThisPage

    function initializeOnShowUp() {
        clearAllTextFields()
    }

    function clearAllTextFields() {
        connectBtn.spinnerTriggered = false
    }

    function errorOccured(errorMessage) {
        errorText = errorMessage
        connectBtn.spinnerTriggered = false
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation &&
                    WizardViewStepModel.accountCreationOption ===
                    WizardViewStepModel.AccountCreationOption.ImportFromDevice) {
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
        anchors.top: parent.top
        anchors.topMargin: JamiTheme.wizardViewLayoutTopMargin

        width: Math.max(508, root.width - 100)

        Text {

            text: JamiStrings.importAccountFromAnotherDevice
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 15
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            wrapMode : Text.WordWrap
        }

        Text {

            text: JamiStrings.importFromDeviceDescription
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: 15
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Flow {
            spacing: 30
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 40
            Layout.preferredWidth: Math.min(step1.width * 2 + 2 * spacing, root.width - JamiTheme.preferredMarginSize * 2)

            InfoBox {
                id: step1
                icoSource: JamiResources.settings_24dp_svg
                title: JamiStrings.importStep1
                description: JamiStrings.importStep1Desc
            }

            InfoBox {
                id: step2
                icoSource: JamiResources.person_24dp_svg
                title: JamiStrings.importStep2
                description: JamiStrings.importStep2Desc
            }

            InfoBox {
                id: step3
                icoSource: JamiResources.finger_select_svg
                title: JamiStrings.importStep3
                description: JamiStrings.importStep3Desc
            }

            InfoBox {
                id: step4
                icoSource: JamiResources.time_clock_svg
                title: JamiStrings.importStep4
                description: JamiStrings.importStep4Desc
            }

        }

        ModalTextEdit {
            id: pinFromDevice

            objectName: "pinFromDevice"

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: 22

            focus: visible

            placeholderText: JamiStrings.pin
            staticText: ""

            KeyNavigation.up: backButton
            KeyNavigation.down: passwordFromDevice
            KeyNavigation.tab: KeyNavigation.down

            onAccepted: passwordFromDevice.forceActiveFocus()

        }

        PasswordTextEdit {
            id: passwordFromDevice

            objectName: "passwordFromDevice"
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            placeholderText: JamiStrings.enterPassword

            KeyNavigation.up: pinFromDevice
            KeyNavigation.down: {
                if (connectBtn.enabled)
                    return connectBtn
                else if (connectBtn.spinnerTriggered)
                    return passwordFromDevice
                return backButton
            }
            KeyNavigation.tab: KeyNavigation.down

            onAccepted: pinFromDevice.forceActiveFocus()

        }

        SpinnerButton {
            id: connectBtn
            color: JamiTheme.tintedBlue

            objectName: "importFromDevicePageConnectBtn"

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 22
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins

            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

            spinnerTriggeredtext: JamiStrings.generatingAccount
            normalText: JamiStrings.connectFromAnotherDevice

            enabled: pinFromDevice.dynamicText.length !== 0 && !spinnerTriggered

            KeyNavigation.tab: backButton
            KeyNavigation.up: passwordFromDevice
            KeyNavigation.down: backButton

            onClicked: {
                spinnerTriggered = true

                WizardViewStepModel.accountCreationInfo =
                        JamiQmlUtils.setUpAccountCreationInputPara(
                            {archivePin : pinFromDevice.dynamicText,
                                password : passwordFromDevice.dynamicText})
                WizardViewStepModel.nextStep()
            }
        }

        Label {
            id: errorLabel

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

            visible: errorText.length !== 0

            text: errorText

            font.pointSize: JamiTheme.textFontSize
            color: JamiTheme.redColor
        }
    }

    BackButton {
        id: backButton

        objectName: "importFromDevicePageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 10

        visible: !connectBtn.spinnerTriggered

        KeyNavigation.tab: pinFromDevice
        KeyNavigation.up: connectBtn.enabled ? connectBtn : passwordFromDevice
        KeyNavigation.down: pinFromDevice

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        onClicked: WizardViewStepModel.previousStep()
    }
}
