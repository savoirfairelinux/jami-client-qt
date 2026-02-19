/*
* Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1

NewMaterialButton {
    id: root

    property bool spinnerTriggered: false
    property string spinnerTriggeredtext: value
    property string normalText: value

    implicitHeight: JamiTheme.newMaterialButtonSetupHeight

    iconSource: spinnerTriggered ? JamiResources.jami_rolling_spinner_gif : ""
    text: spinnerTriggered ? spinnerTriggeredtext : normalText
    color: !enabled ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBlue

    hoverEnabled: enabled
}
