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

    closeButtonVisible: false

    enum PasswordEnteringPurpose {
        ChangePassword,
        ExportAccount,
        SetPassword
    }

    property string path: ""
    property int purpose: PasswordDialog.ChangePassword

    signal done(bool success, int purpose)

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
        width: JamiTheme.preferredDialogWidth

        spacing: 16

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
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 48 : 0

            visible: purpose === PasswordDialog.ChangePassword || purpose === PasswordDialog.ExportAccount
            placeholderText: JamiStrings.enterCurrentPassword

            onDynamicTextChanged: popupContentColumnLayout.validatePassword()
        }

        PasswordTextEdit {
            id: passwordEdit

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? 48 : 0
            Layout.fillWidth: true

            visible: purpose === PasswordDialog.ChangePassword || purpose === PasswordDialog.SetPassword

            placeholderText: JamiStrings.enterNewPassword

            onDynamicTextChanged: popupContentColumnLayout.validatePassword()
        }

        PasswordTextEdit {
            id: confirmPasswordEdit

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? 48 : 0
            Layout.fillWidth: true

            visible: purpose === PasswordDialog.ChangePassword || purpose === PasswordDialog.SetPassword

            placeholderText: JamiStrings.confirmNewPassword

            onDynamicTextChanged: popupContentColumnLayout.validatePassword()
        }

        MaterialButton {
            id: btnConfirm

            Layout.alignment: Qt.AlignHCenter
            preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8

            color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            autoAccelerator: true
            enabled: purpose === PasswordDialog.SetPassword

            text: (purpose === PasswordDialog.ExportAccount) ? JamiStrings.exportAccount : JamiStrings.change

            onClicked: {
                btnConfirm.enabled = false;
                timerToOperate.restart();
            }
        }
    }
}
