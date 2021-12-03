/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    color: JamiTheme.buttonTintedBlue

    ColumnLayout {
        id: swarmProfileDetails
        Layout.fillWidth: true
        Layout.fillHeight: true

        ConversationAvatar {
            id: conversationAvatar

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: JamiTheme.avatarSizeInCall
            Layout.preferredHeight: JamiTheme.avatarSizeInCall

            imageId: LRCInstance.selectedConvUid

            showPresenceIndicator: false
        }

        EditableLineEdit {
            id: titleLine
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize

            font.pointSize: JamiTheme.titleFontSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: CurrentConversation.title
            placeholderText: JamiStrings.editTitle
            placeholderTextColor: JamiTheme.placeholderTextColorWhite
            tooltipText: JamiStrings.editTitle
            backgroundColor: root.color
            color: "white"

            onEditingFinished: {
                ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, titleLine.text)
            }
        }

        EditableLineEdit {
            id: descriptionLine
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize

            font.pointSize: JamiTheme.titleFontSize

            text: CurrentConversation.description
            placeholderText: JamiStrings.editDescription
            placeholderTextColor: JamiTheme.placeholderTextColorWhite
            tooltipText: JamiStrings.editDescription
            backgroundColor: root.color
            color: "white"

            onEditingFinished: {
                ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, descriptionLine.text)
            }
        }

        TabBar {
            id: tabBar

            currentIndex: 1
            Layout.preferredWidth: root.width

            FilterTabButton {
                id: aboutTabButton

                down: tabBar.currentIndex === 0
                labelText: JamiStrings.about
            }

            FilterTabButton {
                id: membersTabButton

                down: tabBar.currentIndex === 1
                labelText: JamiStrings.members
            }

            FilterTabButton {
                id: documentsTabButton

                down: tabBar.currentIndex === 2
                labelText: JamiStrings.documents
            }
        }

    
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: root.width
            Layout.preferredHeight: root.height
            color: JamiTheme.secondaryBackgroundColor
        }
    }
}
