// SPDX-FileCopyrightText: © 2022 Savoir-faire Linux Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick

import net.jami.Constants 1.1

// This component is used to display and edit a value.
Loader {
    id: root

    property string prefixIconSrc
    property color prefixIconColor
    property string suffixIconSrc
    property color suffixIconColor

    required property string placeholderText
    required property string staticText
    property string dynamicText
    property bool inputIsValid: true
    property string infoTipText

    property variant validator

    property real fontPointSize: JamiTheme.materialLineEditPointSize

    // Always start with the static text component displayed first.
    property bool editMode: false

    // Emitted when the editor has been accepted.
    signal accepted

    // This is used when the user is not editing the text.
    Component {
        id: usernameDisplayComp
        MaterialTextField {
            font.pointSize: root.fontPointSize
            readOnly: true
            text: staticText
            horizontalAlignment: TextEdit.AlignHCenter
        }
    }

    // This is used when the user is editing the text.
    Component {
        id: usernameEditComp
        MaterialTextField {
            focus: true
            infoTipText: root.infoTipText
            prefixIconSrc: root.prefixIconSrc
            prefixIconColor: root.prefixIconColor
            suffixIconSrc: root.suffixIconSrc
            suffixIconColor: root.suffixIconColor
            font.pointSize: root.fontPointSize
            placeholderText: root.placeholderText
            validator: root.validator
            onAccepted: root.accepted()
            onTextChanged: dynamicText = text
            inputIsValid: root.inputIsValid
            onFocusChanged: if (!focus) root.editMode = false
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
