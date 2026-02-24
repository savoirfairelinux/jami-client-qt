/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

NewMaterialTextField {
    id: root

    property bool firstEntry: false
    property bool showPassword: false

    leadingIconSource: firstEntry ? JamiResources.lock_svg : JamiResources.password_24dp_svg

    placeholderText: JamiStrings.password
    toolTipText: firstEntry ? JamiStrings.password : ""
    textFieldContent: ""
    echoMode: showPassword ? TextInput.Normal : TextInput.Password

    trailingIconSource: showPassword ? JamiResources.noun_eye_svg : JamiResources.eye_cross_svg
    onTrailingIconClicked: showPassword = !showPassword
}
