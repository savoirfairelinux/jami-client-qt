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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Styles 1.4
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

// PasswordDialog for changing password and exporting account
BaseDialog {
    id: root


    property string path: ""
    property int purpose: 0

    signal doneSignal(bool success, int currentPurpose)

    function openDialog(purposeIn, exportPathIn) {
        if (exportPathIn === undefined)
            exportPathIn = ""
        purpose = purposeIn
        path = exportPathIn
        currentPasswordEdit.clear()
        passwordEdit.borderColorMode = 0
        confirmPasswordEdit.borderColorMode = 0
        passwordEdit.clear()
        confirmPasswordEdit.clear()
        validatePassword()
        open()
    }

    function validatePassword() {
        switch (purpose) {
        case 1:
            btnConfirm.enabled = currentPasswordEdit.length > 0
            break
        case 2:
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
            success = AccountAdapter.exportToFile(
                        AccountAdapter.currentAccountId,
                        path,
                        currentPasswordEdit.text)
        }
        doneSignal(success, purpose)
        close()
    }

    function savePasswordQML() {
        var success = false
        success = AccountAdapter.savePassword(
                    AccountAdapter.currentAccountId,
                    currentPasswordEdit.text,
                    passwordEdit.text)
        if (success) {
            AccountAdapter.setArchiveHasPassword(passwordEdit.text.length !== 0)
        }
        doneSignal(success, purpose)
        close()
    }

    title: {
        switch(purpose){
        case 1:
            return JamiStrings.enterPassword
        case 0:
            return JamiStrings.changePassword
        case 2:
            return JamiStrings.setPassword
        }
    }

    Timer {
        id: timerToOperate

        interval: 200
        repeat: false

        onTriggered: {
            if (purpose === 1) {
                exportAccountQML()
            } else {
                savePasswordQML()
            }
        }
    }

    contentItem: Rectangle {
        id: passwordDialogContentRect

        implicitWidth: JamiTheme.preferredDialogWidth
        implicitHeight: JamiTheme.preferredDialogHeight
        color: JamiTheme.secondaryBackgroundColor

        ColumnLayout {
            anchors.centerIn: parent
            anchors.fill: parent
            anchors.margins: JamiTheme.preferredMarginSize

            MaterialLineEdit {
                id: currentPasswordEdit

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.preferredHeight: visible ? 48 : 0

                visible: purpose === 0 ||
                         purpose === 1
                echoMode: TextInput.Password
                placeholderText: JamiStrings.enterCurrentPassword

                onTextChanged: {
                    validatePassword()
                }
            }

            MaterialLineEdit {
                id: passwordEdit

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.preferredHeight: visible ? 48 : 0

                visible: purpose === 0 ||
                         purpose === 2
                echoMode: TextInput.Password

                placeholderText: JamiStrings.enterNewPassword

                onTextChanged: {
                    validatePassword()
                }
            }

            MaterialLineEdit {
                id: confirmPasswordEdit

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.preferredHeight: visible ? 48 : 0

                visible: purpose === 0 ||
                         purpose === 2
                echoMode: TextInput.Password

                placeholderText: JamiStrings.confirmNewPassword

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
                    enabled: purpose === 2

                    text: (purpose === 1) ? JamiStrings.exportAccount :
                                                                      JamiStrings.change

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
