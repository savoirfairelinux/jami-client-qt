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
import QtQuick.Controls.impl
import QtQuick.Templates as T

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
T.Button {
    id: root

    property bool filledButton: filledButton || (!outlinedButton && !textButton)
    property bool outlinedButton: false // Outlined
    property bool textButton: false // Text

    property color color: JamiTheme.buttonTintedBlue
    property string iconSource: ""
    property string toolTipText: ""

    property bool validFocusReason: focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: JamiTheme.newMaterialButtonHeight

    padding: JamiTheme.newMaterialButtonPadding
    horizontalPadding: JamiTheme.newMaterialButtonHorizontalPadding
    spacing: JamiTheme.newMaterialButtonSpacing

    icon.source: root.iconSource
    icon.width: JamiTheme.iconButtonMedium
    icon.height: JamiTheme.iconButtonMedium
    icon.color: {
        if (root.enabled && (root.hovered || (root.activeFocus && validFocusReason))) {
            if (root.filledButton)
                JamiTheme.whiteColor;
            else if (root.outlinedButton)
                JamiTheme.whiteColor;
            else if (root.textButton)
                JamiTheme.whiteColor;
        } else {
            if (root.filledButton)
                JamiTheme.whiteColor;
            else if (root.outlinedButton)
                root.color;
            else if (root.textButton)
                JamiTheme.textColor;
        }
    }

    Behavior on icon.color {
        ColorAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    contentItem: IconLabel {
        spacing: root.spacing
        mirrored: root.mirrored
        display: root.display

        icon: root.icon
        text: root.text
        font.pixelSize: JamiTheme.buttontextFontPixelSize
        color: {
            if (root.enabled && (root.hovered || (root.activeFocus && validFocusReason))) {
                if (root.filledButton)
                    JamiTheme.whiteColor;
                else if (root.outlinedButton)
                    JamiTheme.whiteColor;
                else if (root.textButton)
                    JamiTheme.whiteColor;
            } else {
                if (root.filledButton)
                    JamiTheme.whiteColor;
                else if (root.outlinedButton)
                    root.color;
                else if (root.textButton)
                    JamiTheme.textColor;
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    background: Rectangle {
        id: background

        radius: height / 2

        color: {
            if (root.enabled) {
                if (root.pressed || root.down) {
                    Qt.rgba(root.color.r, root.color.g, root.color.b, 0.80);
                } else if (root.hovered || (root.activeFocus && validFocusReason)) {
                    Qt.rgba(root.color.r, root.color.g, root.color.b, 0.92);
                } else{
                    if (root.filledButton)
                        root.color;
                    else if (root.outlinedButton)
                        JamiTheme.transparentColor;
                    else if (root.textButton)
                        JamiTheme.transparentColor;
                }
            } else {
                Qt.rgba(root.color.r, root.color.g, root.color.b, 0.64);
            }
        }

        border.width: root.outlinedButton ? 1.0 : 0.0
        border.color: root.color

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    MaterialToolTip {
        id: toolTip

        parent: root
        text: toolTipText
        visible: hovered && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    MouseArea {
        anchors.fill: parent

        // We don't want to eat clicks on the Text.
        acceptedButtons: Qt.NoButton
        cursorShape: (root.hovered && root.enabled) ? Qt.PointingHandCursor : Qt.ArrowCursor
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
