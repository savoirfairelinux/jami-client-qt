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
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 10

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
        color: {
            if (root.pressed || root.highlighted)
                return JamiTheme.smartListSelectedColor;
            else if (root.hovered)
                return JamiTheme.smartListHoveredColor;
            else
                return "transparent";
        }
    }

    highlighted: {
        return mainMenu.selectedUids.includes(UID);
    }

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
