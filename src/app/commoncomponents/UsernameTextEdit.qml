// SPDX-FileCopyrightText: © 2022 Savoir-faire Linux Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick

import net.jami.Adapters 1.1
import net.jami.Constants 1.1

ModalTextEdit {
    id: usernameTextEdit

    property string infohash: CurrentAccount.uri
    property string registeredName: CurrentAccount.registeredName
    property bool hasRegisteredName: registeredName !== ''

    enum NameRegistrationState { BLANK, INVALID, TAKEN, FREE, SEARCHING }
    property int nameRegistrationState: UsernameLineEdit.NameRegistrationState.BLANK

    placeholderText: JamiStrings.chooseAUsername
    staticText: hasRegisteredName ? registeredName : infohash
    onAccepted: registeredName = text

    function startEditing() {
        if (!hasRegisteredName) {
            usernameTextEdit.editMode = true
            forceActiveFocus()
        }
    }

    onActiveFocusChanged: {
        if (!activeFocus) {
            usernameTextEdit.editMode = false
        }
    }
}
