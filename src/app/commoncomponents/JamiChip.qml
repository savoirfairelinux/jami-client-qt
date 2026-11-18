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

import net.jami.Constants 1.1

Control {
    id: root

    // The chip will default to the filled version unless
    // outlinedChip is enabled specifically
    property bool filledChip: !outlinedChip
    property bool outlinedChip: false

    property color color: JamiTheme.tintedBlue

    property alias text: chipText.text
    property string iconSource: ""
    signal iconClicked

    property string toolTipText: ""
    property string iconButtonToolTipText: ""
    property string avatarId: ""
    property real maximumWidth: -1

    leftPadding: background.radius - (avatar.height / 2)
    rightPadding: background.radius - (trailingIconButton.height / 2)
    topPadding: JamiTheme.jamiChipVerticalPadding
    bottomPadding: JamiTheme.jamiChipVerticalPadding

    activeFocusOnTab: true

    scale: root.hovered || root.activeFocus ? JamiTheme.jamiChipHoveredScaleValue : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    contentItem: Row {
        id: chipContent

        spacing: 2

        Avatar {
            id: avatar

            anchors.verticalCenter: parent.verticalCenter

            width: 24
            height: 24

            visible: root.avatarId.length > 0
            mode: Avatar.Mode.Conversation
            imageId: root.avatarId
            showPresenceIndicator: false
        }

        Text {
            id: chipText

            anchors.verticalCenter: parent.verticalCenter

            width: {
                if (root.maximumWidth < 0)
                    return implicitWidth;
                const avatarSpace = avatar.visible ? avatar.width + chipContent.spacing : 0;
                const iconSpace = trailingIconButton.visible ? trailingIconButton.width + chipContent.spacing : 0;
                return Math.max(0, Math.min(implicitWidth, root.maximumWidth - root.leftPadding
                                            - root.rightPadding - avatarSpace - iconSpace));
            }

            color: {
                if (root.filledChip) {
                    return JamiTheme.whiteColor;
                } else if (root.outlinedChip) {
                    if (root.hovered || root.activeFocus) {
                        return JamiTheme.whiteColor;
                    } else {
                        return root.color;
                    }
                }
            }

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

            anchors.verticalCenter: parent.verticalCenter

            padding: 0
            horizontalPadding: 0

            icon.source: root.iconSource
            icon.color: {
                if (root.filledChip) {
                    return JamiTheme.whiteColor;
                } else if (root.outlinedChip) {
                    if (root.hovered || root.activeFocus) {
                        return JamiTheme.whiteColor;
                    } else {
                        return root.color;
                    }
                }
            }
            Behavior on icon.color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }

            scale: trailingIconButton.hovered || trailingIconButton.activeFocus ? JamiTheme.jamiChipIconButtonHoveredScaleValue : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }

            visible: iconSource !== ""

            background: null

            onClicked: root.iconClicked()

            MaterialToolTip {
                id: iconButtonToolTipText

                parent: parent
                text: root.iconButtonToolTipText
                visible: (trailingIconButton.hovered || trailingIconButton.activeFocus) && (text.length > 0)
                delay: Qt.styleHints.mousePressAndHoldInterval
            }

            Accessible.role: Accessible.Button
            Accessible.name: iconButtonToolTipText.text
        }
    }

    background: Rectangle {
        radius: height / 2

        color: {
            if (root.filledChip) {
                return root.color;
            } else if (root.outlinedChip) {
                if (root.hovered || root.activeFocus) {
                    return Qt.rgba(root.color.r, root.color.g, root.color.b, 0.92);
                } else {
                    return Qt.rgba(root.color.r, root.color.g, root.color.b, 0);
                }
            }
        }

        border.color: JamiTheme.tintedBlue
        border.width: root.outlinedChip ? 1 : 0

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    MaterialToolTip {
        id: toolTip

        parent: root
        text: root.toolTipText
        visible: (root.hovered || root.activeFocus) && (root.toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: root.text
}
