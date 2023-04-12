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
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    property string errorText: ""
    property string fileImportBtnText: JamiStrings.archive
    property string filePath: ""
    property int preferredHeight: importFromBackupPageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    color: JamiTheme.secondaryBackgroundColor

    function clearAllTextFields() {
        connectBtn.spinnerTriggered = false;
        filePath = "";
        errorText = "";
        fileImportBtnText = JamiStrings.selectArchiveFile;
    }
    function errorOccured(errorMessage) {
        errorText = errorMessage;
        connectBtn.spinnerTriggered = false;
    }
    signal showThisPage

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.ImportFromBackup) {
                clearAllTextFields();
                root.showThisPage();
            }
        }
    }
    ColumnLayout {
        id: importFromBackupPageColumnLayout
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
            text: JamiStrings.importFromArchiveBackup
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(400, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            horizontalAlignment: Text.AlignHCenter
            lineHeight: JamiTheme.wizardViewTextLineHeight
            text: JamiStrings.importFromArchiveBackupDescription
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        MaterialButton {
            id: fileImportBtn
            KeyNavigation.down: passwordFromBackupEdit
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: backButton
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            focus: visible
            objectName: "fileImportBtn"
            preferredWidth: textSizeFileImportBtn.width + 2 * JamiTheme.buttontextWizzardPadding
            secondary: true
            text: fileImportBtnText
            toolTipText: JamiStrings.importAccountArchive

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

            TextMetrics {
                id: textSizeFileImportBtn
                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                font.weight: Font.Bold
                text: fileImportBtn.text
            }
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            horizontalAlignment: Text.AlignHCenter
            lineHeight: JamiTheme.wizardViewTextLineHeight
            text: JamiStrings.passwordArchive
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        PasswordTextEdit {
            id: passwordFromBackupEdit
            KeyNavigation.down: connectBtn.enabled ? connectBtn : backButton
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: fileImportBtn
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewMarginSize
            objectName: "passwordFromBackupEdit"
            placeholderText: JamiStrings.enterPassword

            onAccepted: connectBtn.forceActiveFocus()
        }
        SpinnerButton {
            id: connectBtn
            KeyNavigation.down: backButton
            KeyNavigation.tab: KeyNavigation.down
            KeyNavigation.up: passwordFromBackupEdit
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: errorLabel.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            enabled: {
                if (spinnerTriggered)
                    return false;
                if (!(filePath.length === 0) && errorText.length === 0)
                    return true;
                return false;
            }
            normalText: JamiStrings.importButton
            objectName: "importFromBackupPageConnectBtn"
            preferredWidth: textSizeConnectBtn.width + 2 * JamiTheme.buttontextWizzardPadding + 1
            primary: true
            spinnerTriggeredtext: JamiStrings.generatingAccount

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

            TextMetrics {
                id: textSizeConnectBtn
                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
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
            objectName: "errorLabel"
            text: errorText
            visible: errorText.length !== 0
        }
    }
    BackButton {
        id: backButton
        KeyNavigation.down: fileImportBtn
        KeyNavigation.tab: fileImportBtn
        KeyNavigation.up: {
            if (connectBtn.enabled)
                return connectBtn;
            return passwordFromBackupEdit;
        }
        anchors.left: parent.left
        anchors.margins: 20
        anchors.top: parent.top
        objectName: "importFromBackupPageBackButton"
        preferredSize: JamiTheme.wizardViewPageBackButtonSize
        visible: !connectBtn.spinnerTriggered

        onClicked: WizardViewStepModel.previousStep()
    }
}
