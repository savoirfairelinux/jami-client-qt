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
import Qt.labs.platform

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int preferredHeight: importFromBackupPageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    property string fileImportBtnText: JamiStrings.archive
    property string filePath: ""
    property string errorText: ""

    signal showThisPage

    function clearAllTextFields() {
        connectBtn.spinnerTriggered = false
        passwordFromBackupEdit.clear()
        filePath = ""
        errorText = ""
        fileImportBtnText = JamiStrings.selectArchiveFile
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
                    WizardViewStepModel.AccountCreationOption.ImportFromBackup) {
                clearAllTextFields()
                root.showThisPage()
            }
        }
    }

    color: JamiTheme.secondaryBackgroundColor

    JamiFileDialog {
        id: importFromFileDialog

        mode: JamiFileDialog.OpenFile
        title: JamiStrings.openFile
        folder: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Desktop"

        nameFilters: [JamiStrings.jamiArchiveFiles, JamiStrings.allFiles]

        onVisibleChanged: {
            if (!visible) {
                rejected()
            }
        }

        onRejected: {
            fileImportBtn.forceActiveFocus()
        }

        onAccepted: {
            filePath = file
            if (file.length !== "") {
                fileImportBtnText = UtilsAdapter.toFileInfoName(file)
            } else {
                fileImportBtnText = JamiStrings.archive
            }
        }
    }

    ColumnLayout {
        id: importFromBackupPageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: JamiTheme.wizardViewLayoutTopMargin

        width: Math.max(508, root.width - 100)

        Text {

            text: JamiStrings.importFromArchiveBackup
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

            text: JamiStrings.importFromArchiveBackupDescription
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 15
            Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            wrapMode : Text.WordWrap
        }

        MaterialButton {
            id: fileImportBtn

            objectName: "fileImportBtn"
            secondary: true
            color: JamiTheme.secAndTertiTextColor
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 35

            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

            text: fileImportBtnText
            toolTipText: JamiStrings.importAccountArchive

            KeyNavigation.tab: passwordFromBackupEdit
            KeyNavigation.up: backButton
            KeyNavigation.down: passwordFromBackupEdit

            onClicked: {
                errorText = ""
                importFromFileDialog.open()
            }
        }

        EditableLineEdit {
            id: passwordFromBackupEdit

            objectName: "passwordFromBackupEdit"

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            focus: visible

            selectByMouse: true
            placeholderText: JamiStrings.password
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            secondIco: JamiResources.eye_cross_svg

            echoMode: TextInput.Password

            KeyNavigation.tab: connectBtn.enabled ? connectBtn : backButton
            KeyNavigation.up: fileImportBtn
            KeyNavigation.down: connectBtn.enabled ? connectBtn : backButton

            onTextChanged: errorText = ""

            onSecondIcoClicked: { toggleEchoMode() }

        }

        SpinnerButton {
            id: connectBtn

            objectName: "importFromBackupPageConnectBtn"

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins
            Layout.topMargin: 30

            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

            spinnerTriggeredtext: JamiStrings.generatingAccount
            normalText: JamiStrings.connectFromBackup

            color: JamiTheme.tintedBlue

            enabled: {
                if (spinnerTriggered)
                    return false
                if (!(filePath.length === 0) && errorText.length === 0)
                    return true
                return false
            }

            KeyNavigation.tab: backButton
            KeyNavigation.up: passwordFromBackupEdit
            KeyNavigation.down: backButton

            onClicked: {
                if (connectBtn.focus)
                    fileImportBtn.forceActiveFocus()
                spinnerTriggered = true

                WizardViewStepModel.accountCreationInfo =
                        JamiQmlUtils.setUpAccountCreationInputPara(
                            {archivePath : UtilsAdapter.getAbsPath(filePath),
                                password : passwordFromBackupEdit.text})
                WizardViewStepModel.nextStep()
            }
        }

        Label {
            id: errorLabel

            objectName: "errorLabel"

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

        objectName: "importFromBackupPageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20

        visible: !connectBtn.spinnerTriggered

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        KeyNavigation.tab: fileImportBtn
        KeyNavigation.up: {
            if (connectBtn.enabled)
                return connectBtn
            return passwordFromBackupEdit
        }
        KeyNavigation.down: fileImportBtn

        onClicked: WizardViewStepModel.previousStep()
    }
}
