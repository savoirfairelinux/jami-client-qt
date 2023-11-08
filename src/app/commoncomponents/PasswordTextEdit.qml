/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1

ModalTextEdit {
    id: modalTextEditRoot

    property bool firstEntry: false
    signal icoClicked

    prefixIconSrc: firstEntry ? JamiResources.lock_svg : JamiResources.round_edit_24dp_svg

    suffixBisIconSrc: echoMode == TextInput.Password ? JamiResources.eye_cross_svg : JamiResources.noun_eye_svg
    suffixBisIconColor: JamiTheme.passwordEyeIconColor

    placeholderText: JamiStrings.password
    infoTipText: firstEntry ? JamiStrings.password : ""
    staticText: ""
    echoMode: TextInput.Password

    onIcoClicked: {
        if (echoMode == TextInput.Normal) {
            echoMode = TextInput.Password;
            suffixBisIconSrc = JamiResources.eye_cross_svg;
        } else {
            echoMode = TextInput.Normal;
            suffixBisIconSrc = JamiResources.noun_eye_svg;
        }
    }

    function startEditing() {
        root.editMode = true;
        forceActiveFocus();
    }
}
