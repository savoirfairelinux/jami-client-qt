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
        clearAllTextFields()
    }

    function clearAllTextFields() {
    }

    function errorOccurred(errorMessage) {
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ImportFromDevice) {
                clearAllTextFields()
            }
        }
    }

    Connections {
        target: AccountAdapter

        function onDeviceAuthStateChanged(accountId, state, detail) {
            console.warn("[LinkDevice] qml update (loading): ", state, ", ", detail);
        }
    }

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: importFromDevicePageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        width: Math.max(508, root.width - 100)

        AnimatedImage {
            id: spinnerMovie

            Layout.alignment: Qt.AlignCenter

            Layout.preferredWidth: 30
            Layout.preferredHeight: 30

            source: JamiResources.jami_rolling_spinner_gif
            playing: visible
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }

        // title
        Text {
            text: JamiStrings.ldLoadingPageTitle
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

        // MaterialButton {
        //     id: debugWizardBtn1
        //
        //     preferredWidth: 250
        //
        //     primary: true
        //     Layout.alignment: Qt.AlignCenter
        //
        //     text: "debug -> scan"
        //     enabled: true
        //     onClicked: {
        //         console.warn("[LinkDevice] LinkDeviceLoadingPage: debug WizardViewStepModel")
        //         WizardViewStepModel.jumpToScannableState()
        //     }
        // }

        // // debug btn
        // MaterialButton {
        //     id: debugWizardBtn2
        //
        //     preferredWidth: 250
        //
        //     primary: true
        //     Layout.alignment: Qt.AlignCenter
        //
        //     text: "debug wz -> auth"
        //     enabled: true
        //     onClicked: {
        //         console.warn("[LinkDevice] LinkDeviceLoadingPage: debug WizardViewStepModel")
        //         WizardViewStepModel.jumpToAuthLinkDevice()
        //     }
        // }

        // Label {
        //     id: errorLabel
        //
        //     Layout.alignment: Qt.AlignCenter
        //     Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
        //
        //     visible: errorText.length !== 0
        //
        //     text: errorText
        //
        //     font.pixelSize: JamiTheme.textEditError
        //     color: JamiTheme.redColor
        // }
    }

    // TODO this back button is different on every page for some reason and needs to be unified
    BackButton {
        id: backButton

        objectName: "importFromDevicePageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        visible: false

        // TODO bring back all sensible keymaps
        // KeyNavigation.tab: pinFromDevice
        // KeyNavigation.up: connectBtn.enabled ? connectBtn : passwordFromDevice
        // KeyNavigation.down: pinFromDevice

        onClicked: WizardViewStepModel.previousStep()
    }
}
