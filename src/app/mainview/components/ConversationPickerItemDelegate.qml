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
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    width: ListView.view.width
    height: JamiTheme.smartListItemHeight

    RowLayout {
        id: rowLayout

        anchors.fill: contentRect
        anchors.margins: JamiTheme.itemPadding

        spacing: 16

        ConversationAvatar {
            id: avatar
            objectName: "smartlistItemDelegateAvatar"

            imageId: UID
            presenceStatus: Presence
            showPresenceIndicator: Presence !== undefined ? Presence : false

            Layout.preferredWidth: JamiTheme.smartListAvatarSize
            Layout.preferredHeight: JamiTheme.smartListAvatarSize

            Rectangle {
                id: overlayHighlighted
                visible: highlighted

                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                radius: JamiTheme.smartListAvatarSize / 2

                Image {
                    id: highlightedImage

                    width: JamiTheme.smartListAvatarSize / 2
                    height: JamiTheme.smartListAvatarSize / 2
                    anchors.centerIn: parent

                    layer {
                        enabled: true
                        effect: ColorOverlay {
                            color: "white"
                        }
                    }
                    source: JamiResources.check_black_24dp_svg
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // best name
            Text {
                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideMiddle
                text: Title === undefined ? "" : Title
                textFormat: TextEdit.PlainText
                font.pointSize: JamiTheme.mediumFontSize
                font.weight: UnreadMessagesCount ? Font.Bold : Font.Normal
                color: JamiTheme.textColor
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignVCenter
                text: JamiStrings.blocked
                textFormat: TextEdit.PlainText
                visible: IsBanned
                font.pointSize: JamiTheme.mediumFontSize
                font.weight: Font.Bold
                color: JamiTheme.textColor
            }
        }

        Accessible.role: Accessible.Button
        Accessible.name: Title === undefined ? "" : Title
    }

    background: Rectangle {
        id: contentRect

        anchors.fill: root
        anchors.topMargin: JamiTheme.itemMarginVertical
        anchors.bottomMargin: JamiTheme.itemMarginVertical
        anchors.leftMargin: JamiTheme.itemMarginHorizontal
        anchors.rightMargin: JamiTheme.itemMarginHorizontal

        radius: JamiTheme.commonRadius

        color: JamiTheme.backgroundColor
    }

    highlighted: {
        return mainMenu.selectedUids.includes(UID);
    }

    states: [
        State {
            name: "normal"
            when: !highlighted && !hovered
            PropertyChanges {
                target: contentRect
                color: JamiTheme.globalIslandColor
            }
            PropertyChanges {
                target: root
                scale: 1.0
            }
        },
        State {
            name: "hovered"
            when: root.activeFocus || (!highlighted && hovered)
            PropertyChanges {
                target: contentRect
                color: JamiTheme.smartListHoveredColor
            }
            PropertyChanges {
                target: root
                scale: ListView.view.width / contentRect.width
            }
        },
        State {
            name: "highlighted"
            when: (highlighted && !hovered) || (highlighted && hovered)
            PropertyChanges {
                target: contentRect
                color: JamiTheme.smartListSelectedColor
            }
            PropertyChanges {
                target: root
                scale: 1.0
            }
        }
    ]

    // Animations within a transition run in parallel
    transitions: [
        Transition {
            from: "normal"
            to: "hovered"
            reversible: true
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
            NumberAnimation {
                target: root
                property: "scale"
                duration: JamiTheme.shortFadeDuration
                easing.type: Easing.OutCubic
            }
        },
        Transition {
            from: "highlighted"
            to: "normal"
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        },
        Transition {
            from: "hovered"
            to: "highlighted"

            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
            NumberAnimation {
                target: root
                property: "scale"
                duration: JamiTheme.shortFadeDuration - 50
                easing.type: Easing.OutCubic
            }
        }
    ]

    onClicked: {
        const currentSelectedUids = mainMenu.selectedUids;
        if (currentSelectedUids.includes(UID)) {
            mainMenu.selectedUids = currentSelectedUids.filter(uid => uid !== UID);
        } else {
            mainMenu.selectedUids = currentSelectedUids.concat(UID);
        }
        return;
    }
}
