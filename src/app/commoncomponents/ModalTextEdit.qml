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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

// This component is used to display and edit a value.
Loader {
    id: root
    property string dynamicText
    property int echoMode: TextInput.Normal

    // Always start with the static text component displayed first.
    property bool editMode: true
    property bool fontBold: false
    property real fontPixelSize: JamiTheme.materialLineEditPixelSize
    property var icon
    property string infoTipLineText
    property string infoTipText
    property bool inputIsValid: true
    property bool isEditing: false
    property bool isPersistent: true
    property bool isSettings
    property bool isSwarmDetail
    required property string placeholderText
    property color prefixIconColor: JamiTheme.editLineColor
    property string prefixIconSrc: JamiResources.round_edit_24dp_svg
    property bool readOnly: false
    property string staticText: ""
    property color suffixBisIconColor: JamiTheme.buttonTintedBlue
    property string suffixBisIconSrc: ""
    property color suffixIconColor: JamiTheme.buttonTintedBlue
    property string suffixIconSrc: ""
    property color textColor: JamiTheme.textColor
    property QtObject textValidator: RegularExpressionValidator {
        id: defaultValidator
    }

    // We use a loader to switch between the two components depending on the
    // editMode property.
    sourceComponent: {
        editMode || isPersistent ? editComp : displayComp;
    }

    // Emitted when the editor has been accepted.
    signal accepted
    signal activeChanged(bool active)
    signal keyPressed

    // Always give up focus when accepted.
    onAccepted: focus = false

    // Needed to give proper focus to loaded item
    onFocusChanged: {
        if (root.focus && root.isPersistent) {
            item.forceActiveFocus();
        }
        isEditing = !isEditing;
    }
    onStatusChanged: {
        if (status == Loader.Ready && icon)
            root.item.icon = icon;
    }

    // This is used when the user is not editing the text.
    Component {
        id: displayComp
        MaterialTextField {
            id: displayCompField
            font.pixelSize: root.fontPixelSize
            horizontalAlignment: TextEdit.AlignHCenter
            readOnly: true
            text: staticText
        }
    }

    // This is used when the user is editing the text.
    Component {
        id: editComp
        MaterialTextField {
            id: editCompField
            echoMode: root.echoMode
            focus: true
            font.bold: root.fontBold
            font.pixelSize: root.fontPixelSize
            infoTipLineText: root.infoTipLineText
            infoTipText: root.infoTipText
            inputIsValid: root.inputIsValid
            isSettings: root.isSettings
            isSwarmDetail: root.isSwarmDetail
            placeholderText: root.placeholderText
            prefixIconColor: root.prefixIconColor
            prefixIconSrc: root.prefixIconSrc
            readOnly: root.readOnly
            suffixBisIconColor: root.suffixBisIconColor
            suffixBisIconSrc: root.suffixBisIconSrc
            suffixIconColor: root.suffixIconColor
            suffixIconSrc: root.suffixIconSrc
            text: staticText
            textColor: root.textColor
            validator: root.textValidator

            onAccepted: root.accepted()
            onFocusChanged: {
                if (!focus && root.editMode) {
                    root.editMode = isPersistent;
                }
                activeChanged(root.editMode);
            }
            onIsActiveChanged: activeChanged(isActive)
            onKeyPressed: root.keyPressed()
            onTextChanged: dynamicText = text
        }
    }
}
