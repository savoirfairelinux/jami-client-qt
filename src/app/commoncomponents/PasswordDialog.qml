/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

// PasswordDialog for changing password and exporting account
BaseModalDialog {
    id: root
    enum PasswordEnteringPurpose {
        ChangePassword,
        ExportAccount,
        SetPassword
    }

    property string path: ""
    property int purpose: PasswordDialog.ChangePassword

    height: Math.min(appWindow.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogHeight)
    title: {
        switch (purpose) {
        case PasswordDialog.ExportAccount:
            return JamiStrings.enterPassword;
        case PasswordDialog.ChangePassword:
            return JamiStrings.changePassword;
        case PasswordDialog.SetPassword:
            return JamiStrings.setPassword;
        }
    }
    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogWidth)

    signal done(bool success, int purpose)
    function reportStatus(success) {
        const title = success ? JamiStrings.success : JamiStrings.error;
        var info;
        switch (purpose) {
        case PasswordDialog.ExportAccount:
            info = success ? JamiStrings.backupSuccessful : JamiStrings.backupFailed;
            break;
        case PasswordDialog.ChangePassword:
            info = success ? JamiStrings.changePasswordSuccess : JamiStrings.changePasswordFailed;
            break;
        case PasswordDialog.SetPassword:
            info = success ? JamiStrings.setPasswordSuccess : JamiStrings.setPasswordFailed;
            break;
        }
        viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                "title": title,
                "infoText": info,
                "buttonTitles": [JamiStrings.optionOk],
                "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue]
            });
        done(success, purpose);
    }

    popupContent: ColumnLayout {
        id: popupContentColumnLayout
        spacing: 0

        function exportAccountQML() {
            var success = false;
            if (path.length > 0) {
                success = AccountAdapter.exportToFile(LRCInstance.currentAccountId, path, currentPasswordEdit.dynamicText);
            }
            reportStatus(success);
            close();
        }
        function savePasswordQML() {
            var success = AccountAdapter.savePassword(LRCInstance.currentAccountId, currentPasswordEdit.dynamicText, passwordEdit.dynamicText);
            reportStatus(success);
            close();
        }
        function validatePassword() {
            switch (purpose) {
            case PasswordDialog.ExportAccount:
                btnConfirm.enabled = currentPasswordEdit.dynamicText.length > 0;
                break;
            case PasswordDialog.SetPassword:
                btnConfirm.enabled = passwordEdit.dynamicText.length > 0 && passwordEdit.dynamicText === confirmPasswordEdit.dynamicText;
                break;
            default:
                btnConfirm.enabled = currentPasswordEdit.dynamicText.length > 0 && passwordEdit.dynamicText === confirmPasswordEdit.dynamicText;
            }
        }

        onVisibleChanged: validatePassword()

        Timer {
            id: timerToOperate
            interval: 200
            repeat: false

            onTriggered: {
                if (purpose === PasswordDialog.ExportAccount) {
                    popupContentColumnLayout.exportAccountQML();
                } else {
                    popupContentColumnLayout.savePasswordQML();
                }
            }
        }
        PasswordTextEdit {
            id: currentPasswordEdit
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? 48 : 0
            Layout.preferredWidth: JamiTheme.preferredFieldWidth
            placeholderText: JamiStrings.enterCurrentPassword
            visible: purpose === PasswordDialog.ChangePassword || purpose === PasswordDialog.ExportAccount

            onDynamicTextChanged: popupContentColumnLayout.validatePassword()
        }
        PasswordTextEdit {
            id: passwordEdit
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? 48 : 0
            Layout.preferredWidth: JamiTheme.preferredFieldWidth
            placeholderText: JamiStrings.enterNewPassword
            visible: purpose === PasswordDialog.ChangePassword || purpose === PasswordDialog.SetPassword

            onDynamicTextChanged: popupContentColumnLayout.validatePassword()
        }
        PasswordTextEdit {
            id: confirmPasswordEdit
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? 48 : 0
            Layout.preferredWidth: JamiTheme.preferredFieldWidth
            placeholderText: JamiStrings.confirmNewPassword
            visible: purpose === PasswordDialog.ChangePassword || purpose === PasswordDialog.SetPassword

            onDynamicTextChanged: popupContentColumnLayout.validatePassword()
        }
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            spacing: 16

            MaterialButton {
                id: btnConfirm
                Layout.alignment: Qt.AlignHCenter
                autoAccelerator: true
                color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                enabled: purpose === PasswordDialog.SetPassword
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true
                text: (purpose === PasswordDialog.ExportAccount) ? JamiStrings.exportAccount : JamiStrings.change

                onClicked: {
                    btnConfirm.enabled = false;
                    timerToOperate.restart();
                }
            }
            MaterialButton {
                id: btnCancel
                Layout.alignment: Qt.AlignHCenter
                autoAccelerator: true
                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true
                text: JamiStrings.optionCancel

                onClicked: close()
            }
        }
    }
}
