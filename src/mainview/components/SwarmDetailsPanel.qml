/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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
import Qt.labs.platform

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../settingsview/components"

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
                inverted: true

                Layout.topMargin: JamiTheme.swarmDetailsPageTopMargin
                Layout.bottomMargin: JamiTheme.preferredMarginSize
                Layout.alignment: Qt.AlignHCenter

                newConversation: true
                imageId: LRCInstance.selectedConvUid
                avatarSize: JamiTheme.smartListAvatarSize
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
                placeholderTextColor: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                tooltipText: JamiStrings.editTitle
                backgroundColor: root.color
                color: UtilsAdapter.luma(backgroundColor) ?
                        JamiTheme.chatviewTextColorLight :
                        JamiTheme.chatviewTextColorDark

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
                placeholderTextColor: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                tooltipText: JamiStrings.editDescription
                backgroundColor: root.color
                color: UtilsAdapter.luma(backgroundColor) ?
                        JamiTheme.chatviewTextColorLight :
                        JamiTheme.chatviewTextColorDark

                onEditingFinished: {
                    ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, descriptionLine.text)
                }
            }

            TabBar {
                id: tabBar

                currentIndex: 1

                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.preferredWidth: root.width
                Layout.preferredHeight: membersTabButton.height

                FilterTabButton {
                    id: aboutTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                            JamiTheme.chatviewTextColorLight :
                            JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 0
                    labelText: JamiStrings.about
                }

                FilterTabButton {
                    id: membersTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                            JamiTheme.chatviewTextColorLight :
                            JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 1
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

                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                            JamiTheme.chatviewTextColorLight :
                            JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 2
                    labelText: JamiStrings.documents
                }*/
            }
        }

        ColorDialog {
            id: colorDialog
            title: JamiStrings.chooseAColor
            onAccepted: {
                console.warn("TODO SAVE preference")
                CurrentConversation.color = colorDialog.color
            }
        }

        Rectangle {
            id: details
            Layout.fillWidth: true
            Layout.preferredHeight: root.height - header.height
            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                id: aboutSwarm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: JamiTheme.settingsMarginSize
                spacing: JamiTheme.preferredMarginSize
                visible: tabBar.currentIndex === 0
                Layout.alignment: Qt.AlignTop

                ToggleSwitch {
                    id: ignoreSwarm

                    Layout.fillWidth: true
                    Layout.leftMargin: JamiTheme.preferredMarginSize
                    Layout.topMargin: JamiTheme.preferredMarginSize

                    checked: false // TODO

                    labelText: JamiStrings.ignoreTheSwarm
                    fontPointSize: JamiTheme.settingsFontSize

                    tooltipText: JamiStrings.ignoreTheSwarmTooltip

                    onSwitchToggled: {
                        // TODO
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                    Text {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: JamiTheme.preferredMarginSize
                        text: JamiStrings.leaveTheSwarm
                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor
                    }

                    color: "transparent"

                    HoverHandler {
                        target: parent
                        enabled: parent.visible
                        onHoveredChanged: {
                            parent.color = hovered ? Qt.darker(JamiTheme.selectedColor, 1.05) : "transparent"
                        }
                    }

                    TapHandler {
                        target: parent
                        enabled: parent.visible
                        onTapped: function onTapped(eventPoint) {
                            MessagesAdapter.removeConversation(LRCInstance.selectedConvUid)
                        }
                    }
                }

                RowLayout {
                    Layout.leftMargin: JamiTheme.preferredMarginSize

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        Layout.rightMargin: JamiTheme.preferredMarginSize

                        text: JamiStrings.chooseAColor
                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor
                    }

                    Rectangle {
                        id: chooseAColorBtn

                        Layout.alignment: Qt.AlignRight

                        width: JamiTheme.aboutBtnSize
                        height: JamiTheme.aboutBtnSize
                        radius: JamiTheme.aboutBtnSize / 2

                        color: CurrentConversation.color

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: colorDialog.open()
                        }
                    }
                }


                RowLayout {
                    Layout.leftMargin: JamiTheme.preferredMarginSize

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        Layout.rightMargin: JamiTheme.preferredMarginSize

                        text: JamiStrings.typeOfSwarm
                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor
                    }

                    Label {
                        id: typeOfSwarmLabel

                        Layout.alignment: Qt.AlignRight

                        color: JamiTheme.buttonTintedBlack

                        text: CurrentConversation.modeString
                    }
                }
            }

            JamiListView {
                id: members
                anchors.fill: parent
                anchors.topMargin: JamiTheme.preferredMarginSize

                visible: tabBar.currentIndex === 1

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
                delegate: ItemDelegate {
                    id: member
                    width: members.width
                    height: JamiTheme.smartListItemHeight

                    background: Rectangle {
                        anchors.fill: parent
                        color: {
                            if (member.hovered)
                                return Qt.darker(JamiTheme.selectedColor, 1.05)
                            else
                                return "transparent"
                        }
                    }

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
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
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
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2

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
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2

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
