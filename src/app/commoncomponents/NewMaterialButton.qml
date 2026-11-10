/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import Jami as JamiStyle

import net.jami.Constants 1.1

/*
 * This new button is meant to match the Material 3 design
 * as close as possible, while using the Jami colour scheme.
 *
 * There are three buttons available: Filled, Outlined, Text.
 * Filled: Text with a solid fill colour.
 * Outlined: Text with with a thin border, but no fill colour.
 * Text: Text only. No filled colour or border.
 *
 * Specify the type of button to be displayed (default Filled).
 *
 * The component presents both hovered and pressed states by
 * modifiying the colours opacity.
 *
 * Reference: https://m3.material.io/components/buttons/overview
 */
JamiStyle.Button {
    id: root

    property bool filledButton: !outlinedButton && !textButton
    property bool outlinedButton: false // Outlined
    property bool textButton: false // Text

    property color color: JamiTheme.buttonTintedBlue
    property alias iconSource: root.icon.source
    property string toolTipText: ""

    property bool validFocusReason: focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason

    flat: !filledButton
    palette.button: root.color
    palette.buttonText: filledButton ? JamiTheme.whiteColor : outlinedButton ? root.color : JamiTheme.textColor
    palette.mid: outlinedButton ? root.color : JamiTheme.transparentColor

    MaterialToolTip {
        id: toolTip

        parent: root
        text: toolTipText
        visible: hovered && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            clicked();
            keyEvent.accepted = true;
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.description: toolTipText
}
