// SPDX-FileCopyrightText: © 2022 Savoir-faire Linux Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick

import net.jami.Constants 1.1

// This component is used to display and edit our username.
Loader {
    id: root

    property string infohash: ''
    property string registeredName: ''
    property bool hasRegisteredName: registeredName !== ''
    property string placeholderText
    property bool editMode: false
    property real fontPointSize: JamiTheme.materialLineEditPointSize

    enum NameRegistrationState { BLANK, INVALID, TAKEN, FREE, SEARCHING }
    property int nameRegistrationState: UsernameLineEdit.NameRegistrationState.BLANK

    // This is used when the user is not editing the text.
    Component {
        id: usernameDisplayComp
        MaterialTextField {
            font.pointSize: root.fontPointSize
            readOnly: true
            text: hasRegisteredName ? registeredName : infohash
            horizontalAlignment: TextEdit.AlignHCenter
        }
    }

    // This is used when the user is editing the text.
    Component {
        id: usernameEditComp
        MaterialTextField {
            focus: true
            font.pointSize: root.fontPointSize
            placeholderText: root.placeholderText
            onAccepted: registeredName = text
        }
    }

    // We use a loader to switch between the two components depending on the
    // editMode property.
    sourceComponent: {
        editMode
                ? usernameEditComp
                : usernameDisplayComp
    }
}
