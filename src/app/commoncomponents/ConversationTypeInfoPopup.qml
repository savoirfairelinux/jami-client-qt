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

BaseModalDialog {
    id: root

    property bool isFeed: false

    button1.text: JamiStrings.close
    button1Role: DialogButtonBox.RejectRole
    button1.onClicked: close()

    popupContent: ColumnLayout {
        objectName: "conversationTypeInfoContent"

        width: 400 - 2 * root.popupMargins
        spacing: 16
        activeFocusOnTab: true

        InfoRow {
            id: typeInfo
            objectName: "conversationTypeInfo"

            iconSource: root.isFeed ? JamiResources.feed_24dp_svg : JamiResources.groups_3_24dp_svg
            infoText: root.isFeed
                      ? qsTr("A feed is a conversation for sharing updates with its members.")
                      : qsTr("A group is a conversation for multiple people.")
        }

        InfoRow {
            id: publishingInfo
            objectName: "conversationPublishingInfo"

            iconSource: root.isFeed ? JamiResources.moderator_filled_24dp_svg : JamiResources.attached_file_24dp_svg
            infoText: root.isFeed
                      ? qsTr("Only you can send new messages.")
                      : qsTr("Members can send messages and share files with each other.")
        }

        InfoRow {
            id: membersInfo
            objectName: "conversationMembersInfo"

            iconSource: root.isFeed ? JamiResources.bidirectional_reply_black_24dp_svg : JamiResources.person_add_24dp_svg
            infoText: root.isFeed
                      ? qsTr("Members can reply and react to messages you send.")
                      : qsTr("Choose the people you want to invite when creating the group. You can add more members later.")
        }

        Accessible.role: Accessible.StaticText
        Accessible.description: typeInfo.infoText + " " + publishingInfo.infoText + " " + membersInfo.infoText
    }
}
