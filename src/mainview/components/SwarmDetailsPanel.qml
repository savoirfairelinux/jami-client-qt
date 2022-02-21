/*
 * Copyright (C) 2022 by Savoir-faire Linux
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

    color: CurrentConversation.color

    ColumnLayout {
        id: swarmProfileDetails
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 0

        ColumnLayout {
            id: header
            Layout.fillWidth: true
            spacing: 0

            PhotoboothView {
                id: currentAccountAvatar

                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: JamiTheme.swarmDetailsPageTopMargin
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                newConversation: true
                imageId: LRCInstance.selectedConvUid
                avatarSize: JamiTheme.avatarSizeInCall
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
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                font.pointSize: JamiTheme.menuFontSize

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

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

                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.preferredWidth: root.width
                Layout.preferredHeight: membersTabButton.height

                /*FilterTabButton {
                    id: aboutTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    down: tabBar.currentIndex === 0
                    labelText: JamiStrings.about
                }*/

                FilterTabButton {
                    id: membersTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    down: true//tabBar.currentIndex === 1
                    labelText: {
                        var membersNb = CurrentConversation.uris.length;
                        if (membersNb > 1)
                            return JamiStrings.members.arg(membersNb)
                        return JamiStrings.member
                    }
                }

                /*FilterTabButton {
                    id: documentsTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    down: tabBar.currentIndex === 2
                    labelText: JamiStrings.documents
                }*/
            }
        }

        Rectangle {
            id: details
            Layout.fillWidth: true
            Layout.preferredHeight: root.height - header.height
            color: JamiTheme.secondaryBackgroundColor

            JamiListView {
                id: members
                anchors.fill: parent
                spacing: JamiTheme.preferredMarginSize
                anchors.topMargin: JamiTheme.preferredMarginSize

                SwarmParticipantContextMenu {
                    id: contextMenu
                    role: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri)

                    function openMenuAt(x, y, participantUri) {
                        contextMenu.x = x
                        contextMenu.y = y
                        contextMenu.conversationId = CurrentConversation.id
                        contextMenu.participantUri = participantUri

                        openMenu()
                    }
                }

                model: CurrentConversation.uris
                delegate: Item {

                    width: members.width
                    height: JamiTheme.smartListItemHeight

                    MouseArea {
                        anchors.fill: parent
                        enabled: modelData != CurrentAccount.uri
                        acceptedButtons: Qt.RightButton
                        onClicked: function (mouse) {
                            contextMenu.openMenuAt(x + mouse.x, y + mouse.y, modelData)
                        }
                    }

                    RowLayout {
                        spacing: 10

                        Avatar {
                            width: JamiTheme.smartListAvatarSize
                            height: JamiTheme.smartListAvatarSize
                            Layout.leftMargin: JamiTheme.preferredMarginSize
                            z: -index
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }

                            imageId: CurrentAccount.uri == modelData ? CurrentAccount.id : modelData
                            showPresenceIndicator: UtilsAdapter.getContactPresence(CurrentAccount.id, modelData)
                            mode: CurrentAccount.uri == modelData ? Avatar.Mode.Account : Avatar.Mode.Contact
                        }

                        ElidedTextLabel {
                            id: bestName

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            eText: UtilsAdapter.getContactBestName(CurrentAccount.id, modelData)
                            maxWidth: JamiTheme.preferredFieldWidth

                            font.pointSize: JamiTheme.participantFontSize
                            color: JamiTheme.primaryForegroundColor
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }
                            font.kerning: true

                            verticalAlignment: Text.AlignVCenter
                        }

                        ElidedTextLabel {
                            id: role

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            eText: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                if (role === Member.Role.ADMIN)
                                    return JamiStrings.administrator
                                if (role === Member.Role.INVITED)
                                    return JamiStrings.invited
                                return ""
                            }
                            maxWidth: JamiTheme.preferredFieldWidth

                            font.pointSize: JamiTheme.participantFontSize
                            color: JamiTheme.textColorHovered
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }
                            font.kerning: true

                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
