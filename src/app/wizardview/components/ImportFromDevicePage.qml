/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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
    property int preferredHeight: importFromDevicePageColumnLayout.implicitHeight

    signal showThisPage

    function initializeOnShowUp() {
        clearAllTextFields()
    }

    function clearAllTextFields() {
        connectBtn.spinnerTriggered = false
        pinFromDevice.clear()
        passwordFromDevice.clear()
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

    color: JamiTheme.backgroundColor

    ColumnLayout {
        id: importFromDevicePageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        // Prevent possible anchor loop detected on centerIn.
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: parent.top
        anchors.topMargin: 38

        Text {

            text: JamiStrings.importAccountFromOtherDevice
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            font.pixelSize: 26
        }

        Text {

            text: JamiStrings.importFromDeviceDescription
            Layout.preferredWidth: 360
            Layout.topMargin: 15
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            font.pixelSize: 15
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Grid {
            columns: 2
            spacing: 30
            Layout.alignment: Qt.AlignCenter

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

        EditableLineEdit {
            id: pinFromDevice
            wizardInput: true

            objectName: "pinFromDevice"

            Layout.alignment: Qt.AlignCenter

            focus: visible

            selectByMouse: true
            placeholderText: JamiStrings.pin
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            secondIco: ""

            KeyNavigation.tab: {
                if (connectBtn.enabled)
                    return connectBtn
                else if (connectBtn.spinnerTriggered)
                    return passwordFromDevice
                return backButton
            }
            KeyNavigation.up: passwordFromDevice
            KeyNavigation.down: KeyNavigation.tab

            onTextChanged: errorText = ""

        }

        EditableLineEdit {
            id: passwordFromDevice
            wizardInput: true

            objectName: "passwordFromDevice"
            underlined: true
            Layout.alignment: Qt.AlignCenter
            secondIco: JamiResources.eye_cross_svg


            selectByMouse: true
            placeholderText: JamiStrings.password
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            echoMode: TextInput.Password

            KeyNavigation.tab: pinFromDevice
            KeyNavigation.up: {
                if (backButton.visible)
                    return backButton
                return pinFromDevice
            }
            KeyNavigation.down: KeyNavigation.tab

            onTextChanged: errorText = ""
            onEditingFinished: pinFromDevice.forceActiveFocus()
        }

        SpinnerButton {
            id: connectBtn
            color: JamiTheme.tintedBlue

            objectName: "importFromDevicePageConnectBtn"

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins

            preferredWidth: JamiTheme.wizardButtonWidth

            spinnerTriggeredtext: JamiStrings.generatingAccount
            normalText: JamiStrings.connectFromAnotherDevice

            enabled: pinFromDevice.text.length !== 0 && !spinnerTriggered

            KeyNavigation.tab: backButton
            KeyNavigation.up: pinFromDevice
            KeyNavigation.down: KeyNavigation.tab

            onClicked: {
                spinnerTriggered = true

                WizardViewStepModel.accountCreationInfo =
                        JamiQmlUtils.setUpAccountCreationInputPara(
                            {archivePin : pinFromDevice.text,
                                password : passwordFromDevice.text})
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

        KeyNavigation.tab: passwordFromDevice
        KeyNavigation.up: connectBtn
        KeyNavigation.down: KeyNavigation.tab

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        onClicked: WizardViewStepModel.previousStep()
    }
}
