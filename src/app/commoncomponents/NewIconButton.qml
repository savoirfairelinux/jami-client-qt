/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import net.jami.Constants 1.1

/* NOTE: This is a high-level imlpementation of the icon button.
 *      Use the standard fixed button size (extra small, small, medium, large, extra large)
 *      as found in the buttonSize enum in JamiTheme. If using a custom size,
 *      add a comment explaining why.
 */
Button {
    id: root

    property int buttonSize
    property string iconSource
    property alias toolTipText: iconButtonToolTip.text
    property alias toolTipShortcutKey: iconButtonToolTip.shortcutKey

    width: background.width
    height: background.height

    // Defines the size of the icon itself,
    // this should be smaller than the button itself (i.e. the background)
    icon.width: {
        switch (buttonSize) {
        case JamiTheme.ButtonSizes.ExtraSmall:
            JamiTheme.iconExtraSmall
            break;
        case JamiTheme.ButtonSizes.Small:
            JamiTheme.iconSmall
            break;
        case JamiTheme.ButtonSizes.Medium:
            JamiTheme.iconMedium
            break
        case JamiTheme.ButtonSizes.Large:
            JamiTheme.iconLarge
            break;
        case JamiTheme.ButtonSizes.ExtraLarge:
            JamiTheme.iconExtraLarge
            break;
        default:
            JamiTheme.iconMedium
            break;
        }
    }
    icon.height: {
        switch (buttonSize) {
        case JamiTheme.ButtonSizes.ExtraSmall:
            JamiTheme.iconExtraSmall
            break;
        case JamiTheme.ButtonSizes.Small:
            JamiTheme.iconSmall
            break;
        case JamiTheme.ButtonSizes.Medium:
            JamiTheme.iconMedium
            break
        case JamiTheme.ButtonSizes.Large:
            JamiTheme.iconLarge
            break;
        case JamiTheme.ButtonSizes.ExtraLarge:
            JamiTheme.iconExtraLarge
            break;
        default:
            JamiTheme.iconMedium
            break;
        }
    }
    icon.color: enabled ? hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered : JamiTheme.buttonTintedGreyHovered
    icon.source: iconSource

    Behavior on icon.color {
        enabled: root.enabled
        ColorAnimation {
            duration: 200
        }
    }


    background: Rectangle {
        anchors.centerIn: contentItem

        // Defines the actual sizing of the button
        // This should be larger than the icons
        width: {
            switch (buttonSize) {
            case JamiTheme.ButtonSizes.ExtraSmall:
                JamiTheme.iconButtonExtraSmall
                break;
            case JamiTheme.ButtonSizes.Small:
                JamiTheme.iconButtonSmall
                break;
            case JamiTheme.ButtonSizes.Medium:
                JamiTheme.iconButtonMedium
                break
            case JamiTheme.ButtonSizes.Large:
                JamiTheme.iconButtonLarge
                break;
            case JamiTheme.ButtonSizes.ExtraLarge:
                JamiTheme.iconButtonExtraLarge
                break;
            default:
                JamiTheme.iconButtonMedium
                break;
            }
        }
        height: {
            switch (buttonSize) {
            case JamiTheme.ButtonSizes.ExtraSmall:
                JamiTheme.iconButtonExtraSmall
                break;
            case JamiTheme.ButtonSizes.Small:
                JamiTheme.iconButtonSmall
                break;
            case JamiTheme.ButtonSizes.Medium:
                JamiTheme.iconButtonMedium
                break
            case JamiTheme.ButtonSizes.Large:
                JamiTheme.iconButtonLarge
                break;
            case JamiTheme.ButtonSizes.ExtraLarge:
                JamiTheme.iconButtonExtraLarge
                break;
            default:
                JamiTheme.iconButtonMedium
                break;
            }
        }

        radius: height / 2

        color: JamiTheme.hoveredButtonColor

        opacity: root.hovered ? 1.0 : 0.0

        visible: root.enabled

        Behavior on opacity {
            enabled: root.enabled
            NumberAnimation {
                duration: 200
            }
        }
    }

    MaterialToolTip {
        id: iconButtonToolTip

        parent: root

        hasShortcut: shortcutKey.length > 0

        visible: root.enabled && (root.hovered || root.activeFocus) && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    Accessible.role: Accessible.Button
    Accessible.name: iconButtonToolTip.text
}
