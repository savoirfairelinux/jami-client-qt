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
        connectBtn.spinnerTriggered = false;
        filePath = "";
        errorText = "";
        fileImportBtnText = JamiStrings.selectArchiveFile;
    }

    function errorOccurred(errorMessage) {
        errorText = errorMessage;
        connectBtn.spinnerTriggered = false;
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ImportFromBackup) {
                clearAllTextFields();
                root.showThisPage();
            }
        }
    }

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: importFromBackupPageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        width: Math.max(508, root.width - 100)

        Text {

            text: JamiStrings.importFromArchiveBackup
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

            text: JamiStrings.importFromArchiveBackupDescription
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
            Layout.preferredWidth: Math.min(400, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            wrapMode: Text.WordWrap
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        MaterialButton {
            id: fileImportBtn

            TextMetrics {
                id: textSizeFileImportBtn
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                text: fileImportBtn.text
            }

            objectName: "fileImportBtn"
            secondary: true

            focus: visible

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

            preferredWidth: textSizeFileImportBtn.width + 2 * JamiTheme.buttontextWizzardPadding

            text: fileImportBtnText
            toolTipText: JamiStrings.importAccountArchive

            KeyNavigation.up: backButton
            KeyNavigation.down: passwordFromBackupEdit
            KeyNavigation.tab: KeyNavigation.down

            onClicked: {
                errorText = "";
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                        "title": JamiStrings.openFile,
                        "fileMode": JamiFileDialog.OpenFile,
                        "folder": StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Desktop",
                        "nameFilters": [JamiStrings.jamiArchiveFiles, JamiStrings.allFiles]
                    });
                dlg.fileAccepted.connect(function (file) {
                        filePath = file;
                        if (file.length !== "") {
                            fileImportBtnText = UtilsAdapter.toFileInfoName(file);
                            passwordFromBackupEdit.forceActiveFocus();
                        } else {
                            fileImportBtnText = JamiStrings.archive;
                        }
                    });
                dlg.rejected.connect(function () {
                        fileImportBtn.forceActiveFocus();
                    });
            }
        }

        Text {
            text: JamiStrings.passwordArchive
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            wrapMode: Text.WordWrap
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        PasswordTextEdit {
            id: passwordFromBackupEdit

            objectName: "passwordFromBackupEdit"

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewMarginSize
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            placeholderText: JamiStrings.enterPassword

            KeyNavigation.up: fileImportBtn
            KeyNavigation.down: connectBtn.enabled ? connectBtn : backButton
            KeyNavigation.tab: KeyNavigation.down

            onAccepted: connectBtn.forceActiveFocus()
        }

        SpinnerButton {
            id: connectBtn

            TextMetrics {
                id: textSizeConnectBtn
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                text: connectBtn.normalText
            }

            objectName: "importFromBackupPageConnectBtn"

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

            preferredWidth: textSizeConnectBtn.width + 2 * JamiTheme.buttontextWizzardPadding + 1
            primary: true

            spinnerTriggeredtext: JamiStrings.generatingAccount
            normalText: JamiStrings.importButton

            enabled: {
                if (spinnerTriggered)
                    return false;
                if (!(filePath.length === 0) && errorText.length === 0)
                    return true;
                return false;
            }

            KeyNavigation.up: passwordFromBackupEdit
            KeyNavigation.down: backButton
            KeyNavigation.tab: KeyNavigation.down

            onClicked: {
                if (connectBtn.focus)
                    fileImportBtn.forceActiveFocus();
                spinnerTriggered = true;
                WizardViewStepModel.accountCreationInfo = JamiQmlUtils.setUpAccountCreationInputPara({
                        "archivePath": UtilsAdapter.getAbsPath(filePath),
                        "password": passwordFromBackupEdit.dynamicText
                    });
                WizardViewStepModel.nextStep();
            }
        }

        Label {
            id: errorLabel

            objectName: "errorLabel"

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

        objectName: "importFromBackupPageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20

        visible: !connectBtn.spinnerTriggered

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        KeyNavigation.tab: fileImportBtn
        KeyNavigation.up: {
            if (connectBtn.enabled)
                return connectBtn;
            return passwordFromBackupEdit;
        }
        KeyNavigation.down: fileImportBtn

        onClicked: WizardViewStepModel.previousStep()
    }
}
