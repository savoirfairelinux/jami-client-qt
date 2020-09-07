/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.15
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.15
import net.jami.Models 1.0

import "../constant"

// PasswordDialog for changing password and exporting account
Window {
    id: root

    enum PasswordEnteringPurpose {
        ChangePassword,
        ExportAccount,
        SetPassword
    }

    property string path: ""
    property int purpose: PasswordDialog.ChangePassword

    signal doneSignal(bool success, int currentPurpose)

    function openDialog(purposeIn, exportPathIn = "") {
        purpose = purposeIn
        path = exportPathIn
        currentPasswordEdit.clear()
        passwordEdit.borderColorMode = InfoLineEdit.NORMAL
        confirmPasswordEdit.borderColorMode = InfoLineEdit.NORMAL
        passwordEdit.clear()
        confirmPasswordEdit.clear()
        validatePassword()
        show()
    }

    function validatePassword() {
        switch (purpose) {
        case PasswordDialog.ExportAccount:
            btnConfirm.enabled = currentPasswordEdit.length > 0
            break
        case PasswordDialog.SetPassword:
            btnConfirm.enabled = passwordEdit.length > 0 &&
                    passwordEdit.text === confirmPasswordEdit.text
            break
        default:
            btnConfirm.enabled = currentPasswordEdit.length > 0 &&
                    passwordEdit.text === confirmPasswordEdit.text
        }
    }

    function exportAccountQML() {
        var success = false
        if (path.length > 0) {
            success = ClientWrapper.accountAdaptor.exportToFile(ClientWrapper.utilsAdaptor.getCurrAccId(),
                                                                path, currentPasswordEdit.text)
        }
        doneSignal(success, purpose)
        close()
    }

    function savePasswordQML() {
        var success = false
        success = ClientWrapper.accountAdaptor.savePassword(ClientWrapper.utilsAdaptor.getCurrAccId(),
                                                            currentPasswordEdit.text, passwordEdit.text)
        if (success) {
            ClientWrapper.accountAdaptor.setArchiveHasPassword(passwordEdit.text.length !== 0)
        }
        doneSignal(success, purpose)
        close()
    }

    title: {
        switch(purpose){
        case PasswordDialog.ExportAccount:
            return qsTr("Export account")
        case PasswordDialog.ChangePassword:
            return qsTr("Choose a new password")
        case PasswordDialog.SetPassword:
            return qsTr("Set password")
        }
    }

    visible: false
    modality: Qt.WindowModal
    flags: Qt.WindowStaysOnTopHint

    width: JamiTheme.preferredDialogWidth
    height: JamiTheme.preferredDialogHeight
    minimumWidth: JamiTheme.preferredDialogWidth
    minimumHeight: JamiTheme.preferredDialogHeight

    Timer {
        id: timerToOperate

        interval: 200
        repeat: false

        onTriggered: {
            if (purpose === PasswordDialog.ExportAccount) {
                exportAccountQML()
            } else {
                savePasswordQML()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.centerIn: parent

        ColumnLayout {
            id: contentLayout
            Layout.margins: JamiTheme.preferredMarginSize
            spacing: 16
            Layout.alignment: Qt.AlignHCenter

            MaterialLineEdit {
                id: currentPasswordEdit

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.preferredHeight: visible ? 48 : 0

                visible: purpose === PasswordDialog.ChangePassword ||
                         purpose === PasswordDialog.ExportAccount
                echoMode: TextInput.Password
                placeholderText: qsTr("Enter Current Password")

                onTextChanged: {
                    validatePassword()
                }
            }

            MaterialLineEdit {
                id: passwordEdit

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.preferredHeight: visible ? 48 : 0

                visible: purpose === PasswordDialog.ChangePassword ||
                         purpose === PasswordDialog.SetPassword
                echoMode: TextInput.Password

                placeholderText: qsTr("Enter New Password")

                onTextChanged: {
                    validatePassword()
                }
            }

            MaterialLineEdit {
                id: confirmPasswordEdit

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.preferredHeight: visible ? 48 : 0

                visible: purpose === PasswordDialog.ChangePassword ||
                         purpose === PasswordDialog.SetPassword
                echoMode: TextInput.Password

                placeholderText: qsTr("Confirm New Password")

                onTextChanged: {
                    validatePassword()
                }
            }

            RowLayout {
                spacing: 16
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter

                MaterialButton {
                    id: btnConfirm

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight

                    color: enabled? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    enabled: purpose === PasswordDialog.SetPassword

                    text: (purpose === PasswordDialog.ExportAccount ? qsTr("Export") :
                                                                      qsTr("Change"))

                    onClicked: {
                        btnConfirm.enabled = false
                        timerToOperate.restart()
                    }
                }

                MaterialButton {
                    id: btnCancel

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true

                    text: qsTr("Cancel")

                    onClicked: {
                        close()
                    }
                }
            }
        }
    }
}
