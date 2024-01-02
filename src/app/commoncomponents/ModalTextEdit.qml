/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

// This component is used to display and edit a value.
Loader {
    id: root
    property string prefixIconSrc: JamiResources.round_edit_24dp_svg
    property color prefixIconColor: JamiTheme.editLineColor
    property string suffixIconSrc: ""
    property color suffixIconColor: JamiTheme.buttonTintedBlue
    property string suffixBisIconSrc: ""
    property color suffixBisIconColor: JamiTheme.buttonTintedBlue
    property color textColor: JamiTheme.textColor

    required property string placeholderText
    property string staticText: ""
    property string dynamicText

    property bool inputIsValid: true
    property string infoTipText
    property string infoTipLineText
    property bool isPersistent: true

    property string elidedText: ""
    property int maxCharacters

    property real fontPixelSize: JamiTheme.materialLineEditPixelSize
    property bool fontBold: false

    property int echoMode: TextInput.Normal
    property QtObject textValidator: RegularExpressionValidator {
        id: defaultValidator
    }

    property var icon
    property bool isSettings
    property bool isSwarmDetail

    property bool readOnly: false
    property bool isEditing: false

    onStatusChanged: {
        if (status == Loader.Ready && icon)
            root.item.icon = icon;
    }

    // Always start with the static text component displayed first.
    property bool editMode: true

    // Emitted when the editor has been accepted.
    signal accepted
    signal keyPressed

    signal activeChanged(bool active)

    // Always give up focus when accepted.
    onAccepted: focus = false

    // Needed to give proper focus to loaded item
    onFocusChanged: {
        if (item && root.focus && root.isPersistent) {
            item.forceActiveFocus();
        }
        isEditing = !isEditing;
    }

    // This is used when the user is not editing the text.
    Component {
        id: displayComp

        MaterialTextField {
            id: displayCompField

            font.pixelSize: root.fontPixelSize
            readOnly: root.readOnly
            text: elidedText != "" ? elidedText : staticText
            horizontalAlignment: elidedText != "" ? TextEdit.AlignLeft : TextEdit.AlignHCenter
            isSwarmDetail: root.isSwarmDetail
            isSettings: root.isSettings
            textColor: root.textColor
            suffixBisIconSrc: root.suffixBisIconSrc
            suffixBisIconColor: root.suffixBisIconColor
            placeholderText: root.placeholderText
            prefixIconSrc: isSwarmDetail ? "" : root.prefixIconSrc
            prefixIconColor: root.prefixIconColor
        }
    }

    // This is used when the user is editing the text.
    Component {
        id: editComp

        MaterialTextField {
            id: editCompField

            focus: true
            infoTipText: root.infoTipText
            infoTipLineText: root.infoTipLineText
            prefixIconSrc: root.prefixIconSrc
            prefixIconColor: root.prefixIconColor
            suffixIconSrc: root.suffixIconSrc
            suffixIconColor: root.suffixIconColor
            suffixBisIconSrc: root.suffixBisIconSrc
            suffixBisIconColor: root.suffixBisIconColor
            textColor: root.textColor
            font.pixelSize: root.fontPixelSize
            font.bold: root.fontBold
            echoMode: root.echoMode
            placeholderText: root.placeholderText
            onAccepted: root.accepted()
            onRejected: {
                root.editMode = false;
                text = staticText;
            }
            onKeyPressed: root.keyPressed()
            onTextChanged: dynamicText = text
            text: staticText
            inputIsValid: root.inputIsValid
            onFocusChanged: {
                if (!focus && root.editMode) {
                    root.editMode = isPersistent;
                }
                activeChanged(root.editMode);
            }
            onIsActiveChanged: activeChanged(isActive)
            validator: root.textValidator
            isSettings: root.isSettings
            isSwarmDetail: root.isSwarmDetail
            readOnly: root.readOnly
            maxCharacters: root.maxCharacters
        }
    }

    // We use a loader to switch between the two components depending on the
    // editMode property.
    sourceComponent: {
        editMode || isPersistent ? editComp : displayComp;
    }
}
