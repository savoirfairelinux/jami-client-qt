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
import QtQuick.Controls
import QtQuick.Controls.impl

import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

/* NOTE: This is a high-level imlpementation of the icon button.
 *      Use the standard fixed icon button size (small, medium, large, extra large)
 *      as found in JamiTheme. If using a custom size, add a comment
 *      explaining why.
 */
Button {
    id: root

    property int iconSize
    property string iconSource

    property alias toolTipText: iconButtonToolTip.text
    property alias toolTipShortcutKey: iconButtonToolTip.shortcutKey

    property bool canMirror: JamiResources.mirroredIcons.includes(iconSource)

    focusPolicy: Qt.TabFocus

    Connections {
        target: UtilsAdapter
        function onChangeLanguage() {
            // Exceptions:
            // - Question marks in Hebrew are written the same way as in LTR langauges
            if (UtilsAdapter.getAppValue(Settings.Key.LANG) === "he" && iconSource === JamiResources.bidirectional_help_outline_24dp_svg) {
                canMirror = false;
            } else {
                canMirror = JamiResources.mirroredIcons.includes(iconSource);
            }
        }
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    leftPadding: iconSize / 4
    rightPadding: iconSize / 4
    topPadding: iconSize / 4
    bottomPadding: iconSize / 4

    contentItem: IconImage {
        id: iconImage
        anchors.centerIn: parent

        width: root.iconSize
        height: root.iconSize

        source: root.iconSource
        sourceSize.width: root.iconSize
        sourceSize.height: root.iconSize

        color: {
            if (root.enabled) {
                if (root.hovered || root.checked) {
                    return JamiTheme.textColor;
                } else {
                    return JamiTheme.buttonTintedGreyHovered;
                }
            } else {
                return JamiTheme.buttonTintedGreyHovered;
            }
        }

        mirror: root.mirrored && root.canMirror

        Behavior on color {
            enabled: root.enabled
            ColorAnimation {
                duration: 200
            }
        }
    }

    background: Rectangle {
        visible: root.enabled

        implicitWidth: iconSize + (iconSize / 2)
        implicitHeight: iconSize + (iconSize / 2)

        radius: height / 2

        opacity: root.hovered || root.checked ? 1.0 : 0.0

        color: root.pressed ? JamiTheme.pressedButtonColor : JamiTheme.hoveredButtonColor

        Behavior on opacity {
            enabled: root.enabled
            NumberAnimation {
                duration: 200
            }
        }

        Behavior on color {
            ColorAnimation {
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
