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
import QtQuick.Layouts

import net.jami.Constants 1.1

Control {
    id: root

    enum Variant {
        Filled,
        Outlined,
        Neutral
    }

    property int variant: JamiChip.Variant.Filled
    property color color: JamiTheme.tintedBlue

    property alias text: chipText.text
    property string avatarId: ""
    property alias avatarMode: avatar.mode
    property string iconSource: ""
    property string toolTipText: ""
    property string iconButtonToolTipText: ""
    signal iconClicked

    readonly property bool neutral: variant === JamiChip.Variant.Neutral
    readonly property bool outlined: variant === JamiChip.Variant.Outlined
    readonly property bool highlighted: hovered || activeFocus
    readonly property color contentColor: {
        if (neutral)
            return JamiTheme.textColor;
        if (outlined && !highlighted)
            return color;
        return JamiTheme.whiteColor;
    }

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    leftPadding: avatar.visible ? 4 : 8
    rightPadding: trailingIconButton.visible ? 4 : 8
    verticalPadding: JamiTheme.jamiChipVerticalPadding

    activeFocusOnTab: true

    scale: highlighted && !neutral ? JamiTheme.jamiChipHoveredScaleValue : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    contentItem: RowLayout {
        spacing: 4

        Avatar {
            id: avatar

            mode: Avatar.Mode.Conversation

            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            visible: root.avatarId !== ""
            imageId: root.avatarId
            showPresenceIndicator: false
        }

        Text {
            id: chipText

            Layout.fillWidth: true

            color: root.contentColor
            elide: Text.ElideRight
            textFormat: Text.PlainText
            verticalAlignment: Text.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        Button {
            id: trailingIconButton

            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            visible: root.iconSource !== ""
            padding: 0
            background: null

            icon.source: root.iconSource
            icon.color: root.neutral ? root.withAlpha(root.contentColor, hovered || activeFocus ? 0.9 : 0.6) : root.contentColor
            Behavior on icon.color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }

            scale: (hovered || activeFocus) && !root.neutral ? JamiTheme.jamiChipIconButtonHoveredScaleValue : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }

            onClicked: root.iconClicked()

            MaterialToolTip {
                parent: trailingIconButton
                text: root.iconButtonToolTipText
                visible: (trailingIconButton.hovered || trailingIconButton.activeFocus) && text.length > 0
                delay: Qt.styleHints.mousePressAndHoldInterval
            }

            Accessible.role: Accessible.Button
            Accessible.name: root.iconButtonToolTipText
        }
    }

    background: Rectangle {
        radius: height / 2

        color: {
            if (root.neutral)
                return root.withAlpha(JamiTheme.textColor, (JamiTheme.darkTheme ? 0.16 : 0.08) + (root.highlighted ? 0.06 : 0));
            if (root.outlined)
                return root.withAlpha(root.color, root.highlighted ? 0.92 : 0);
            return root.color;
        }

        border.color: root.color
        border.width: root.outlined ? 1 : 0

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    MaterialToolTip {
        parent: root
        text: root.toolTipText
        visible: root.highlighted && text.length > 0
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: root.text
}
