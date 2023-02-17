/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

import net.jami.Constants 1.1

// This component is used to display and edit a value.
Loader {
    id: root
    property string prefixIconSrc: JamiResources.round_edit_24dp_svg
    property color prefixIconColor: JamiTheme.editLineColor
    property string suffixIconSrc : ""
    property color suffixIconColor: JamiTheme.buttonTintedBlue
    property string suffixBisIconSrc : ""
    property color suffixBisIconColor: JamiTheme.buttonTintedBlue

    required property string placeholderText
    property string staticText: ""
    property string dynamicText
    property bool inputIsValid: true
    property string infoTipText
    property bool isPersistent: true

    property real fontPointSize: JamiTheme.materialLineEditPointSize
    property bool fontBold: false

    property int echoMode: TextInput.Normal

    // Always start with the static text component displayed first.
    property bool editMode: true

    // Emitted when the editor has been accepted.
    signal accepted

    // Always give up focus when accepted.
    onAccepted: focus = false

    // Needed to give proper focus to loaded item
    onFocusChanged: {
        if (root.focus && root.isPersistent) {
            item.forceActiveFocus()
        }
    }

    // This is used when the user is not editing the text.
    Component {

        id: displayComp
        MaterialTextField {

            font.pointSize: root.fontPointSize
            readOnly: true
            text: staticText
            horizontalAlignment: TextEdit.AlignHCenter
        }
    }

    // This is used when the user is editing the text.
    Component {
        id: editComp

        MaterialTextField {

            id: editCompField

            focus: true
            infoTipText: root.infoTipText
            prefixIconSrc: root.prefixIconSrc
            prefixIconColor: root.prefixIconColor
            suffixIconSrc: root.suffixIconSrc
            suffixIconColor: root.suffixIconColor
            suffixBisIconSrc: root.suffixBisIconSrc
            suffixBisIconColor: root.suffixBisIconColor
            font.pointSize: root.fontPointSize
            font.bold: root.fontBold
            echoMode: root.echoMode
            placeholderText: root.placeholderText
            onAccepted: root.accepted()
            onTextChanged: dynamicText = text
            onVisibleChanged: text = dynamicText
            inputIsValid: root.inputIsValid
            onFocusChanged: if (!focus) root.editMode = false
        }
    }

    // We use a loader to switch between the two components depending on the
    // editMode property.
    sourceComponent: {

        editMode || isPersistent
                ? editComp
                : displayComp
    }

}
