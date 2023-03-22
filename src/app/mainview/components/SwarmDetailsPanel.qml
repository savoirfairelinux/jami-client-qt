/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root

    property alias tabBarIndex: tabBar.currentIndex
    property int tabBarItemsLength: tabBar.contentChildren.length

    color: CurrentConversation.color

    property var isAdmin: UtilsAdapter.getParticipantRole(CurrentAccount.id,
                                        CurrentConversation.id,
                                        CurrentAccount.uri) === Member.Role.ADMIN
                          || CurrentConversation.isCoreDialog

    property string textColor: UtilsAdapter.luma(root.color) ?
                                 JamiTheme.chatviewTextColorLight :
                                 JamiTheme.chatviewTextColorDark

    ColumnLayout {
        id: swarmProfileDetails
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: header
            Layout.topMargin: JamiTheme.swarmDetailsPageTopMargin
            Layout.fillWidth: true
            spacing: JamiTheme.preferredMarginSize

            RowLayout {
                spacing: 15
                Layout.leftMargin: 15

                PhotoboothView {
                    id: currentAccountAvatar

                    readOnly: !root.isAdmin
                    width: avatarSize
                    height: avatarSize

                    Layout.alignment: Qt.AlignHCenter

                    newItem: true
                    imageId: LRCInstance.selectedConvUid
                    avatarSize: JamiTheme.smartListAvatarSize * 3/2
                }

                ColumnLayout {

                    signal accepted

                    ModalTextEdit {
                        id: titleLineButton

                        isSwarmDetail: true
                        enabled: isAdmin

                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        Layout.preferredWidth: 217

                        staticText: CurrentConversation.title

                        textColor: root.textColor
                        prefixIconColor: root.textColor

                        onAccepted: ConversationsAdapter.updateConversationTitle(
                                        LRCInstance.selectedConvUid, dynamicText)

                        onActiveFocusChanged: {
                            if(!activeFocus){
                                ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, dynamicText)
                            }
                        }

                        infoTipLineText: JamiStrings.swarmName
                    }

                    ModalTextEdit {
                        id: descriptionLineButton

                        isSwarmDetail: true
                        enabled: isAdmin

                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        Layout.preferredWidth: 217

                        staticText: CurrentConversation.description
                        placeholderText: JamiStrings.addADescription

                        textColor: root.textColor
                        prefixIconColor: root.textColor

                        onAccepted: ConversationsAdapter.updateConversationDescription(
                                        LRCInstance.selectedConvUid, dynamicText)

                        onActiveFocusChanged: {
                            if(!activeFocus){
                                ConversationsAdapter.updateConversationDescription(
                                            LRCInstance.selectedConvUid, dynamicText)

                            }
                        }

                        infoTipLineText: JamiStrings.addADescription
                    }
                }
            }

            TabBar {
                id: tabBar

                currentIndex: 0

                Layout.preferredWidth: root.width
                Layout.preferredHeight: settingsTabButton.height

                property string currentItemName: itemAt(currentIndex).objectName

                component DetailsTabButton: FilterTabButton {
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true
                    textColorHovered: UtilsAdapter.luma(root.color) ?
                                          JamiTheme.placeholderTextColorWhite :
                                          JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                                   JamiTheme.chatviewTextColorLight :
                                   JamiTheme.chatviewTextColorDark
                    Layout.fillWidth: true
                    down: tabBar.currentIndex === TabBar.index
                }

                function addRemoveButtons() {
                    if (CurrentConversation.isCoreDialog) {
                        if (tabBar.contentChildren.length === 3)
                            tabBar.removeItem(tabBar.itemAt(1))
                    } else {
                        if (tabBar.contentChildren.length === 2) {
                            const obj = membersTabButtonComp.createObject(tabBar)
                            tabBar.insertItem(1, obj)
                        }
                    }
                }

                Component.onCompleted: addRemoveButtons()

                Connections {
                    target: CurrentConversation
                    function onIsCoreDialogChanged() { tabBar.addRemoveButtons() }
                }

                Component {
                    id: membersTabButtonComp
                    DetailsTabButton {
                        id: membersTabButton
                        objectName: "members"
                        visible: !CurrentConversation.isCoreDialog
                        labelText: {
                            var membersNb = CurrentConversationMembers.count;
                            if (membersNb > 1)
                                return JamiStrings.members.arg(membersNb)
                            return JamiStrings.member
                        }
                    }
                }

                DetailsTabButton {
                    id: settingsTabButton
                    objectName: "settings"
                    labelText: JamiStrings.settings
                }

                DetailsTabButton {
                    id: documentsTabButton
                    objectName: "documents"
                    labelText: JamiStrings.documents
                }
            }
        }

        Component {
            id: colorDialogComp
            ColorDialog {
                id: colorDialog
                title: JamiStrings.chooseAColor
                onAccepted: {
                    CurrentConversation.setPreference("color", colorDialog.color)
                    this.destroy()
                }
                onRejected: this.destroy()
            }
        }

        Rectangle {
            id: details
            Layout.fillWidth: true
            Layout.preferredHeight: root.height - header.height - JamiTheme.preferredMarginSize
            color: JamiTheme.secondaryBackgroundColor


            JamiFlickable {
                id: settingsScrollView
                property ScrollBar vScrollBar: ScrollBar.vertical
                anchors.fill: parent

                contentHeight: aboutSwarm.height + JamiTheme.preferredMarginSize

                ColumnLayout {
                    id: aboutSwarm
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: JamiTheme.settingsMarginSize
                    visible: tabBar.currentItemName === "settings"
                    Layout.alignment: Qt.AlignTop

                    SwarmDetailsItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        ToggleSwitch {
                            id: ignoreSwarm

                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize

                            checked: CurrentConversation.ignoreNotifications

                            labelText: JamiStrings.muteConversation
                            fontPointSize: JamiTheme.settingsFontSize

                            tooltipText: JamiStrings.ignoreNotificationsTooltip

                            onSwitchToggled: {
                                CurrentConversation.setPreference("ignoreNotifications", checked ? "true" : "false")
                            }
                        }
                    }

                    SwarmDetailsItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: JamiTheme.preferredMarginSize
                            text: JamiStrings.leaveConversation
                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor
                        }

                        TapHandler {
                            target: parent
                            enabled: parent.visible
                            onTapped: function onTapped(eventPoint) {
                                var dlg = viewCoordinator.presentDialog(
                                            appWindow,
                                            "commoncomponents/ConfirmDialog.qml",
                                            {
                                                title: JamiStrings.confirmAction,
                                                textLabel: JamiStrings.confirmRmConversation,
                                                confirmLabel: JamiStrings.optionRemove
                                            })
                                dlg.accepted.connect(function() {
                                    MessagesAdapter.removeConversation(LRCInstance.selectedConvUid)
                                })
                            }
                        }
                    }

                    SwarmDetailsItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        visible: CurrentAccount.type !== Profile.Type.SIP // TODO for SIP save in VCard

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize

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
                            }
                        }

                        TapHandler {
                            target: parent
                            enabled: parent.visible
                            onTapped: function onTapped(eventPoint) {
                                colorDialogComp.createObject(appWindow).open()
                            }
                        }
                    }

                    SwarmDetailsItem {
                        id: settingsSwarmItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        visible: !CurrentConversation.isCoreDialog

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize

                            Text {
                                id: settingsSwarmText
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                Layout.rightMargin: JamiTheme.preferredMarginSize
                                Layout.maximumWidth: settingsSwarmItem.width / 2

                                text: JamiStrings.defaultCallHost
                                font.pointSize: JamiTheme.settingsFontSize
                                font.kerning: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter

                                color: JamiTheme.textColor
                            }


                            RowLayout {
                                id: swarmRdvPref
                                spacing: 10
                                Layout.alignment: Qt.AlignRight
                                Layout.maximumWidth: settingsSwarmItem.width / 2

                                Connections {
                                    target: CurrentConversation

                                    function onRdvAccountChanged() {
                                        // This avoid incorrect avatar by always modifying the mode before the imageId
                                        avatar.mode = CurrentConversation.rdvAccount === CurrentAccount.uri ? Avatar.Mode.Account : Avatar.Mode.Contact
                                        avatar.imageId = CurrentConversation.rdvAccount === CurrentAccount.uri ? CurrentAccount.id : CurrentConversation.rdvAccount
                                    }
                                }

                                Avatar {
                                    id: avatar
                                    width: JamiTheme.contactMessageAvatarSize
                                    height: JamiTheme.contactMessageAvatarSize
                                    Layout.leftMargin: JamiTheme.preferredMarginSize
                                    Layout.topMargin: JamiTheme.preferredMarginSize / 2
                                    visible: CurrentConversation.rdvAccount !== ""

                                    imageId: ""
                                    showPresenceIndicator: false
                                    mode: Avatar.Mode.Account
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.alignment: Qt.AlignVCenter

                                    ElidedTextLabel {
                                        id: bestName

                                        eText: {
                                            if (CurrentConversation.rdvAccount === "")
                                                return JamiStrings.none
                                            else if (CurrentConversation.rdvAccount === CurrentAccount.uri)
                                                return CurrentAccount.bestName
                                            else
                                                return UtilsAdapter.getBestNameForUri(CurrentAccount.id, CurrentConversation.rdvAccount)
                                        }
                                        maxWidth: JamiTheme.preferredFieldWidth

                                        font.pointSize: JamiTheme.participantFontSize
                                        color: JamiTheme.primaryForegroundColor
                                        font.kerning: true

                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    ElidedTextLabel {
                                        id: deviceId

                                        eText: CurrentConversation.rdvDevice === "" ? JamiStrings.none : CurrentConversation.rdvDevice
                                        visible: CurrentConversation.rdvDevice !== ""
                                        maxWidth: JamiTheme.preferredFieldWidth

                                        font.pointSize: JamiTheme.participantFontSize
                                        color: JamiTheme.textColorHovered
                                        font.kerning: true

                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }

                        TapHandler {
                            target: parent

                            enabled: parent.visible && root.isAdmin
                            onTapped: function onTapped(eventPoint) {
                                viewCoordinator.presentDialog(
                                            appWindow,
                                            "mainview/components/DevicesListPopup.qml")
                            }
                        }
                    }

                    RowLayout {
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        visible: CurrentAccount.type !== Profile.Type.SIP

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

                            color: JamiTheme.textColor

                            text: CurrentConversation.modeString
                        }
                    }

                    RowLayout {
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        Layout.maximumWidth: parent.width
                        visible: LRCInstance.debugMode()

                        Text {
                            id: idLabel
                            Layout.preferredHeight: 30
                            Layout.rightMargin: JamiTheme.preferredMarginSize
                            Layout.maximumWidth: parent.width / 2

                            text: JamiStrings.identifier
                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            Layout.maximumWidth: parent.width / 2

                            color: JamiTheme.textColor


                            text: CurrentConversation.id
                            elide: Text.ElideRight

                        }
                    }
                }
            }

            JamiListView {
                id: members
                anchors.topMargin: JamiTheme.preferredMarginSize
                anchors.bottomMargin: JamiTheme.preferredMarginSize
                anchors.fill: parent

                visible: tabBar.currentItemName === "members"

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

                model: CurrentConversationMembers
                delegate: ItemDelegate {
                    id: member

                    width: members.width
                    height: JamiTheme.smartListItemHeight

                    background: Rectangle {
                        anchors.fill: parent
                        color: {
                            if (member.hovered || nameTextEditHover.hovered)
                                return JamiTheme.smartListHoveredColor
                            else
                                return "transparent"
                        }
                    }

                    MouseArea {
                        id: memberMouseArea

                        anchors.fill: parent
                        enabled: MemberUri !== CurrentAccount.uri
                        acceptedButtons: Qt.RightButton
                        onClicked: function (mouse) {
                            var position = mapToItem(members, mouse.x, mouse.y)
                            contextMenu.openMenuAt(position.x, position.y, MemberUri)
                        }
                    }

                    RowLayout {
                        spacing: 10
                        anchors.fill: parent
                        anchors.rightMargin: JamiTheme.preferredMarginSize

                        Avatar {
                            id: avatar
                            width: JamiTheme.smartListAvatarSize
                            height: JamiTheme.smartListAvatarSize
                            Layout.leftMargin: JamiTheme.preferredMarginSize
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            z: -index
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED)? 0.5 : 1

                            imageId: CurrentAccount.uri == MemberUri ? CurrentAccount.id : MemberUri
                            showPresenceIndicator: UtilsAdapter.getContactPresence(CurrentAccount.id, MemberUri)
                            mode: CurrentAccount.uri == MemberUri ? Avatar.Mode.Account : Avatar.Mode.Contact
                        }

                        ElidedTextLabel {
                            id: nameTextEdit

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            Layout.fillWidth: true

                            eText: UtilsAdapter.getContactBestName(CurrentAccount.id, MemberUri)
                            maxWidth: width

                            font.pointSize: JamiTheme.participantFontSize
                            color: JamiTheme.primaryForegroundColor
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED)? 0.5 : 1
                            font.kerning: true

                            verticalAlignment: Text.AlignVCenter

                            HoverHandler {
                                id: nameTextEditHover
                            }
                        }

                        ElidedTextLabel {
                            id: roleLabel

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2

                            eText: {
                                if (MemberRole === Member.Role.ADMIN)
                                    return JamiStrings.administrator
                                if (MemberRole === Member.Role.INVITED)
                                    return JamiStrings.invited
                                if (MemberRole === Member.Role.BANNED)
                                    return JamiStrings.banned
                                return ""
                            }
                            maxWidth: JamiTheme.preferredFieldWidth

                            font.pointSize: JamiTheme.participantFontSize
                            color: JamiTheme.textColorHovered
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED)? 0.5 : 1
                            font.kerning: true

                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            DocumentsScrollview {
                id: documents

                clip: true
                visible: tabBar.currentItemName === "documents"
                anchors.fill: parent
            }
        }
    }
}
